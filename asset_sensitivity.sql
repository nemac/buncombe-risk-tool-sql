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

create or replace view communications_fld_vw as 
select * from resilience_variables where asset_type = 'Communications' 
and par_fl5yr_ = 'yes';


create or replace view communications_fld_vw as 
select * from resilience_variables where asset_type = 'Communications' 
and par_ls_yn = 'yes';


create or replace view commercial_fld_vw as 
select * from resilience_variables where asset_type = 'Commercial' 
and par_fl5yr_ = 'yes';

create or replace view commercial_fld_vw as 
select * from resilience_variables where asset_type = 'Commercial' 
and par_ls_yn = 'yes';

create or replace view industrial_fld_vw  as 
select * from resilience_variables where asset_type = 'Industrial' 
and par_fl5yr_ = 'yes';

create or replace view industrial_ls_vw as 
select * from resilience_variables where asset_type = 'Industrial' 
and par_ls_yn = 'yes';


create or replace view energy_fld_vw as 
select * from resilience_variables where asset_type = 'Energy' 
and par_fl5yr_ = 'yes';

create or replace view energy_ls_vw as 
select * from resilience_variables where asset_type = 'Energy' 
and par_ls_yn = 'yes';

create or replace view emergency_services_fld_vw as 
select * from resilience_variables where asset_type = 'Emerg Services' 
and par_fl5yr_ = 'yes';

create or replace view emergency_services_ls_vw as 
select * from resilience_variables where asset_type = 'Emerg Services' 
and par_ls_yn = 'yes';

create or replace view water_resources_fld_vw as 
select * from resilience_variables where asset_type = 'Water Resources' 
and par_fl5yr_ = 'yes';

create or replace view water_resources_ls_vw as 
select * from resilience_variables where asset_type = 'Water Resources' 
and par_ls_yn = 'yes';

create or replace view city_parks_fld_vw as 
select * from resilience_variables where asset_type = 'City Parks' 
and par_fl5yr_ = 'yes';

create or replace view city_parks_ls_vw as 
select * from resilience_variables where asset_type = 'City Parks' 
and par_ls_yn = 'yes';

create or replace view historic_structures_fld_vw as 
select * from resilience_variables where asset_type = 'Historic Structure' 
and par_fl5yr_ = 'yes';

create or replace view historic_structures_ls_vw as 
select * from resilience_variables where asset_type = 'Historic Structure' 
and par_ls_yn = 'yes';
