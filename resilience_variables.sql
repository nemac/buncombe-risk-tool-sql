--This is the SQL to create the parcel variables  
-- Variable 	Description
-- Pinnum	Unique parcel id
-- cblock	census block
-- cbgroup	census block group
-- ctract	census tract
-- in_fld100	100 yr flood exposure
-- in _fld500	500 yr flood exposure
-- in_ls	Landslide exposure
-- totvalue	total parcel value
-- landvalue	parcel land value
-- bldvalue	parcel building value
-- landval_nrm	parcel land value normalized to acres of parcel
-- bldvalue_nrm	parcel building value normalized to building sq ft
-- acres	parcel acres
-- ownership	whether the parcel in owner_occupied, in_county, out_county
-- fldexposure	flood exposure
-- fldadatpcap	flood adaptive capacity
-- fldvuln	flood vulnerability
-- fldrisk	flood risk
-- lsexposure	landslide exposure
-- lsadatpcap	landslide adaptive capacity
-- lsvuln	landslide vulnerability
-- lsrisk	landslide risk
-- min_bld_year	minimum year built for parcel buildings
-- class	parcel class #
-- type	type of parcel (based on parcel class groupings)
-- bld_sqft	building sq footage 
-- lsexposure	landslide exposure ? 
-- lsadatpcap	landslide adaptive capacity ? 
-- lsvuln	landslide vulnerability ?
-- lsrisk	landslide risk ?
-- landval_nrm	parcel land value normalized to acres of parcel ?
-- bldvalue_nrm	parcel building value normalized to building sq ft ?


create table resilience_variables();

alter table resilience_variables
add column pinnum character varying(50),
add column totalmarke numeric(10,0),
add column appraisedv numeric(10,0),
add column taxvalue numeric(10,0),
add column buildingva numeric(10,0),
add column tractce character varying(6),
add column blockce10 character varying(4),
add column blkgrpce character varying(1),
add column blockgroup_geoid10 text;
add column acreage numeric, 
add column ownership text,
add column parcel_type text, 
add column exposure_levels1 text,
add column adcap_levels1 text,
add column vuln_levels1 text,
add column exposure_levels5 text,
add column adcap_levels5 text,
add column vuln_levels5 text,
add column exposure_levels_ls text,
add column adcap_levels_ls text,
add column vuln_levels_ls text,
add column year numeric, 
add column class character varying(10),
add column sqft numeric,
add column par_fl1yr_yn text,
add column par_fl5yr_yn text,
add column build_par_flqyr_yn text,
add column build_par_fl5yr_yn text,
add column landval_nrm numeric,
add column bldvalue_nrm numeric;

--The creation of the exposure levels and adaptive capacity data table
--This process includes creating the tables intersecting of parcels and features within the 100 and 500 year floodplain
--When the intersection is being ran it pulls out the pinnum geometry building class and building values
--Once the exposued features have been found then a field is added to show whether or not the building within the parcel is also exposed--
--Year built values are then joined to the parcels data gatherinh all the metrics needed to assess vulbnerability-----


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

---CREATE PARCELS IN DEBRIS FLOW VIEW BUILDINGS----------------


drop table if exists building_pinnum_join cascade;
drop table if exists parcels_fl1yr_tab cascade;
drop table if exists parcels_fl5yr_tab cascade;
drop table if exists parcel_ls_tab cascade;
drop table if exists build_fl1yr_tab cascade;
drop table if exists build_fl5yr_tab cascade;
drop table if exists build_ls_tab cascade;


---^^^when starting a new database run this query first to clear out old data^^^--

create table building_pinnum_join as
SELECT a.pinnum as pin, b.geom 
from property_4326 as a 
join footprints_4326 as b on st_intersects(a.geom,b.geom)
group by a.pinnum, b.geom;
---^^spatially join the buildings to parcel to associated the building features with a pinnum^^--



