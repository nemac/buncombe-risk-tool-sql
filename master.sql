-----CLEAN PROPERTY AND BUILDING DATA---------
UPDATE property_v2
  SET geom=ST_Multi(ST_CollectionExtract(ST_MakeValid(geom), 3))
  WHERE NOT ST_IsValid(geom);

update property_v2
set geom = ST_MakeValid(geom)

create or replace view vw_valid_geoms as
SELECT 
  g.geom, 
  row_number() over() AS gid
FROM 
  (SELECT 
     (ST_DUMP(ST_MakeValid (geom))).geom FROM property_v2
  ) AS g
WHERE ST_GeometryType(g.geom) = 'ST_MultiPolygon' 
   OR ST_GeometryType(g.geom) = 'ST_Polygon';


---JOIN BUILDING FOOTPRINTS TO PARCEL DATA AND CREATE NEW TABLE-------------------------
create table building_footprints as 
select DISTINCT on (f.geom) pinnum, pin, pinext, owner, nmptype, taxyear, condobuild, deedbook, deedpage, platbook, platpage, subname, sublot, subblock,
subsect, updatedate, housenumbe, numbersuff, direction, streetname, streettype, township, acreage, accountnum, deeddate, stamps , instrument , reason , county,
city, firedistri, schooldist, careof, address, cityname, state, zipcode, class, improved, exempt, priced ,totalmarke, appraisedv, taxvalue, landuse, neighborho,
landvalue, buildingva, improvemen,  appraisala, state_rout, state_ro_1, propcard, f.geom 
from property as p
inner join buildings as f
ON ST_Intersects(f.geom, p.geom);

---CREATE WILDFIRE EXPOSURE TABLE------------------------
CREATE table wf_results as
WITH 
-- our features of interest
   feat AS (SELECT pinnum As parcel_id, geom FROM property AS b 
    WHERE (PIN > '0')) ,
