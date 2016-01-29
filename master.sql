alter table property
add column wfrisk_cat text,
add column ls_risk text,
add column fw_in bigint,
add column fl1yr_in bigint; 

UPDATE property 
SET class=(CASE WHEN class >= '100' AND class < '200' THEN 'Residential'
			WHEN class >= '200' AND class < '300' THEN 'Biltmore Estate'
			WHEN class >= '300' AND class < '400' THEN 'Vacant Land'
			WHEN class >= '400' AND class < '500' THEN 'Commercial'
			WHEN class >= '500' AND class < '600' THEN 'Recreation'
			WHEN class >= '600' AND class < '700' THEN 'Community Services'
			WHEN class >= '700' AND class < '800' THEN 'Industrial'
			WHEN class >= '800' AND class < '900' THEN 'State Assessed/Utilities'
			WHEN class >= '900' AND class < '1000' THEN 'Conserved Area/Park'
			ELSE 'Unclassified' END) ; 
			
--Changes the Multipolygon geom column to a polygon
Alter table property alter column geom SET data type geometry;
--Adds a fake buffer to workaround intersection
UPDATE property
SET geom = ST_buffer(geom,0.0); 
--Returns the geom column to a multipolygon 
Alter table property alter column geom SET data type geometry(multipolygon) USING st_multi(geom);

CREATE view wf_results as
WITH 
-- our features of interest
   feat AS (SELECT pinnum As parcel_id, geom FROM property AS b 
    WHERE (PIN > '0')) ,
-- clip band of raster tiles to boundaries of builds
-- then get stats for these clipped regions
 b_stats AS
	(SELECT  parcel_id, (stats).*
FROM (SELECT parcel_id, (ST_SummaryStats(ST_Clip(rast,1,geom,NULL,true),TRUE)) As stats
    FROM wildfire_4326
		INNER JOIN feat
	ON ST_Intersects(feat.geom, rast) 
 ) As foo
 )
-- finally summarize stats
SELECT parcel_id, SUM(count) As num_pixels
  , MIN(min) As min_pval
  ,  MAX((CASE
	WHEN max >= 78 THEN 'High Risk'
	WHEN max >= 67 and max < 78   THEN 'Medium High Risk'
	WHEN max >= 33 and max < 67 THEN 'Medium'
	ELSE 'Low Risk'
	END)) As max_pval
  , SUM(mean*count)/SUM(count) As avg_pval
	FROM b_stats
 WHERE count > 0
	GROUP BY parcel_id
	ORDER BY max_pval;

--This is really useful script to bring in data off of common values
UPDATE property as p
SET wfrisk_cat = pr.max_pval
FROM wf_results as pr 
--Where pin in table property is the same as the pin in property two 
--relating the two tables based off this values
where p.pinnum = pr.parcel_id; 

Create table wildfire_exposure(category text,High_Risk_parcels numeric,High_Risk numeric,Medium_High_Risk_parcels numeric,
Medium_High_Risk numeric,Medium_Risk_parcels Numeric,Medium_Risk Numeric,Low_Risk_parcels Numeric, Low_Risk Numeric);

Create table wildfire_exposure_v1(category text,High_Risk_parcels numeric,High_Risk numeric,Medium_High_Risk_parcels numeric,
Medium_High_Risk numeric,Medium_Risk_parcels Numeric,Medium_Risk Numeric,Low_Risk_parcels Numeric, Low_Risk Numeric);

insert into wildfire_exposure(Category, high_risk_parcels, High_Risk, 
Medium_high_risk_parcels, Medium_High_risk, Medium_risk_parcels, medium_risk,
low_risk_parcels, low_risk)