CREATE table parcels_fl1yr_tab AS
SELECT a.pinnum as pin, a.geom, sum(a.buildingva), a.class
from property_4326 as a 
join fl1yr as b on st_intersects(a.geom,b.geom)
group by a.pinnum, a.geom, a.class;
--^^Intersect the parcels to the 100 year floodplain^^-----


CREATE table parcels_fl5yr_tab AS
SELECT a.pinnum as pin, a.geom, sum(a.buildingva), a.class
from property_4326 as a 
join fl5yr as b on st_intersects(a.geom,b.geom)
group by a.pinnum, a.geom, a.class;
--^^Intersect the parcels to the 500 year floodplain^^-----

CREATE table parcels_ls_tab AS
SELECT a.pinnum as pin, a.geom, sum(a.buildingva), a.class
from property_4326 as a 
join debris_flow as b on st_intersects(a.geom,b.geom)
group by a.pinnum, a.geom, a.class;

CREATE table build_fl1yr_tab AS
SELECT a.pin, a.geom
from building_pinnum_join as a 
join fl1yr as b on st_intersects(a.geom,b.geom)
group by a.pin, a.geom;
--****2275472 ms to run****--
--^^Intersect the building footprints to the 100 year floodplain^^-----

CREATE table build_fl5yr_tab AS
SELECT a.pin as pin, a.geom
from building_pinnum_join as a 
join fl5yr as b on st_intersects(a.geom,b.geom)
group by a.pin, a.geom;
--****>7000000****-----
---^^Intersect the building footprints to the 500 year floodplain^^-------

CREATE table build_ls_tab AS
SELECT a.pin as pin, a.geom
from building_pinnum_join as a 
join debris as b on st_intersects(a.geom,b.geom)
group by a.pin, a.geom;


------Join fields that will be used for the vulnerability rankings-------

---Parcels within 100 year flood plain attribute gathering----------

create or replace view parcels_fl1yr_vw as
select * from parcels_fl1yr_tab;

create or replace view par_fl1yr_yn as 
select a.pin, (case when a.pin = b.pin then 'yes' else 
null end) as yes_no from parcels_fl1yr_vw as a, parcels_fl1yr_tab as b 
where a.pin= b.pin;

create or replace view build_par_fl1yr_yn as 
select a.pin, (case when a.pin = b.pin then 'yes' else 
null end) as yes_no from build_fl1yr_tab as a, parcels_fl1yr_tab as b 
where a.pin= b.pin

alter table parcels_fl1yr_tab
add column bldg_fl1yr_yn text,
add column year_built numeric;

update parcels_fl1yr_tab as a
set year_built = b.year_built 
from year_built_com as b 
where a.pin = b.pinnum;

update parcels_fl1yr_tab as a
set year_built = b.year_built 
from year_built_res as b 
where a.pin = b.pinnum; 

update parcels_fl1yr_tab as a 
set bldg_fl1yr_yn = b.yes_no 
from build_par_fl1yr_yn as b
where a.pin = b.pin


---Parcels within 500 year flood plain attribute gathering----------
create or replace view parcels_fl5yr_vw as
select * from parcels_fl5yr_tab;

create or replace view par_fl5yr_yn as 
select a.pin, (case when a.pin = b.pin then 'yes' else 
null end) as yes_no from parcels_fl5yr_vw as a, parcels_fl5yr_tab as b 
where a.pin= b.pin;  

create or replace view build_par_fl5yr_yn as 
select a.pin, (case when a.pin = b.pin then 'yes' else 
null end) as yes_no from build_fl5yr_tab as a, parcels_fl5yr_tab as b 
where a.pin= b.pin

alter table parcels_fl5yr_tab 
add column bldg_fl5yr_yn text,
add column year_built numeric;

update parcels_fl5yr_tab as a
set year_built = b.year_built 
from year_built_com as b 
where a.pin = b.pinnum;

update parcels_fl5yr_tab as a
set year_built = b.year_built 
from year_built_res as b 
where a.pin = b.pinnum; 

