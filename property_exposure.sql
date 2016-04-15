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