SELECT class as c,
COUNT((case when wfrisk_cat = 'High Risk'then APPRAISEDV END)) AS High_Risk_parcels,
SUM((case when wfrisk_cat = 'High Risk'then APPRAISEDV END)) AS High_Risk,
COUNT((case when wfrisk_cat = 'Medium High Risk'  then APPRAISEDV END)) AS Medium_High_Risk_parcels,
SUM((case when wfrisk_cat = 'Medium High Risk'  then APPRAISEDV END)) AS Medium_High_Risk,
COUNT((case when wfrisk_cat = 'Medium'  then APPRAISEDV END)) AS Medium_Risk_parcels,
SUM((case when wfrisk_cat = 'Medium'  then APPRAISEDV END)) AS Medium_Risk,
COUNT((case when wfrisk_cat = 'Low Risk' then APPRAISEDV END)) AS Low_Risk_parcels,
SUM((case when wfrisk_cat = 'Low Risk' then APPRAISEDV END)) AS Low_Risk
from property
group by c
UNION
SELECT 'Total',
COUNT((case when wfrisk_cat = 'High Risk'then APPRAISEDV END)) AS High_Risk_parcels,
SUM((case when wfrisk_cat = 'High Risk'then APPRAISEDV END)) AS High_Risk,
COUNT((case when wfrisk_cat = 'Medium High Risk'  then APPRAISEDV END)) AS Medium_High_Risk_parcels,
SUM((case when wfrisk_cat = 'Medium High Risk'  then APPRAISEDV END)) AS Medium_High_Risk,
COUNT((case when wfrisk_cat = 'Medium'  then APPRAISEDV END)) AS Medium_Risk_parcels,
SUM((case when wfrisk_cat = 'Medium'  then APPRAISEDV END)) AS Medium_Risk,
COUNT((case when wfrisk_cat = 'Low Risk' then APPRAISEDV END)) AS Low_Risk_parcels,
SUM((case when wfrisk_cat = 'Low Risk' then APPRAISEDV END)) AS Low_Risk
from property;

Update wildfire_exposure
SET category=(CASE WHEN category = 'State Assessed/Utilities' THEN '1'
			WHEN category = 'Biltmore Estate'  THEN '2'
			WHEN category = 'Recreation'  THEN '3'
			WHEN category = 'Parcels Exposed'  THEN '01'
			WHEN category = 'Industrial'  THEN '5'
			WHEN category = 'Unclassified' THEN '6'
			WHEN category = 'Vacant Land'  THEN '7'
			WHEN category = 'Residential'  THEN '8'
			WHEN category = 'Community Services' THEN '9'
			WHEN category = 'Commercial' THEN '4'
			WHEN category = 'Total' Then '0' END); 



----This script reorganizes the redefined numerical class codes,
--then it inserts it into a new wildfire exposure table that has been 
--declared as version 2
insert into wildfire_exposure_v1(Category, high_risk_parcels, High_Risk, 
Medium_high_risk_parcels, Medium_High_risk, Medium_risk_parcels, medium_risk,
low_risk_parcels, low_risk)
SELECT * FROM wildfire_exposure
Order by category DESC;

Update wildfire_exposure_v1
SET category=(CASE WHEN category = '1' THEN 'State Assessed/Utilities' 
			WHEN category = '2'  THEN 'Biltmore Estate' 
			WHEN category = '3'  THEN 'Recreation'
			WHEN category = '5' THEN 'Industrial'
			WHEN category = '6'THEN 'Unclassified'
			WHEN category = '7' THEN 'Vacant Land' 
			WHEN category = '8'  THEN 'Residential' 
			WHEN category = '9'THEN 'Community Services'  
			WHEN category = '4' THEN 'Commercial' 
			WHEN category = '0' Then 'Total'  END); 

			






--This will allow you to pull the highest pixel value from the property geometry 
--and then declare that pixel value as the level exposure that that parcel is experiencing
Create or replace view AS 
 WITH 
-- our features of interest
   feat AS (SELECT pinnum As parcel_id, geom FROM property AS b 
    WHERE (pinnum > '0')) ,
-- clip band 2 of raster tiles to boundaries of builds
-- then get stats for these clipped regions
 b_stats AS
	(SELECT  parcel_id, (stats).*
FROM (SELECT parcel_id, (ST_SummaryStats(ST_Clip(rast,geom))) As stats
    FROM lsindex
	INNER JOIN feat
	ON ST_Intersects(feat.geom, rast) 
 ) As foo
 )