update parcels_fl5yr_tab as a 
set bldg_fl5yr_yn = b.yes_no 
from build_par_fl5yr_yn as b
where a.pin = b.pin;

---Parcels within debris flow attribute gathering----------
create or replace view parcels_ls_vw as
select * from parcels_ls_tab;

create or replace view par_ls_yn as 
select a.pin, (case when a.pin = b.pin then 'yes' else 
null end) as yes_no from parcels_ls_vw as a, parcels_ls_tab as b 
where a.pin= b.pin;  

create or replace view build_par_ls_yn as 
select a.pin, (case when a.pin = b.pin then 'yes' else 
null end) as yes_no from build_ls_tab as a, parcels_ls_tab as b 
where a.pin= b.pin

alter table parcels_ls_tab 
add column bldg_ls_yn text;
update parcels_ls_tab as a 

update parcels_ls_tab as a
set year_built = b.year_built 
from year_built_com as b 
where a.pin = b.pinnum;

update parcels_ls_tab as a
set year_built = b.year_built 
from year_built_res as b 
where a.pin = b.pinnum; 

set bldg_ls_yn = b.yes_no 
from build_par_ls_yn as b
where a.pin = b.pin;

--------Begin the creation of the vulerability ranks of 1-9 given the exposure and adaptive capcity metrics-------------


-----Parcels within the 100 year floodplain exposure, adaptive apacity and vulnerability metric------------------

--------Begin the creation of the vulerability ranks of 1-9 given the exposure and adaptive capcity metrics-------------


-----Parcels within the 100 year floodplain exposure, adaptive apacity and vulnerability metric------------------
alter table parcels_fl1yr_tab 
add column exposure_levels text,
add column adcap_levels text,
add column vuln_levels text;

create or replace view fl1yr_exposure as 
select a.pin, 
(case
when bldg_fl1yr_yn is null then 'Low'
when bldg_fl1yr_yn = 'yes' 
and class != '170' 
and class != '416' 
and class != '411' 
and class != '180'
then 'Med' 
else 'High' 
END) as exposure_levels,
a.geom from parcels_fl1yr_tab as a
where 
class = '100' 
or class < '200' 
or class = '411'
or class = '416' 
or class = '635';


update parcels_fl1yr_tab as a
set exposure_levels = b.exposure_levels 
from fl1yr_exposure as b 
where a.pin = b.pin;

create or replace view fl1yr_adcap as 
select a.pin, 
(case 
when a.year_built < 1981 and sum < 120000 then 'Low'
when a.year_built < 1981 and sum > 120000 then 'Med'
when a.year_built > 1981 and sum < 120000 then 'Med'
when a.year_built > 1981 and sum > 120000 then 'High' 
else null END) as adcap_levels,
a.geom from parcels_fl1yr_tab as a;

update parcels_fl1yr_tab as a
set adcap_levels = b.adcap_levels 
from fl1yr_adcap as b 
where a.pin = b.pin;


create or replace view fl1yr_vuln as 
select a.pin, 
(case 
when exposure_levels = 'Low' and adcap_levels = 'High'  then '1'
when exposure_levels = 'Med' and adcap_levels = 'High'  then '2'
when exposure_levels = 'Low' and adcap_levels = 'Med'  then '2'
when exposure_levels = 'High' and adcap_levels = 'High'  then '3'
when exposure_levels = 'Low' and adcap_levels = 'Low' then '3'
when exposure_levels = 'Med' and adcap_levels = 'Med'  then '4'
when exposure_levels = 'Med' and adcap_levels = 'Low'  then '6'
when exposure_levels = 'High' and adcap_levels = 'Med'  then '6'
when exposure_levels = 'High' and adcap_levels = 'Low'  then '9'
ELSE 'Not enough data' END) as vuln_levels, a.geom from parcels_fl1yr_tab as a;

update parcels_fl1yr_tab as a
set vuln_levels = b.vuln_levels 
from fl1yr_vuln as b 
where a.pin = b.pin;

