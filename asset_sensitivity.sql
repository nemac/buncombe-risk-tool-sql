create or replace view building_pinnum_vw as
SELECT a.pinnum as pin, b.geom 
from resilience_variables as a 
join building_footprints as b 
on st_intersects(a.geom,b.geom)
group by a.pinnum, b.geom;  

alter table resilience_variables
add column asset_type text;

select * from historic_district_define_vw;

create or replace view historic_district_vw as
SELECT b.pinnum as pinnum
from local_historic_district_overlay as a 
join resilience_variables as b 
on st_intersects(a.geom,b.geom)
group by b.pinnum;

create or replace view historic_district_define_vw as 
select a.pinnum, (case when a.pinnum = b.pinnum then 'Historic Structure' else 
null end) as asset_type from historic_district_vw as a, resilience_variables as b 
where a.pinnum = b.pinnum;

create or replace view historic_structures_vw as
SELECT b.pinnum as pinnum
from historic_landmarks_register_properties_point as a 
join resilience_variables as b 
on st_intersects(a.geom,b.geom)
group by b.pinnum;

create or replace view historic_structures_define_vw as 
select a.pinnum, (case when a.pinnum = b.pinnum then 'Historic Structure' else 
null end) as asset_type from historic_structures_vw as a, resilience_variables as b 
where a.pinnum = b.pinnum;

create or replace view asset_type as 
select gid, pinnum, (
CASE WHEN class >= '400' AND class < '411' THEN 'Commercial'
when class = '934' THEN 'City Parks'
WHEN class >= '412' AND class < '416' THEN 'Commercial'
WHEN class >= '417' AND class < '500' THEN 'Commercial'
WHEN class >= '700' AND class < '800' THEN 'Industrial'
WHEN class = '830' THEN 'Communications'
WHEN class = '831' THEN 'Communications'
WHEN class = '836' THEN 'Communications'
WHEN class = '810' THEN 'Energy'
WHEN class = '812' THEN 'Energy'
WHEN class = '817' THEN 'Energy'
WHEN class = '818' THEN 'Energy'
WHEN class = '640' THEN 'Emerg Services'
WHEN class = '641' THEN 'Emerg Services'
WHEN class = '642' THEN 'Emerg Services'
WHEN class = '662' THEN 'Emerg Services'
WHEN class = '820' THEN 'Water Resources'
WHEN class = '822' THEN 'Water Resources'     
WHEN class = '853' THEN 'Water Resources'
ELSE null END) as asset_type, geom
from resilience_variables;

update resilience_variables as a 
set asset_type = b.asset_type 
from asset_type as b
where a.pinnum = b.pinnum;

update resilience_variables as a 
set asset_type = b.asset_type
from historic_structures_define_vw as b 
where a.pinnum = b.pinnum;

update resilience_variables as a 
set asset_type = b.asset_type
from historic_district_define_vw as b 
where a.pinnum = b.pinnum;
--------------------------------communications---------------------------------
drop view communications_vw cascade;
drop view commercial_vw cascade;
drop view energy_vw cascade;
drop view industrial_vw cascade;
drop view city_parks_vw cascade;
drop view emergency_services_vw cascade;
drop view water_resources_vw cascade;
drop view historic_structures_all_vw cascade;

--------------------------------communications---------------------------------
create or replace view communications_vw as 
select * from resilience_variables where asset_type = 'Communications';

create or replace view communications_fld_vw as 
select * from resilience_variables where asset_type = 'Communications' 
and par_fl5yr_ = 'yes';

create or replace view communications_flooded_total as
select
(select asset_type from resilience_variables where asset_type = 'Communications' limit 1),
(select count(pinnum) from communications_fld_vw) as flooded,
(select count(pinnum) from communications_vw) as total;

create or replace view communications_fld_percentage as 
select asset_type, flooded, total, flooded/total::float * 100 as percentage from communications_flooded_total
group by flooded,total, asset_type;

create or replace view communications_ls_vw as 
select * from resilience_variables where asset_type = 'Communications' 
and par_ls_yn = 'yes';

create or replace view communications_ls_total as
select
(select asset_type from resilience_variables where asset_type = 'Communications' limit 1),
(select count(pinnum) from communications_ls_vw) as landslide,
(select count(pinnum) from communications_vw) as total;

create or replace view communications_ls_percentage as 
select asset_type, landslide, total, landslide/total::float * 100 as percentage from communications_ls_total
group by landslide,total ,asset_type;




----------------------------commercial---------------------------------------------

create or replace view commercial_vw as 
select * from resilience_variables where asset_type = 'Commercial';

create or replace view commercial_fld_vw as 
select * from resilience_variables where asset_type = 'Commercial' 
and par_fl5yr_ = 'yes';

create or replace view commercial_flooded_total as
select
(select asset_type from resilience_variables where asset_type = 'Commercial' limit 1),
(select count(pinnum) from commercial_fld_vw) as flooded,
(select count(pinnum) from commercial_vw) as total;