-- finally summarize stats
SELECT parcel_id, SUM(count) As num_pixels
  , MAX(max) as max_pval
  , MIN(min) As min_pval
  ,  MIN((CASE
	WHEN min = 6 THEN 'Unstable'
	WHEN min = 5 THEN 'Upper Threshold'
	WHEN min = 4 THEN 'Lower Threshold'
	WHEN min = 3 THEN 'Nominally Stable'
	WHEN min = 2 THEN 'Moderately Stable'
	WHEN min = 1 THEN 'Stable'
	ELSE ' '
	END)) As risk_cat
  , SUM(mean*count)/SUM(count) As avg_pval
	FROM b_stats
 WHERE count > 0
	GROUP BY parcel_id
	ORDER BY max_pval;

UPDATE property as p
SET ls_risk = pr.risk_cat
FROM ls_results as pr 
--Where pin in table property is the same as the pin in property two 
--relating the two tables based off this values
where p.pinnum = pr.parcel_id; 

create table landslide_exposure(Category text,Unstable_Parcels numeric,
Unstable numeric,Upper_Threshold_Parcels numeric,Upper_Threshold numeric,
Lower_Threshold_Parcels numeric,Lower_Threshold numeric,Nominally_Stable_Parcels numeric,
 Nominally_Stable numeric, Moderately_stable_Parcels numeric,Moderately_stable numeric,
 Stable_Parcels numeric, Stable numeric);

 create table landslide_exposure_v1(Category text,Unstable_Parcels numeric,
Unstable numeric,Upper_Threshold_Parcels numeric,Upper_Threshold numeric,
Lower_Threshold_Parcels numeric,Lower_Threshold numeric,Nominally_Stable_Parcels numeric,
 Nominally_Stable numeric, Moderately_stable_Parcels numeric,Moderately_stable numeric,
 Stable_Parcels numeric, Stable numeric);
 
 Insert into landslide_exposure(Category, unstable_parcels, Unstable, upper_threshold_parcels, Upper_threshold, 
lower_threshold_parcels, Lower_Threshold, nominally_stable_parcels, Nominally_stable,
moderately_stable_parcels, moderately_stable, stable_parcels, stable)

SELECT class as c,
COUNT((case when ls_risk = 'Unstable' then APPRAISEDV END)) AS Unstable_parcels,
SUM((case when ls_risk = 'Unstable' then APPRAISEDV END)) AS Unstable,
COUNT((case when ls_risk = 'Upper Threshold'  then APPRAISEDV END)) AS Upper_Threshold_parcels,
SUM((case when ls_risk = 'Upper Threshold'  then APPRAISEDV END)) AS Upper_Threshold,
COUNT((case when ls_risk = 'Lower Threshold'  then APPRAISEDV END)) AS Lower_Threshold_parcels,
SUM((case when ls_risk = 'Lower Threshold'  then APPRAISEDV END)) AS Lower_Threshold,
COUNT((case when ls_risk = 'Nominally Stable'  then APPRAISEDV END)) AS Nominally_Stable_parcels,
SUM((case when ls_risk = 'Nominally Stable'  then APPRAISEDV END)) AS Nominally_Stable,
COUNT((case when ls_risk = 'Moderately Stable'  then APPRAISEDV END)) AS Moderately_Stable_parcels,
SUM((case when ls_risk = 'Moderately Stable'  then APPRAISEDV END)) AS Moderately_Stable,
COUNT((case when ls_risk = 'Stable' then APPRAISEDV END)) AS stable_parcels,
SUM((case when ls_risk = 'Stable' then APPRAISEDV END)) AS Stable
From property
group by c
UNION
SELECT 'Total',
COUNT((case when ls_risk = 'Unstable' then APPRAISEDV END)) AS Unstable_parcels,
SUM((case when ls_risk = 'Unstable' then APPRAISEDV END)) AS Unstable,
COUNT((case when ls_risk = 'Upper Threshold'  then APPRAISEDV END)) AS Upper_Threshold_parcels,
SUM((case when ls_risk = 'Upper Threshold'  then APPRAISEDV END)) AS Upper_Threshold,
COUNT((case when ls_risk = 'Lower Threshold'  then APPRAISEDV END)) AS Lower_Threshold_parcels,
SUM((case when ls_risk = 'Lower Threshold'  then APPRAISEDV END)) AS Lower_Threshold,
COUNT((case when ls_risk = 'Nominally Stable'  then APPRAISEDV END)) AS Nominally_Stable_parcels,
SUM((case when ls_risk = 'Nominally Stable'  then APPRAISEDV END)) AS Nominally_Stable,
COUNT((case when ls_risk = 'Moderately Stable'  then APPRAISEDV END)) AS Moderately_Stable_parcels,
SUM((case when ls_risk = 'Moderately Stable'  then APPRAISEDV END)) AS Moderately_Stable,
COUNT((case when ls_risk = 'Stable' then APPRAISEDV END)) AS stable_parcels,
SUM((case when ls_risk = 'Stable' then APPRAISEDV END)) AS Stable
from property;