-----Parcels within the 500 year floodplain exposure, adaptive apacity and vulnerability metric------------------
create or replace view fl5yr_exposure as 
select a.pin, a.class,
(case
when bldg_fl5yr_yn is null then 'Low'
when bldg_fl5yr_yn = 'yes' 
and class != '170' 
and class != '416' 
and class != '411' 
and class != '180'
then 'Med' 
else 'High' 
END) as exposure_levels,
a.geom from parcels_fl5yr_tab as a
where 
class = '100' 
or class < '200' 
or class = '411'
or class = '416' 
or class = '635';

update parcels_fl5yr_tab as a
set exposure_levels = b.exposure_levels 
from fl5yr_exposure as b 
where a.pin = b.pin;

create or replace view fl5yr_adcap as 
select a.pin, 
(case 
when a.year_built < 1981 and sum < 120000 then 'Low'
when a.year_built < 1981 and sum > 120000 then 'Med'
when a.year_built > 1981 and sum > 120000 then 'High' 
else null END) as adcap_levels,
a.geom from parcels_fl5yr_tab as a;

update parcels_fl5yr_tab as a
set adcap_levels = b.adcap_levels 
from fl5yr_adcap as b 
where a.pin = b.pin;


create or replace view fl5yr_vuln as 
select a.pin, 
(case 
when exposure_levels = 'Low' and adcap_levels = 'Low' then '1'
when exposure_levels = 'Low' and adcap_levels = 'Med'  then '2'
when exposure_levels = 'Low' and adcap_levels = 'High'  then '3'
when exposure_levels = 'Med' and adcap_levels = 'Low'  then '4'
when exposure_levels = 'Med' and adcap_levels = 'Med'  then '5'
when exposure_levels = 'Med' and adcap_levels = 'High'  then '6'
when exposure_levels = 'High' and adcap_levels = 'Low'  then '7'
when exposure_levels = 'High' and adcap_levels = 'Med'  then '8'
when exposure_levels = 'High' and adcap_levels = 'High'  then '9'
ELSE 'Not enough data' END) as vuln_levels, a.geom from parcels_fl5yr_tab as a;

update parcels_fl5yr_tab as a
set vuln_levels = b.vuln_levels 
from fl5yr_vuln as b 
where a.pin = b.pin;

-----Parcels within the landslided debris exposure, adaptive apacity and vulnerability metric------------------

create or replace view ls_exposure as 
select a.pin, a.class,
(case
when bldg_ls_yn is null then 'Low'
when bldg_ls_yn = 'yes' 
and class != '170' 
and class != '416' 
and class != '411' 
and class != '180'
then 'Med' 
else 'High' 
END) as exposure_levels,
a.geom from parcels_ls_tab as a
where 
class = '100' 
or class < '200' 
or class = '411'
or class = '416';

update parcels_ls_tab as a
set exposure_levels = b.exposure_levels 
from ls_exposure as b 
where a.pin = b.pin;

create or replace view ls_adcap as 
select a.pin, 
(case 
when a.year_built < 1981 and sum < 120000 then 'Low'
when a.year_built < 1981 and sum > 120000 then 'Med'
when a.year_built > 1981 and sum > 120000 then 'High' 
else null END) as adcap_levels,
a.geom from parcels_ls_tab as a;

update parcels_ls_tab as a
set adcap_levels = b.adcap_levels 
from ls_adcap as b 
where a.pin = b.pin;


create or replace view ls_vuln as 
select a.pin, 
(case 
when exposure_levels = 'Low' and adcap_levels = 'Low' then '1'
when exposure_levels = 'Low' and adcap_levels = 'Med'  then '2'
when exposure_levels = 'Low' and adcap_levels = 'High'  then '3'
when exposure_levels = 'Med' and adcap_levels = 'Low'  then '4'
when exposure_levels = 'Med' and adcap_levels = 'Med'  then '5'
when exposure_levels = 'Med' and adcap_levels = 'High'  then '6'
when exposure_levels = 'High' and adcap_levels = 'Low'  then '7'
when exposure_levels = 'High' and adcap_levels = 'Med'  then '8'
when exposure_levels = 'High' and adcap_levels = 'High'  then '9'
ELSE 'Not enough data' END) as vuln_levels, a.geom from parcels_ls_tab as a;

