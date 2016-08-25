
alter table resilience_variables
add column asset_type text;

-------non parcel asset definitions-------
------historic structures-------------

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


update resilience_variables as a 
set asset_type = b.asset_type
from historic_structures_define_vw as b 
where a.pinnum = b.pinnum;

update resilience_variables as a 
set asset_type = b.asset_type
from historic_district_define_vw as b 
where a.pinnum = b.pinnum;


----city parks-------------------------
create or replace view coa_parks_vw as 
SELECT b.pinnum as pinnum
from coa_parks as a 
join resilience_variables as b 
on st_intersects(a.geom,b.geom)
group by b.pinnum;

create or replace view coa_parks_define_vw as 
select a.pinnum, (case when a.pinnum = b.pinnum then 'City Parks' else 
null end) as asset_type from historic_structures_vw as a, resilience_variables as b 
where a.pinnum = b.pinnum;

update resilience_variables as a 
set asset_type = b.asset_type
from coa_parks_define_vw as b 
where a.pinnum = b.pinnum;




---------------food assets definition--------------

create or replace view food_infrastructure_vw as 
select  b.pinnum, a.* from food_infrastructure_buncombe as a, resilience_variables as b 
where a.address::text like concat('%', upper(b.address), '%');

create or replace view food_infrastructure_vw_defintion AS
select a.pinnum, (case when a.pinnum = b.pinnum then 'Food' else 
null end) as asset_type from food_infrastructure_vw as a, resilience_variables as b 
where a.pinnum = b.pinnum;

create or replace view food_snap_retailers_vw as
select  b.pinnum, a.* from food_snap_retailers as a, resilience_variables as b 
where a.address::text like concat('%', upper(b.address), '%');

create or replace view food_snap_retailers_defintion_vw as 
select a.pinnum, (case when a.pinnum = b.pinnum then 'Food' else 
null end) as asset_type from food_snap_retailers_vw as a, resilience_variables as b 
where a.pinnum = b.pinnum;


update resilience_variables as a 
set asset_type =b.asset_type 
from food_snap_retailers_defintion_vw as b 
where a.pinnum = b.pinnum;

update resilience_variables as a 
set asset_type =b.asset_type 
from food_infrastructure_vw_defintion as b 
where a.pinnum = b.pinnum;
 

------dam asset defintion-------



----parcel type asset defintion-------------