UPDATE landslide_exposure
SET category=(CASE WHEN category = 'State Assessed/Utilities' THEN '1'
			WHEN category = 'Biltmore Estate'  THEN '2'
			WHEN category = 'Recreation'  THEN '3'
			WHEN category = 'Parcels Exposed'  THEN '01'
			WHEN category = 'Industrial'  THEN '5'
			WHEN category = 'Unclassified' THEN '6'
			WHEN category = 'Vacant Land'  THEN '7'
			WHEN category = 'Residential'  THEN '8'
			WHEN category = 'Community Services' THEN '9'
			WHEN category = 'Commercial' THEN '4'
			WHEN category = 'Total' Then '0' END); 


insert into landslide_exposure_v1(Category, unstable_parcels, Unstable, upper_threshold_parcels, Upper_threshold, 
lower_threshold_parcels, Lower_Threshold, nominally_stable_parcels, Nominally_stable,
moderately_stable_parcels, moderately_stable, stable_parcels, stable)
SELECT * FROM landslide_exposure
Order by category DESC;

Update landslide_exposure_v1
SET category=(CASE WHEN category = '1' THEN 'State Assessed/Utilities' 
			WHEN category = '2'  THEN 'Biltmore Estate' 
			WHEN category = '3'  THEN 'Recreation'
			WHEN category = '5' THEN 'Industrial'
			WHEN category = '6'THEN 'Unclassified'
			WHEN category = '7' THEN 'Vacant Land' 
			WHEN category = '8'  THEN 'Residential' 
			WHEN category = '9'THEN 'Community Services'  
			WHEN category = '4' THEN 'Commercial' 
			WHEN category = '0' Then 'Total'  END); 

		create table fw_r(pinnum character varying(15), class character varying(50),
ap numeric, lv numeric,bv numeric, parcels bigint);

create table fl1yr_r(pinnum character varying(15), class character varying(50),
ap numeric, lv numeric,bv numeric, parcels bigint);

create table fl1yrexposure(class character varying, building_fl1yr numeric, 
land_fl1yr numeric, total_fl1yr numeric, total_parcels_fl1yr bigint);

create view fw_r as
Select pinnum as pinnum,
sum(appraisedv) as ap,
sum(buildingva) as bv,
sum(landvalue) as lv,
count(*) as parcels
from property as p
join fw as f
on ST_Intersects(p.geom, f.geom)
group by pinnum;

Insert into fl1yr_r(pinnum, ap, bv, lv, parcels) 
Select pinnum as pinnum,
sum(appraisedv) as ap,
sum(buildingva) as bv,
sum(landvalue) as lv,
count(*) as parcels
from property as p
join fw_fl1 as f
on ST_Intersects(p.geom, f.geom)
group by pinnum;

UPDATE property as p
SET fw_in = pr.parcels
FROM fw_r as pr 
--Where pin in table property is the same as the pin in property two 
--relating the two tables based off this values
where p.pinnum = pr.pinnum; 

UPDATE property as p
SET fl1yr_in = pr.parcels
FROM fl1yr_r as pr 
--Where pin in table property is the same as the pin in property two 
--relating the two tables based off this values
where p.pinnum = pr.pinnum; 