update parcels_ls_tab as a
set vuln_levels = b.vuln_levels 
from ls_vuln as b 
where a.pin = b.pin;

------------------------------Start of census information to determine exposure-------------------------------------------------------
--select substring(geoid10,1,12) as blockgroup_geoid from nc_cblock

drop view if exists property_centroid cascade; 

create or replace view property_centroid as
select a.gid, a.pinnum, st_centroid(a.geom)::geometry(point,4326) as geom, a.landvalue as lv, a.buildingva as bv, a.appraisedv as ap 
,a.acreage,a.class from property_4326 as a

create table census_parcel as 
select b.gid, a.pinnum, b.tractce10, substring(b.geoid10,1,12) as blockgroup_geoid10, b.blockce10, 
a.lv, a.bv, a.ap,
a.acreage, a.class, b.geom
from property_centroid as a 
join nc_cblock as b 
on st_intersects(a.geom, b.geom);

create table census_parcels_averages as
select gid, blockce10, 
avg(lv) as average_land,
avg(bv) as average_building, 
avg(ap) as average_total, 
sum(acreage) as acreage, geom
from census_parcel 
group by gid, blockce10, geom;

create table parcel_type as
select gid, pinnum, (CASE WHEN class >= '100' AND class < '200' THEN 'Residential'
WHEN class = '411' THEN 'Residential'
WHEN class = '416' THEN 'Residential'
WHEN class = '635' THEN 'Residential'
WHEN class = '250' THEN 'Biltmore Estate'
WHEN class >= '300' AND class < '400' THEN 'Vacant Land'
WHEN class >= '400' AND class < '411' THEN 'Commercial'
WHEN class >= '412' AND class < '416' THEN 'Commercial'
WHEN class >= '417' AND class < '500' THEN 'Commercial'
WHEN class >= '500' AND class < '600' THEN 'Recreation'
WHEN class >= '600' AND class < '635' THEN 'Community Services'
WHEN class >= '636' AND class < '700' THEN 'Community Services'
WHEN class >= '700' AND class < '800' THEN 'Industrial'
WHEN class >= '800' AND class < '900' THEN 'State Assessed/Utilities'
WHEN class >= '900' AND class < '1000' THEN 'Conserved Area/Park'
ELSE 'Unclassified' END) as type, geom
from property_4326;

create table ownership as 
select gid, pinnum,
(CASE
            WHEN ((((property_4326.housenumbe::text || ' '::text) || property_4326.streetname::text) || ' '::text) || property_4326.streettype::text) = property_4326.address::text THEN 'owner_residence'::text
            WHEN property_4326.state::text <> 'NC'::text THEN 'out_of_state'::text
            WHEN property_4326.zipcode::text = ANY ('{28806,28804,28801,28778,28748,28715,28803,28704,28732,28730,28711,28709,28787,28805,28701}'::text[]) THEN 'in_county'::text
            ELSE 'in_state'::text
        END) AS ownership, 
        geom
from property_4326

create table ownership_residential as 
select gid, pinnum, class,
(CASE
            WHEN ((((property_4326.housenumbe::text || ' '::text) || property_4326.streetname::text) || ' '::text) || property_4326.streettype::text) = property_4326.address::text THEN 'owner_residence'::text
            WHEN property_4326.state::text <> 'NC'::text THEN 'out_of_state'::text
            WHEN property_4326.zipcode::text = ANY ('{28806,28804,28801,28778,28748,28715,28803,28704,28732,28730,28711,28709,28787,28805,28701}'::text[]) THEN 'in_county'::text
            ELSE 'in_state'::text
        END) AS ownership, 
        geom