-- clip band of raster tiles to boundaries of builds
-- then get stats for these clipped regions
 b_stats AS
	(SELECT  parcel_id, (stats).*
FROM (SELECT parcel_id, (ST_SummaryStats(ST_Clip(rast,1,geom,NULL,true),TRUE)) As stats
    FROM wildfire
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
	
--CREATE PARCELS IMPACTED BY WILDFIRE VIEW-------------------
CREATE VIEW or replace parcels_wildfire AS 
SELECT b.pinnum as pin,(CASE WHEN class >= '100' AND class < '200' THEN 'Residential'
			WHEN class >= '200' AND class < '300' THEN 'Biltmore Estate'
			WHEN class >= '300' AND class < '400' THEN 'Vacant Land'
			WHEN class >= '400' AND class < '500' THEN 'Commercial'
			WHEN class >= '500' AND class < '600' THEN 'Recreation'
			WHEN class >= '600' AND class < '700' THEN 'Community Services'
			WHEN class >= '700' AND class < '800' THEN 'Industrial'
			WHEN class >= '800' AND class < '900' THEN 'State Assessed/Utilities'
			WHEN class >= '900' AND class < '1000' THEN 'Conserved Area/Park'
			ELSE 'Unclassified' END) as class, b.appraisedv, b.buildingva, b.landvalue, b.geom, c.max_pval 
			from property as b, wf_results as c WHERE b.pinnum = c.parcel_id;
	
--CREATE WILDFIRE SUMMARY STATISTICS EXPOSURE TABLE VIEW------------------- 
CREATE VIEW wf_statistics AS 
SELECT "case",
COUNT((case when max_pval = 'High Risk'then APPRAISEDV END)) AS High_Risk_parcels,
SUM((case when max_pval = 'High Risk'then APPRAISEDV END)) AS High_Risk,
COUNT((case when max_pval = 'Medium High Risk'  then APPRAISEDV END)) AS Medium_High_Risk_parcels,
SUM((case when max_pval = 'Medium High Risk'  then APPRAISEDV END)) AS Medium_High_Risk,
COUNT((case when max_pval = 'Medium'  then APPRAISEDV END)) AS Medium_Risk_parcels,
SUM((case when max_pval = 'Medium'  then APPRAISEDV END)) AS Medium_Risk,
COUNT((case when max_pval = 'Low Risk' then APPRAISEDV END)) AS Low_Risk_parcels,
SUM((case when max_pval = 'Low Risk' then APPRAISEDV END)) AS Low_Risk
from parcels_wildfire
group by "case"
UNION
SELECT 'Total',
COUNT((case when max_pval = 'High Risk'then APPRAISEDV END)) AS High_Risk_parcels,
SUM((case when max_pval = 'High Risk'then APPRAISEDV END)) AS High_Risk,
COUNT((case when max_pval = 'Medium High Risk'  then APPRAISEDV END)) AS Medium_High_Risk_parcels,
SUM((case when max_pval = 'Medium High Risk'  then APPRAISEDV END)) AS Medium_High_Risk,
COUNT((case when max_pval = 'Medium'  then APPRAISEDV END)) AS Medium_Risk_parcels,
SUM((case when max_pval = 'Medium'  then APPRAISEDV END)) AS Medium_Risk,
COUNT((case when max_pval = 'Low Risk' then APPRAISEDV END)) AS Low_Risk_parcels,
SUM((case when max_pval = 'Low Risk' then APPRAISEDV END)) AS Low_Risk
from parcels_wildfire;

---CREATE LANDSLIDE EXPOSURE TABLE-----------------------
Create table ls_results AS 
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

--CREATE PARCELS IMPACTED BY LANDSLIDE--------------	
CREATE VIEW or replace parcels_landslide AS 
SELECT b.pinnum as pin,(CASE WHEN class >= '100' AND class < '200' THEN 'Residential'
			WHEN class >= '200' AND class < '300' THEN 'Biltmore Estate'
			WHEN class >= '300' AND class < '400' THEN 'Vacant Land'
			WHEN class >= '400' AND class < '500' THEN 'Commercial'
			WHEN class >= '500' AND class < '600' THEN 'Recreation'
			WHEN class >= '600' AND class < '700' THEN 'Community Services'
			WHEN class >= '700' AND class < '800' THEN 'Industrial'
			WHEN class >= '800' AND class < '900' THEN 'State Assessed/Utilities'
			WHEN class >= '900' AND class < '1000' THEN 'Conserved Area/Park'
			ELSE 'Unclassified' END) as class, b.appraisedv, b.buildingva, b.landvalue, b.geom, c.max_pval 
			from property as b, ls_results as c WHERE b.pinnum = c.parcel_id;


--CREATE LANDSLIDE EXPOSURE VIEW----------------------
CREATE VIEW ls_statistics AS
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
From parcels_landslide
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
from parcels_landslide;



-----CREATE DEBRIS FLOW VIEW-----------------
create or replace view debrflow_exposure as 
Select pinnum as pinnum,
sum(appraisedv) as ap,
sum(buildingva) as bv,
sum(landvalue) as lv,
count(*) as parcels
from property as p
join debris_flow as f
on ST_Intersects(p.geom, f.geom)
group by pinnum;


---CREATE PARCELS IN DEBRIS FLOW VIEW-----------------
CREATE or REPLACE VIEW parcels_debrflow AS
SELECT b.pinnum as pin, (CASE WHEN class >= '100' AND class < '200' THEN 'Residential'
			WHEN class >= '200' AND class < '300' THEN 'Biltmore Estate'
			WHEN class >= '300' AND class < '400' THEN 'Vacant Land'
			WHEN class >= '400' AND class < '500' THEN 'Commercial'
			WHEN class >= '500' AND class < '600' THEN 'Recreation'
			WHEN class >= '600' AND class < '700' THEN 'Community Services'
			WHEN class >= '700' AND class < '800' THEN 'Industrial'
			WHEN class >= '800' AND class < '900' THEN 'State Assessed/Utilities'
			WHEN class >= '900' AND class < '1000' THEN 'Conserved Area/Park'
			ELSE 'Unclassified' END) as class, b.buildingva, b.landvalue, b.appraisedv, b.geom 
from property as b, debrflow_exposure as c
WHERE b.pinnum = c.pinnum;


---CREATE DEBRIS FLOW SUMMARY STATISTICS--------------

create or replace view debrflow_statistics as 
Select class as class,
sum(appraisedv) as ap,
sum(buildingva) as bv,
sum(landvalue) as lv,
count(*) as parcels
from parcels_debrflow
group by class
UNION 
SELECT 'TOTAL',
sum(appraisedv) as ap,
sum(buildingva) as bv,
sum(landvalue) as lv,
count(*) as parcels
from parcels_debrflow;



---CREATE 100 YEAR FLOODPLAIN VIEW-------------------
create or replace view fl1yr_exposure as 
Select pinnum as pinnum,
sum(appraisedv) as ap,
sum(buildingva) as bv,
sum(landvalue) as lv,
count(*) as parcels
from property as p
join fl1yr as f
on ST_Intersects(p.geom, f.geom)
group by pinnum;


----CREATE VIEW FOR PARCELS IN THE 100 YEAR FLOODPLAIN-----
CREATE or REPLACE VIEW parcels_fl1yr AS
SELECT b.pinnum as pin, (CASE WHEN class >= '100' AND class < '200' THEN 'Residential'
			WHEN class >= '200' AND class < '300' THEN 'Biltmore Estate'
			WHEN class >= '300' AND class < '400' THEN 'Vacant Land'
			WHEN class >= '400' AND class < '500' THEN 'Commercial'
			WHEN class >= '500' AND class < '600' THEN 'Recreation'
			WHEN class >= '600' AND class < '700' THEN 'Community Services'
			WHEN class >= '700' AND class < '800' THEN 'Industrial'
			WHEN class >= '800' AND class < '900' THEN 'State Assessed/Utilities'
			WHEN class >= '900' AND class < '1000' THEN 'Conserved Area/Park'
			ELSE 'Unclassified' END) as class, b.buildingva, b.landvalue, b.appraisedv, b.geom 
from property as b, fl1yr_exposure as c
WHERE b.pinnum = c.pinnum;


--CREATE 100 YEAR FLOODPLAIN SUMMARY STATISTICS------
create or replace view fl1yr_statistics as 
Select class as class,
sum(appraisedv) as ap,
sum(buildingva) as bv,
sum(landvalue) as lv,
count(*) as parcels
from parcels_fl1yr
group by class
UNION 
SELECT 'TOTAL',
sum(appraisedv) as ap,
sum(buildingva) as bv,
sum(landvalue) as lv,
count(*) as parcels
from parcels_fl1yr;



--CREATE 500 YEAR FLOODPLAIN VIEW-------------------
create or replace view fl5yr_exposure as 
Select pinnum as pinnum,
sum(appraisedv) as ap,
sum(buildingva) as bv,
sum(landvalue) as lv,
count(*) as parcels
from property as p
join fl5yr as f
on ST_Intersects(p.geom, f.geom)
group by pinnum;


--CREATE VIEW FOR PARCELS IN THE 500 YEAR FLOODPLAIN-----

CREATE OR REPLACE VIEW parcels_fl5yr AS
SELECT b.pinnum as pin, (CASE WHEN class >= '100' AND class < '200' THEN 'Residential'
			WHEN class >= '200' AND class < '300' THEN 'Biltmore Estate'
			WHEN class >= '300' AND class < '400' THEN 'Vacant Land'
			WHEN class >= '400' AND class < '500' THEN 'Commercial'
			WHEN class >= '500' AND class < '600' THEN 'Recreation'
			WHEN class >= '600' AND class < '700' THEN 'Community Services'
			WHEN class >= '700' AND class < '800' THEN 'Industrial'
			WHEN class >= '800' AND class < '900' THEN 'State Assessed/Utilities'
			WHEN class >= '900' AND class < '1000' THEN 'Conserved Area/Park'
			ELSE 'Unclassified' END) as class, b.buildingva, b.landvalue, b.appraisedv, b.geom 
from property as b, fl5yr_exposure as c
WHERE b.pinnum = c.pinnum;

--CREATE 500 YEAR FLOODPLAIN SUMMARY STATISTICS-------------------
create or replace view fl5yr_statistics as 
Select class as class,
sum(appraisedv) as ap,
sum(buildingva) as bv,
sum(landvalue) as lv,
count(*) as parcels
from parcels_fl5yr
group by class
UNION
SELECT 'TOTAL',
sum(appraisedv) as ap,
sum(buildingva) as bv,
sum(landvalue) as lv,
count(*) as parcels
from parcels_fl5yr;


----CREATE 100 YEAR FLOODED BUILDINGS----------
create or replace view fl1yr_build_exposure as 
Select pinnum as pinnum,
sum(appraisedv) as ap,
sum(buildingva) as bv,
sum(landvalue) as lv,
count(*) as parcels
from building_footprints as p
join fl1yr as f
on ST_Intersects(p.geom, f.geom)
group by pinnum;

---CREATE 100 YEAR FLOODED BUILDINGS WITHIN PARCELS--------
CREATE OR REPLACE VIEW buildings_fl1yr AS
SELECT b.pinnum as pin, (CASE WHEN class >= '100' AND class < '200' THEN 'Residential'
			WHEN class >= '200' AND class < '300' THEN 'Biltmore Estate'
			WHEN class >= '300' AND class < '400' THEN 'Vacant Land'
			WHEN class >= '400' AND class < '500' THEN 'Commercial'
			WHEN class >= '500' AND class < '600' THEN 'Recreation'
			WHEN class >= '600' AND class < '700' THEN 'Community Services'
			WHEN class >= '700' AND class < '800' THEN 'Industrial'
			WHEN class >= '800' AND class < '900' THEN 'State Assessed/Utilities'
			WHEN class >= '900' AND class < '1000' THEN 'Conserved Area/Park'
			ELSE 'Unclassified' END) as class, b.buildingva, b.landvalue, b.appraisedv, b.geom 
from building_footprints as b, fl1yr_build_exposure as c
WHERE b.pinnum = c.pinnum;


---CREATE 100 YEAR FLOODED BUILDINGS STATISTICS-----
create or replace view fl1yr_build_statistics as 
Select class as class,
sum(appraisedv) as ap,
sum(buildingva) as bv,
sum(landvalue) as lv,
count(*) as parcels
from buildings_fl1yr
group by class
UNION
SELECT 'TOTAL',
sum(appraisedv) as ap,
sum(buildingva) as bv,
sum(landvalue) as lv,
count(*) as parcels
from buildings_fl1yr;


----CREATE 500 YEAR FLOODED BUILDINGS----------
create or replace view fl5yr_build_exposure as 
Select pinnum as pinnum,
sum(appraisedv) as ap,
sum(buildingva) as bv,
sum(landvalue) as lv,
count(*) as parcels
from building_footprints as p
join fl5yr as f
on ST_Intersects(p.geom, f.geom)
group by pinnum;

---CREATE 500 YEAR FLOODED BUILDINGS WITHIN PARCELS--------
CREATE OR REPLACE VIEW buildings_fl5yr AS
SELECT b.pinnum as pin, (CASE WHEN class >= '100' AND class < '200' THEN 'Residential'
			WHEN class >= '200' AND class < '300' THEN 'Biltmore Estate'
			WHEN class >= '300' AND class < '400' THEN 'Vacant Land'
			WHEN class >= '400' AND class < '500' THEN 'Commercial'
			WHEN class >= '500' AND class < '600' THEN 'Recreation'
			WHEN class >= '600' AND class < '700' THEN 'Community Services'
			WHEN class >= '700' AND class < '800' THEN 'Industrial'
			WHEN class >= '800' AND class < '900' THEN 'State Assessed/Utilities'
			WHEN class >= '900' AND class < '1000' THEN 'Conserved Area/Park'
			ELSE 'Unclassified' END) as class, b.buildingva, b.landvalue, b.appraisedv, b.geom 
from building_footprints as b, fl5yr_build_exposure as c
WHERE b.pinnum = c.pinnum;


---CREATE 500 YEAR FLOODED BUILDINGS STATISTICS-----
create or replace view fl5yr_statistics_build as 
Select class as class,
sum(appraisedv) as ap,
sum(buildingva) as bv,
sum(landvalue) as lv,
count(*) as parcels
from buildings_fl5yr
group by class
UNION
SELECT 'TOTAL',
sum(appraisedv) as ap,
sum(buildingva) as bv,
sum(landvalue) as lv,
count(*) as parcels
from buildings_fl5yr;


-----CREATE DEBRIS FLOW VIEW BUILDINGS-----------------
create or replace view debrflow_build_exposure as 
Select pinnum as pinnum,
sum(appraisedv) as ap,
sum(buildingva) as bv,
sum(landvalue) as lv,
count(*) as parcels
from building_footprints as p
join debris_flow as f
on ST_Intersects(f.geom, p.geom)
group by pinnum;


---CREATE PARCELS IN DEBRIS FLOW VIEW BUILDINGS-----------------
CREATE or REPLACE VIEW build_debrflow AS
SELECT b.pinnum as pin, (CASE WHEN class >= '100' AND class < '200' THEN 'Residential'
			WHEN class >= '200' AND class < '300' THEN 'Biltmore Estate'
			WHEN class >= '300' AND class < '400' THEN 'Vacant Land'
			WHEN class >= '400' AND class < '500' THEN 'Commercial'
			WHEN class >= '500' AND class < '600' THEN 'Recreation'
			WHEN class >= '600' AND class < '700' THEN 'Community Services'
			WHEN class >= '700' AND class < '800' THEN 'Industrial'
			WHEN class >= '800' AND class < '900' THEN 'State Assessed/Utilities'
			WHEN class >= '900' AND class < '1000' THEN 'Conserved Area/Park'
			ELSE 'Unclassified' END) as class, b.buildingva, b.landvalue, b.appraisedv, b.geom 
from building_footprints as b, debrflow_build_exposure as c
WHERE b.pinnum = c.pinnum;


---CREATE DEBRIS FLOW SUMMARY STATISTICS BUILDINGS--------------

create or replace view debrflow_build_statistics as 
Select class as class,
sum(appraisedv) as ap,
sum(buildingva) as bv,
sum(landvalue) as lv,
count(*) as parcels
from build_debrflow
group by class
UNION 
SELECT 'TOTAL',
sum(appraisedv) as ap,
sum(buildingva) as bv,
sum(landvalue) as lv,
count(*) as parcels
from build_debrflow;