UPDATE fw_r as p 
SET class = pr.class
from property as pr
where p.pinnum = pr.pinnum;

UPDATE fl1yr_r as p 
SET class = pr.class
from property as pr
where p.pinnum = pr.pinnum;



create table floodexposure(class character varying, building_floodway numeric, 
land_floodway numeric, total_floodway numeric, total_parcels bigint, building_fl1yr numeric, 
land_fl1yr numeric, total_fl1yr numeric, total_parcels_fl1yr bigint);

create table floodexposure_v1(class character varying, building_floodway numeric, 
land_floodway numeric, total_floodway numeric, total_parcels bigint, building_fl1yr numeric, 
land_fl1yr numeric, total_fl1yr numeric, total_parcels_fl1yr bigint);

Insert into floodexposure(class, building_floodway, land_floodway, total_floodway, total_parcels)
SELECT class,
sum(bv) as Building_Floodway,
sum(lv) as Land_Floodway,
sum(ap) as Total_Floodway,
count(ap) as Total_parcels
from fw_r
group by class
Union 
SELECT 'Total',
sum(bv) as Building_Floodway,
sum(lv) as Land_Floodway,
sum(ap) as Total_Floodway,
count(ap) as Total_parcels
from fw_r;

Insert into fl1yrexposure(class, building_fl1yr, land_fl1yr, total_fl1yr, total_parcels_fl1yr)

SELECT class,
sum(bv) as Building_Floodway,
sum(lv) as Land_Floodway,
sum(ap) as Total_Floodway,
count(ap) as Total_parcels
from fl1yr_r
group by class
Union 
SELECT 'Total',
sum(bv) as Building_Floodway,
sum(lv) as Land_Floodway,
sum(ap) as Total_Floodway,
count(ap) as Total_parcels
from fl1yr_r;

UPDATE floodexposure as p
SET building_fl1yr = pr.building_fl1yr
FROM fl1yrexposure as pr 
where p.class = pr.class;

UPDATE floodexposure as p
SET land_fl1yr = pr.land_fl1yr
FROM fl1yrexposure as pr 
where p.class = pr.class;

UPDATE floodexposure as p
SET total_fl1yr = pr.total_fl1yr
FROM fl1yrexposure as pr 
where p.class = pr.class;

UPDATE floodexposure as p
SET total_parcels_fl1yr = pr.total_parcels_fl1yr
FROM fl1yrexposure as pr 
where p.class = pr.class;

Update floodexposure
SET class =(CASE WHEN class = 'State Assessed/Utilities' THEN '1'
			WHEN class = 'Biltmore Estate'  THEN '2'
			WHEN class = 'Recreation'  THEN '3'
			WHEN class = 'Parcels Exposed'  THEN '01'
			WHEN class = 'Industrial'  THEN '5'
			WHEN class = 'Unclassified' THEN '6'
			WHEN class = 'Vacant Land'  THEN '7'
			WHEN class = 'Residential'  THEN '8'
			WHEN class = 'Community Services' THEN '9'
			WHEN class = 'Commercial' THEN '4'
			WHEN class = 'Total' Then '0' END); 


insert into floodexposure_v1(class, building_floodway, 
land_floodway, total_floodway, total_parcels, building_fl1yr, 
land_fl1yr, total_fl1yr, total_parcels_fl1yr)
SELECT * FROM floodexposure
Order by class DESC;

Update floodexposure_v1
SET class=(CASE WHEN class = '1' THEN 'State Assessed/Utilities' 
			WHEN class = '2'  THEN 'Biltmore Estate' 
			WHEN class = '3'  THEN 'Recreation'
			WHEN class = '5' THEN 'Industrial'
			WHEN class = '6'THEN 'Unclassified'
			WHEN class = '7' THEN 'Vacant Land' 
			WHEN class = '8'  THEN 'Residential' 
			WHEN class = '9'THEN 'Community Services'  
			WHEN class = '4' THEN 'Commercial' 
			WHEN class = '0' Then 'Total'  END); 