create or replace view commercial_fld_percentage as 
select asset_type, flooded, total, flooded/total::float * 100 as percentage from commercial_flooded_total
group by flooded,total,asset_type;

create or replace view commercial_ls_vw as 
select * from resilience_variables where asset_type = 'Commercial' 
and par_ls_yn = 'yes';

create or replace view commercial_ls_total as
select
(select asset_type from resilience_variables where asset_type = 'Commercial' limit 1),
(select count(pinnum) from commercial_ls_vw) as landslide,
(select count(pinnum) from commercial_vw) as total;

create or replace view commercial_ls_percentage as 
select asset_type, landslide, total, landslide/total::float * 100 as percentage from commercial_ls_total
group by landslide,total,asset_type;


--------------------industrial-------------------------------------------

create or replace view industrial_vw  as 
select * from resilience_variables where asset_type = 'Industrial'; 

create or replace view industrial_fld_vw  as 
select * from resilience_variables where asset_type = 'Industrial' 
and par_fl5yr_ = 'yes';

create or replace view industrial_flooded_total as
select
(select asset_type from resilience_variables where asset_type = 'Industrial' limit 1),
(select count(pinnum) from industrial_fld_vw) as flooded,
(select count(pinnum) from industrial_vw) as total;

create or replace view industrial_fld_percentage as 
select asset_type, flooded, total, flooded/total::float * 100 as percentage from industrial_flooded_total
group by flooded,total,asset_type;

create or replace view industrial_ls_vw as 
select * from resilience_variables where asset_type = 'Industrial' 
and par_ls_yn = 'yes';

create or replace view industrial_ls_total as
select
(select asset_type from resilience_variables where asset_type = 'Industrial' limit 1),
(select count(pinnum) from industrial_ls_vw) as landslide,
(select count(pinnum) from industrial_vw) as total;

create or replace view industrial_ls_percentage as 
select asset_type, landslide, total, landslide/total::float * 100 as percentage from industrial_ls_total
group by landslide,total,asset_type;


--------------------energy----------------------------------------------
create or replace view energy_vw as 
select * from resilience_variables where asset_type = 'Energy';

create or replace view energy_fld_vw as 
select * from resilience_variables where asset_type = 'Energy' 
and par_fl5yr_ = 'yes';

create or replace view energy_flooded_total as
select
(select asset_type from resilience_variables where asset_type = 'Energy' limit 1),
(select count(pinnum) from energy_fld_vw) as flooded,
(select count(pinnum) from energy_vw) as total;

create or replace view energy_fld_percentage as 
select asset_type, flooded, total, flooded/total::float * 100 as percentage from energy_flooded_total
group by flooded,total,asset_type;

create or replace view energy_ls_vw as 
select * from resilience_variables where asset_type = 'Energy' 
and par_ls_yn = 'yes';

create or replace view energy_ls_total as
select
(select asset_type from resilience_variables where asset_type = 'Energy' limit 1),
(select count(pinnum) from energy_ls_vw) as landslide,
(select count(pinnum) from energy_vw) as total;

create or replace view energy_ls_percentage as 
select asset_type, landslide, total, landslide/total::float * 100 as percentage from energy_ls_total
group by landslide,total,asset_type;


------------------------emergency----------------------------------------

create or replace view emergency_services_vw as 
select * from resilience_variables where asset_type = 'Emerg Services';

create or replace view emergency_services_fld_vw as 
select * from resilience_variables where asset_type = 'Emerg Services' 
and par_fl5yr_ = 'yes';


create or replace view emergency_services_flooded_total as
select
(select asset_type from resilience_variables where asset_type = 'Emerg Services' limit 1),
(select count(pinnum) from emergency_services_fld_vw) as flooded,
(select count(pinnum) from emergency_services_vw) as total;

create or replace view emergency_services_fld_percentage as 
select asset_type, flooded, total, flooded/total::float * 100 as percentage from emergency_services_flooded_total
group by flooded,total,asset_type;

create or replace view emergency_services_ls_vw as 
select * from resilience_variables where asset_type = 'Emerg Services' 
and par_ls_yn = 'yes';

create or replace view emergency_services_ls_total as
select
(select asset_type from resilience_variables where asset_type = 'Emerg Services' limit 1),
(select count(pinnum) from emergency_services_ls_vw) as landslide,
(select count(pinnum) from energy_vw) as total;

create or replace view emergency_services_ls_percentage as 
select asset_type, landslide, total, landslide/total::float * 100 as percentage from emergency_services_ls_total
group by landslide,total,asset_type;


-------------------------water resources-------------------------------
create or replace view water_resources_vw as 
select * from resilience_variables where asset_type = 'Water Resources';

create or replace view water_resources_fld_vw as 
select * from resilience_variables where asset_type = 'Water Resources' 
and par_fl5yr_ = 'yes';