create or replace view asset_type as 
select pinnum, ( CASE
WHEN class >= '100' AND class < '200' THEN 'Residential'
WHEN class = '411' THEN 'Residential'
WHEN class = '411' THEN 'Residential'
WHEN class = '416' THEN 'Residential'
WHEN class = '476' THEN 'Residential'
WHEN class = '631' THEN 'Residential'
WHEN class = '633' THEN 'Residential'
WHEN class = '634' THEN 'Residential'
WHEN class = '635' THEN 'Residential'
WHEN class = '644' THEN 'Residential'
WHEN class = '250' THEN 'Commercial'
WHEN class >= '400' AND class < '411' THEN 'Commercial'
WHEN class >= '412' AND class < '416' THEN 'Commercial'
WHEN class >= '417' AND class < '476' THEN 'Commercial'
WHEN class >= '477' AND class < '500' THEN 'Commercial'
WHEN class = '307' THEN 'Parking'
WHEN class = '437' THEN 'Parking'
WHEN class = '438' THEN 'Parking'
WHEN class = '850' THEN 'Waste'
WHEN class = '852' THEN 'Waste'
WHEN class = '853' THEN 'Waste'
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
WHEN class = '660' THEN 'Emerg Services'
WHEN class = '661' THEN 'Emerg Services'
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


-------------------------------if starting fresh uncomment and run the script---------------------------------
-- drop view communications_vw cascade;
-- drop view commercial_vw cascade;
-- drop view energy_vw cascade;
-- drop view industrial_vw cascade;
-- drop view city_parks_vw cascade;
-- drop view emergency_services_vw cascade;
-- drop view water_resources_vw cascade;
-- drop view historic_structures_all_vw cascade;

create or replace view communications_vw as 
select * from resilience_variables where asset_type = 'Communications';

create or replace view communications_fld_vw as 
select * from resilience_variables where asset_type = 'Communications' 
and par_fl5yr_yn = 'yes';

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

create or replace view communications_wf_vw as 
select * from resilience_variables where asset_type = 'Communications' 
and par_wf_yn = 'yes';

create or replace view communications_wf_total as
select
(select asset_type from resilience_variables where asset_type = 'Communications' limit 1),
(select count(pinnum) from communications_wf_vw) as landslide,
(select count(pinnum) from communications_vw) as total;

create or replace view communications_wf_percentage as 
select asset_type, landslide, total, landslide/total::float * 100 as percentage from communications_wf_total
group by landslide,total ,asset_type;



----------------------------commercial---------------------------------------------


--flood---

create or replace view commercial_vw as 
select * from resilience_variables where asset_type = 'Commercial';

create or replace view commercial_fld_vw as 
select * from resilience_variables where asset_type = 'Commercial' 
and par_fl5yr_yn = 'yes';

create or replace view commercial_flooded_total as
select
(select asset_type from resilience_variables where asset_type = 'Commercial' limit 1),
(select count(pinnum) from commercial_fld_vw) as flooded,
(select count(pinnum) from commercial_vw) as total;

create or replace view commercial_fld_percentage as 
select asset_type, flooded, total, flooded/total::float * 100 as percentage from commercial_flooded_total
group by flooded,total,asset_type;


---landslide------

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


--wildfire---

create or replace view commercial_wf_vw as 
select * from resilience_variables where asset_type = 'Commercial' 
and par_wf_yn = 'yes';

create or replace view commercial_wf_total as
select
(select asset_type from resilience_variables where asset_type = 'Commercial' limit 1),
(select count(pinnum) from commercial_wf_vw) as wildfire,
(select count(pinnum) from commercial_vw) as total;

create or replace view commercial_wf_percentage as 
select asset_type, wildfire, total, wildfire/total::float * 100 as percentage from commercial_wf_total
group by wildfire,total,asset_type;




--------------------industrial-------------------------------------------

--flood-----

create or replace view industrial_vw  as 
select * from resilience_variables where asset_type = 'Industrial'; 

create or replace view industrial_fld_vw  as 
select * from resilience_variables where asset_type = 'Industrial' 
and par_fl5yr_yn = 'yes';

create or replace view industrial_flooded_total as
select
(select asset_type from resilience_variables where asset_type = 'Industrial' limit 1),
(select count(pinnum) from industrial_fld_vw) as flooded,
(select count(pinnum) from industrial_vw) as total;

create or replace view industrial_fld_percentage as 
select asset_type, flooded, total, flooded/total::float * 100 as percentage from industrial_flooded_total
group by flooded,total,asset_type;


--landslide--


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


--wildfire-----

create or replace view industrial_wf_vw as 
select * from resilience_variables where asset_type = 'Industrial' 
and par_wf_yn = 'yes';

create or replace view industrial_wf_total as
select
(select asset_type from resilience_variables where asset_type = 'Industrial' limit 1),
(select count(pinnum) from industrial_wf_vw) as wildfire,
(select count(pinnum) from industrial_vw) as total;

create or replace view industrial_wf_percentage as 
select asset_type, wildfire, total, wildfire/total::float * 100 as percentage from industrial_wf_total
group by wildfire,total,asset_type;






--------------------energy----------------------------------------------



--flood---

create or replace view energy_vw as 
select * from resilience_variables where asset_type = 'Energy';

create or replace view energy_fld_vw as 
select * from resilience_variables where asset_type = 'Energy' 
and par_fl5yr_yn = 'yes';

create or replace view energy_flooded_total as
select
(select asset_type from resilience_variables where asset_type = 'Energy' limit 1),
(select count(pinnum) from energy_fld_vw) as flooded,
(select count(pinnum) from energy_vw) as total;

create or replace view energy_fld_percentage as 
select asset_type, flooded, total, flooded/total::float * 100 as percentage from energy_flooded_total
group by flooded,total,asset_type;


--landslide--

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


--wildfire---

create or replace view energy_wf_vw as 
select * from resilience_variables where asset_type = 'Energy' 
and par_wf_yn = 'yes';

create or replace view energy_wf_total as
select
(select asset_type from resilience_variables where asset_type = 'Energy' limit 1),
(select count(pinnum) from energy_wf_vw) as wildfire,
(select count(pinnum) from energy_vw) as total;

create or replace view energy_wf_percentage as 
select asset_type, wildfire, total, wildfire/total::float * 100 as percentage from energy_wf_total
group by wildfire,total,asset_type;




------------------------emergency----------------------------------------

create or replace view emergency_services_vw as 
select * from resilience_variables where asset_type = 'Emerg Services';

--flood---

create or replace view emergency_services_fld_vw as 
select * from resilience_variables where asset_type = 'Emerg Services' 
and par_fl5yr_yn = 'yes';


create or replace view emergency_services_flooded_total as
select
(select asset_type from resilience_variables where asset_type = 'Emerg Services' limit 1),
(select count(pinnum) from emergency_services_fld_vw) as flooded,
(select count(pinnum) from emergency_services_vw) as total;

create or replace view emergency_services_fld_percentage as 
select asset_type, flooded, total, flooded/total::float * 100 as percentage from emergency_services_flooded_total
group by flooded,total,asset_type;


--landslide--

create or replace view emergency_services_ls_vw as 
select * from resilience_variables where asset_type = 'Emerg Services' 
and par_ls_yn = 'yes';

create or replace view emergency_services_ls_total as
select
(select asset_type from resilience_variables where asset_type = 'Emerg Services' limit 1),
(select count(pinnum) from emergency_services_ls_vw) as landslide,
(select count(pinnum) from emergency_services_vw) as total;

create or replace view emergency_services_ls_percentage as 
select asset_type, landslide, total, landslide/total::float * 100 as percentage from emergency_services_ls_total
group by landslide,total,asset_type;


--wildfire---

create or replace view emergency_services_wf_vw as 
select * from resilience_variables where asset_type = 'Emerg Services' 
and par_wf_yn = 'yes';

create or replace view emergency_services_wf_total as
select
(select asset_type from resilience_variables where asset_type = 'Emerg Services' limit 1),
(select count(pinnum) from emergency_services_wf_vw) as wildfire,
(select count(pinnum) from emergency_services_vw) as total;

create or replace view emergency_services_wf_percentage as 
select asset_type, wildfire, total, wildfire/total::float * 100 as percentage from emergency_services_wf_total
group by wildfire,total,asset_type;



-------------------------water resources-------------------------------

--flood--

create or replace view water_resources_vw as 
select * from resilience_variables where asset_type = 'Water Resources';

create or replace view water_resources_fld_vw as 
select * from resilience_variables where asset_type = 'Water Resources' 
and par_fl5yr_yn = 'yes';

create or replace view water_resources_flooded_total as
select
(select asset_type from resilience_variables where asset_type = 'Water Resources' limit 1),
(select count(pinnum) from water_resources_fld_vw) as flooded,
(select count(pinnum) from water_resources_vw) as total;

create or replace view water_resources_fld_percentage as 
select asset_type, flooded, total, flooded/total::float * 100 as percentage from water_resources_flooded_total
group by flooded,total,asset_type;

--landslide---

create or replace view water_resources_ls_vw as 
select * from resilience_variables where asset_type = 'Water Resources' 
and par_wf_yn = 'yes';

create or replace view water_resources_ls_total as
select
(select asset_type from resilience_variables where asset_type = 'Water Resources' limit 1),
(select count(pinnum) from water_resources_ls_vw) as landslide,
(select count(pinnum) from water_resources_vw) as total;

create or replace view water_resources_ls_percentage as 
select asset_type, landslide, total, landslide/total::float * 100 as percentage from water_resources_ls_total
group by landslide,total,asset_type;


--wildfire---

create or replace view water_resources_wf_vw as 
select * from resilience_variables where asset_type = 'Water Resources' 
and par_wf_yn = 'yes';

create or replace view water_resources_wf_total as
select
(select asset_type from resilience_variables where asset_type = 'Water Resources' limit 1),
(select count(pinnum) from water_resources_wf_vw) as wildfire,
(select count(pinnum) from water_resources_vw) as total;

create or replace view water_resources_wf_percentage as 
select asset_type, wildfire, total, wildfire/total::float * 100 as percentage from water_resources_wf_total
group by wildfire,total,asset_type;


---------------------------city parks-------------------------------

--flood--

create or replace view city_parks_fld_vw as 
select * from coa_parks where fl5yr_exp = 'yes';

create or replace view city_parks_flooded_total as
select
(select asset_type from resilience_variables where asset_type = 'City Parks' limit 1),
(select count(gid) from city_parks_fld_vw) as flooded,
(select count(gid) from coa_parks) as total;

create or replace view city_parks_fld_percentage as 
select asset_type, flooded, total, flooded/total::float * 100 as percentage from city_parks_flooded_total
group by flooded,total,asset_type;


--landslide---


create or replace view city_parks_ls_vw as 
select * from coa_parks where ls_exp = 'yes';

create or replace view city_parks_ls_total as
select
(select asset_type from resilience_variables where asset_type = 'City Parks' limit 1),
(select count(gid) from city_parks_ls_vw) as landslide,
(select count(gid) from coa_parks) as total;

create or replace view city_parks_ls_percentage as 
select asset_type, landslide, total, landslide/total::float * 100 as percentage from city_parks_ls_total
group by landslide,total,asset_type;


--wildfire-----

create or replace view city_parks_wf_vw as 
select * from coa_parks where wf_exp = 'yes';

create or replace view city_parks_wf_total as
select
(select asset_type from resilience_variables where asset_type = 'City Parks' limit 1),
(select count(gid) from city_parks_wf_vw) as wildfire,
(select count(gid) from coa_parks) as total;

create or replace view city_parks_wf_percentage as 
select asset_type, wildfire, total, wildfire/total::float * 100 as percentage from city_parks_wf_total
group by wildfire,total,asset_type;



-----------historic structures-------------------------------------------

--flood-

create or replace view historic_structures_all_vw as 
select * from resilience_variables where asset_type = 'Historic Structure' ;

create or replace view historic_structures_fld_vw as 
select * from resilience_variables where asset_type = 'Historic Structure' 
and par_fl5yr_yn = 'yes';

create or replace view historic_structures_flooded_total as
select
(select asset_type from resilience_variables where asset_type = 'Historic Structure' limit 1),
(select count(pinnum) from historic_structures_fld_vw) as flooded,
(select count(pinnum) from historic_structures_all_vw) as total;

create or replace view historic_structures_fld_percentage as 
select asset_type,  flooded, total, flooded/total::float * 100 as percentage from historic_structures_flooded_total
group by flooded,total,asset_type;


--landslide---

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


--wildfire---


create or replace view historic_structures_wf_vw as 
select * from resilience_variables where asset_type = 'Historic Structure' 
and par_wf_yn = 'yes';

create or replace view historic_structures_wf_total as
select
(select asset_type from resilience_variables where asset_type = 'Historic Structure' limit 1),
(select count(pinnum) from historic_structures_wf_vw) as wildfire,
(select count(pinnum) from historic_structures_all_vw) as total;

create or replace view historic_structures_wf_percentage as 
select asset_type, wildfire, total, wildfire/total::float * 100 as percentage from historic_structures_wf_total
group by wildfire,total,asset_type;

-----------------------food analysis-------------

--flood--


create or replace view food_all_vw as 
select * from resilience_variables where asset_type = 'Food' ;

create or replace view food_fld_vw as 
select * from resilience_variables where asset_type = 'Food' 
and par_fl5yr_yn = 'yes';

create or replace view food_flooded_total as
select
(select asset_type from resilience_variables where asset_type = 'Food' limit 1),
(select count(pinnum) from food_fld_vw) as flooded,
(select count(pinnum) from food_all_vw) as total;

create or replace view food_fld_percentage as 
select asset_type,  flooded, total, flooded/total::float * 100 as percentage from food_flooded_total
group by flooded,total,asset_type;


--landslide---

create or replace view food_ls_vw as 
select * from resilience_variables where asset_type = 'Food' 
and par_ls_yn = 'yes';

create or replace view food_ls_total as
select
(select asset_type from resilience_variables where asset_type = 'Food' limit 1),
(select count(pinnum) from food_ls_vw) as landslide,
(select count(pinnum) from food_all_vw) as total;

create or replace view food_ls_percentage as 
select asset_type, landslide, total, landslide/total::float * 100 as percentage from food_ls_total
group by landslide,total,asset_type;


--wildfire----

create or replace view food_wf_vw as 
select * from resilience_variables where asset_type = 'Food' 
and par_wf_yn = 'yes';

create or replace view food_wf_total as
select
(select asset_type from resilience_variables where asset_type = 'Food' limit 1),
(select count(pinnum) from food_wf_vw) as wildfire,
(select count(pinnum) from food_all_vw) as total;

create or replace view food_wf_percentage as 
select asset_type, wildfire, total, wildfire/total::float * 100 as percentage from food_wf_total
group by wildfire,total,asset_type;


--------------------------------waste---------------------------------

--flood--

create or replace view waste_vw as 
select * from resilience_variables where asset_type = 'Waste';

create or replace view waste_fld_vw as 
select * from resilience_variables where asset_type = 'Waste' 
and par_fl5yr_yn = 'yes';

create or replace view waste_flooded_total as
select
(select asset_type from resilience_variables where asset_type = 'Waste' limit 1),
(select count(pinnum) from waste_fld_vw) as flooded,
(select count(pinnum) from waste_vw) as total;

create or replace view waste_fld_percentage as 
select asset_type, flooded, total, flooded/total::float * 100 as percentage from waste_flooded_total
group by flooded,total, asset_type;


--landslide---

create or replace view waste_ls_vw as 
select * from resilience_variables where asset_type = 'Waste' 
and par_ls_yn = 'yes';

create or replace view waste_ls_total as
select
(select asset_type from resilience_variables where asset_type = 'Waste' limit 1),
(select count(pinnum) from waste_ls_vw) as landslide,
(select count(pinnum) from waste_vw) as total;

create or replace view waste_ls_percentage as 
select asset_type, landslide, total, landslide/total::float * 100 as percentage from waste_ls_total
group by landslide,total ,asset_type;

--wildfire--

create or replace view waste_wf_vw as 
select * from resilience_variables where asset_type = 'Waste' 
and par_wf_yn = 'yes';

create or replace view waste_wf_total as
select
(select asset_type from resilience_variables where asset_type = 'Waste' limit 1),
(select count(pinnum) from waste_wf_vw) as landslide,
(select count(pinnum) from waste_vw) as total;

create or replace view waste_wf_percentage as 
select asset_type, landslide, total, landslide/total::float * 100 as percentage from waste_wf_total
group by landslide,total ,asset_type;





---------------------parking-----------------------------------

--flood--

create or replace view parking_vw as 
select * from resilience_variables where asset_type = 'Parking';

create or replace view parking_fld_vw as 
select * from resilience_variables where asset_type = 'Parking' 
and par_fl5yr_yn = 'yes';

create or replace view parking_flooded_total as
select
(select asset_type from resilience_variables where asset_type = 'Parking' limit 1),
(select count(pinnum) from parking_fld_vw) as flooded,
(select count(pinnum) from parking_vw) as total;

create or replace view parking_fld_percentage as 
select asset_type, flooded, total, flooded/total::float * 100 as percentage from parking_flooded_total
group by flooded,total, asset_type;


--landslide---

create or replace view parking_ls_vw as 
select * from resilience_variables where asset_type = 'Parking' 
and par_ls_yn = 'yes';

create or replace view parking_ls_total as
select
(select asset_type from resilience_variables where asset_type = 'Parking' limit 1),
(select count(pinnum) from parking_ls_vw) as landslide,
(select count(pinnum) from parking_vw) as total;

create or replace view parking_ls_percentage as 
select asset_type, landslide, total, landslide/total::float * 100 as percentage from parking_ls_total
group by landslide,total ,asset_type;

--wildfire--

create or replace view parking_wf_vw as 
select * from resilience_variables where asset_type = 'Parking' 
and par_wf_yn = 'yes';

create or replace view parking_wf_total as
select
(select asset_type from resilience_variables where asset_type = 'Parking' limit 1),
(select count(pinnum) from parking_wf_vw) as landslide,
(select count(pinnum) from parking_vw) as total;

create or replace view parking_wf_percentage as 
select asset_type, landslide, total, landslide/total::float * 100 as percentage from parking_wf_total
group by landslide,total ,asset_type;



-----------------greenways------------

--flood
create or replace view greenways_fld as 
select a.* from greenways as a 
join fl5yr as b 
on st_intersects(a.geom, b.geom)
group by a.gid;

create or replace view greenways_fld_total as
select 
(select sum(st_length(geom::geography)) * .0006 from greenways_fld) as flooded_miles,
(select sum(st_length(geom::geography))* .0006 from greenways) as total_miles;

create or replace view greenways_fld_percentage as 
select flooded_miles, total_miles, flooded_miles/total_miles * 100 as percentage 
from greenways_fld_total 
group by flooded_miles, total_miles; 


---landslide

create or replace view greenways_ls as 
select a.* from greenways as a 
join debris_flow as b 
on st_intersects(a.geom, b.geom);

create or replace view greenways_ls_total as
select 
(select sum(st_length(geom::geography)) * .0006 from greenways_ls) as ls_miles,
(select sum(st_length(geom::geography))* .0006 from greenways) as total_miles;

create or replace view greenways_ls_percentage as 
select ls_miles, total_miles, ls_miles/total_miles * 100 as percentage 
from greenways_ls_total 
group by ls_miles, total_miles; 



---------------------------------------roads-------------------
--flood

create or replace view roads_fld as 
select a.* from roads_coa as a 
join fl5yr as b 
on st_intersects(a.geom, b.geom)
group by a.gid;

create or replace view roads_fld_total as
select 
(select sum(st_length(geom::geography)) * .0006 from roads_fld) as flooded_miles,
(select sum(st_length(geom::geography))* .0006 from roads_coa) as total_miles;

create or replace view roads_fld_percentage as 
select flooded_miles, total_miles, flooded_miles/total_miles * 100 as percentage 
from roads_fld_total 
group by flooded_miles, total_miles; 


--landslide


create or replace view roads_ls as 
select a.* from roads_coa as a 
join debris_flow as b 
on st_intersects(a.geom, b.geom);

create or replace view roads_ls_total as
select 
(select sum(st_length(geom::geography)) * .0006 from roads_ls) as ls_miles,
(select sum(st_length(geom::geography))* .0006 from roads_coa) as total_miles;

create or replace view roads_ls_percentage as 
select ls_miles, total_miles, ls_miles/total_miles * 100 as percentage 
from roads_ls_total 
group by ls_miles, total_miles; 




--------------------------------begin the summaries from each of the asset analysis-----------------------------


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
select * from communications_ls_percentage
union all 
select * from food_ls_percentage
union all 
select * from waste_ls_percentage
union all 
select * from parking_ls_percentage;

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
select * from communications_fld_percentage
union all 
select * from food_fld_percentage
union all 
select * from waste_fld_percentage
union all 
select * from parking_fld_percentage;

create or replace view wildfire_summary_vw as 
select * from historic_structures_wf_percentage 
union all
select * from city_parks_wf_percentage 
union all
select * from water_resources_wf_percentage 
union all
select * from emergency_services_wf_percentage 
union all
select * from energy_wf_percentage 
union all
select * from industrial_wf_percentage 
union all
select * from commercial_wf_percentage 
union all
select * from communications_wf_percentage
union all 
select * from food_wf_percentage
union all 
select * from waste_wf_percentage
union all 
select * from parking_wf_percentage;


select * from flood_summary_vw;  