from property_4326
where
class >= '100' and class < '200' 
or class = '416' 
or class = '411'
or class = '635';

create or replace view landval_nrm as
select a.pinnum, (case when landvalue = null or acreage = 0 then null 
	else a.landvalue / a.acreage end) as landval_nrm 
	 from property_4326 as a

create or replace view bldvalue_nrm as 
select a.pinnum, (case when buildingva = null or sqft = 0 then null
		  else a.buildingva / a.sqft end) as bldvalue_nrm
		  from building_val_sqft


update resilience_variables as a
set blockce10  =  b.blockce10
from census_parcel as b
where a.pinnum = b.pinnum;

update resilience_variables as a
set blockgroup_geoid10  =  b.blockgroup_geoid10
from census_parcel as b
where a.pinnum = b.pinnum;

update resilience_variables as a
set tractce  =  b.tractce10
from census_parcel as b
where a.pinnum = b.pinnum; 

update resilience_variables as a
set totalmarke =  b.totalmarke
from property_4326 as b
where a.pinnum = b.pinnum;

update resilience_variables as a
set appraisedv =  b.appraisedv 
from property_4326 as b
where a.pinnum = b.pinnum;

update resilience_variables as a
set taxvalue  =  b.taxvalue 
from property_4326 as b
where a.pinnum = b.pinnum;

update resilience_variables as a
set acreage  =  b.acreage 
from property_4326 as b
where a.pinnum = b.pinnum;

--12370 what is classed?

update resilience_variables as a
set class=  b.class
from property_4326 as b
where a.pinnum = b.pinnum;

update resilience_variables as a
set par_fl1yr_yn  =  b.yes_no
from par_fl1yr_yn as b
where a.pinnum = b.pin;

update resilience_variables as a
set  ownership =  b.ownership
from ownership as b
where a.pinnum = b.pinnum;

update resilience_variables as a
set exposure_levels1  =  b.exposure_levels 
from parcels_fl1yr_tab as b
where a.pinnum = b.pin;

update resilience_variables as a
set adcap_levels1  =  b.adcap_levels
from parcels_fl1yr_tab as b
where a.pinnum = b.pin;

update resilience_variables as a
set vuln_levels1  =  b.vuln_levels 
from parcels_fl1yr_tab as b
where a.pinnum = b.pin;

update resilience_variables as a
set exposure_levels5  =  b.exposure_levels 
from parcels_fl5yr_tab as b
where a.pinnum = b.pin;

update resilience_variables as a
set adcap_levels5  =  b.adcap_levels
from parcels_fl5yr_tab as b
where a.pinnum = b.pin;

update resilience_variables as a
set vuln_levels5  =  b.vuln_levels 
from parcels_fl5yr_tab as b
where a.pinnum = b.pin;

update resilience_variables as a
set exposure_levels_ls =  b.adcap_levels
from parcels_ls_tab as b
where a.pinnum = b.pin; 

update resilience_variables as a
set adcap_levels_ls  =  b.adcap_levels
from parcels_ls_tab as b
where a.pinnum = b.pin; 

update resilience_variables as a
set vuln_levels_ls  =  b.adcap_levels
from parcels_ls_tab as b
where a.pinnum = b.pin; 

update resilience_variables as a
set year  =  b.year_built
from year_built_com as b
where a.pinnum = b.pinnum;

update resilience_variables as a
set year  =  b.year_built
from year_built_res as b
where a.pinnum = b.pinnum;

update resilience_variables as a
set sqft =  b.sum 
from build_sqft_group_pinnum as b
where a.pinnum = b.pinnum;

update resilience_variables as a
set landval_nrm  =  b.landval_nrm
from landval_nrm as b
where a.pinnum = b.pinnum;

update resilience_variables as a
set bldvalue_nrm =  b.bldvalue_nrm 
from bldvalue_nrm as b
where a.pinnum = b.pinnum;

update resilience_variables as a
set parcel_type  =  b.type
from parcel_type as b
where a.pinnum = b.pinnum;
 