create or replace view water_resources_flooded_total as
select
(select asset_type from resilience_variables where asset_type = 'Water Resources' limit 1),
(select count(pinnum) from water_resources_fld_vw) as flooded,
(select count(pinnum) from water_resources_vw) as total;

create or replace view water_resources_fld_percentage as 
select asset_type, flooded, total, flooded/total::float * 100 as percentage from water_resources_flooded_total
group by flooded,total,asset_type;

create or replace view water_resources_ls_vw as 
select * from resilience_variables where asset_type = 'Water Resources' 
and par_ls_yn = 'yes';

create or replace view water_resources_ls_total as
select
(select asset_type from resilience_variables where asset_type = 'Water Resources' limit 1),
(select count(pinnum) from water_resources_ls_vw) as landslide,
(select count(pinnum) from water_resources_vw) as total;

create or replace view water_resources_ls_percentage as 
select asset_type, landslide, total, landslide/total::float * 100 as percentage from water_resources_ls_total
group by landslide,total,asset_type;


---------------------------city parks-------------------------------
create or replace view city_parks_vw as 
select * from resilience_variables where asset_type = 'City Parks' ;

create or replace view city_parks_fld_vw as 
select * from resilience_variables where asset_type = 'City Parks' 
and par_fl5yr_ = 'yes';

create or replace view city_parks_flooded_total as
select
(select asset_type from resilience_variables where asset_type = 'City Parks' limit 1),
(select count(pinnum) from city_parks_fld_vw) as flooded,
(select count(pinnum) from city_parks_vw) as total;

create or replace view city_parks_fld_percentage as 
select asset_type, flooded, total, flooded/total::float * 100 as percentage from city_parks_flooded_total
group by flooded,total,asset_type;

create or replace view city_parks_ls_vw as 
select * from resilience_variables where asset_type = 'City Parks' 
and par_ls_yn = 'yes';

create or replace view city_parks_ls_total as
select
(select asset_type from resilience_variables where asset_type = 'City Parks' limit 1),
(select count(pinnum) from city_parks_ls_vw) as landslide,
(select count(pinnum) from city_parks_vw) as total;

create or replace view city_parks_ls_percentage as 
select asset_type, landslide, total, landslide/total::float * 100 as percentage from city_parks_ls_total
group by landslide,total,asset_type;



-----------historic structures-------------------------------------------
create or replace view historic_structures_all_vw as 
select * from resilience_variables where asset_type = 'Historic Structure' ;

create or replace view historic_structures_fld_vw as 
select * from resilience_variables where asset_type = 'Historic Structure' 
and par_fl5yr_ = 'yes';

create or replace view historic_structures_flooded_total as
select
(select asset_type from resilience_variables where asset_type = 'Historic Structure' limit 1),
(select count(pinnum) from historic_structures_fld_vw) as flooded,
(select count(pinnum) from historic_structures_all_vw) as total;

create or replace view historic_structures_fld_percentage as 
select asset_type,  flooded, total, flooded/total::float * 100 as percentage from historic_structures_flooded_total
group by flooded,total,asset_type;

create or replace view historic_structures_ls_vw as 
select * from resilience_variables where asset_type = 'Historic Structure' 
and par_ls_yn = 'yes';

create or replace view historic_structures_ls_total as
select
(select asset_type from resilience_variables where asset_type = 'Historic Structure' limit 1),
(select count(pinnum) from historic_structures_ls_vw) as landslide,
(select count(pinnum) from historic_structures_all_vw) as total;

create or replace view historic_structures_ls_percentage as 
select asset_type, landslide, total, landslide/total::float * 100 as percentage from historic_structures_ls_total
group by landslide,total,asset_type;

----food analysis-------------
create or replace view food_infrastructure_buncombe_vw as 
select  b.pinnum, a.* from food_infrastructure_buncombe as a, resilience_variables as b 
where a.address::text like concat('%', upper(b.address), '%');

create or replace view food_snap_retailers_vw as
select  b.pinnum, a.* from food_snap_retailers as a, resilience_variables as b 
where a.address::text like concat('%', upper(b.address), '%');



create or replace view landslide_summary_vw as 
select * from historic_structures_ls_percentage 
union all
select * from city_parks_ls_percentage 
union all
select * from water_resources_ls_percentage 
union all
select * from emergency_services_ls_percentage 
union all
select * from energy_ls_percentage 
union all
select * from industrial_ls_percentage 
union all
select * from commercial_ls_percentage 
union all
select * from communications_ls_percentage;



create or replace view flood_summary_vw as 
select * from historic_structures_fld_percentage 
union all
select * from city_parks_fld_percentage 
union all
select * from water_resources_fld_percentage 
union all
select * from emergency_services_fld_percentage 
union all
select * from energy_fld_percentage 
union all
select * from industrial_fld_percentage 
union all
select * from commercial_fld_percentage 
union all
select * from communications_fld_percentage;


select * from flood_summary_vw;


