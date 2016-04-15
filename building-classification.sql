----------------------------------------This is the start of the building classification vulnerability queries--------------
create or replace view buildingsfl1 as
Select p.* from building_footprints as p
join fl1yr as f
on ST_Intersects(p.geom, f.geom);

create or replace view property_buildingfl1 as
select p.*
from property as p 
inner join buildingsfl1 on p.pinnum = buildingsfl1.pinnum; 

create or replace view buildingsfl5 as
Select p.* from building_footprints as p
join fl5yr as f
on ST_Intersects(p.geom, f.geom);

create or replace view property_buildingfl5 as
select p.*
from property as p 
inner join buildingsfl5 on p.pinnum = buildingsfl5.pinnum; 

create or replace view buildingsls as
Select p.* from building_footprints as p
join debris_flow as f
on ST_Intersects(p.geom, f.geom);

create or replace view property_buildingls as
select p.*
from property as p 
inner join buildingsls on p.pinnum = buildingsls.pinnum; 


alter table property add column building_fl1 "text";
alter table property add column building_fl5 "text";
alter table property add column building_ls "text";

update property set building_fl1 = 
CASE WHEN EXISTS 
(SELECT * FROM property_buildingfl1 as a
WHERE  a.pinnum = property.pinnum ) 
THEN 1 ELSE 0 END;

update property set building_fl5 = 
CASE WHEN EXISTS 
(SELECT * FROM property_buildingfl5 as a
WHERE  a.pinnum = b.pinnum ) 
THEN 'yes' ELSE 'no'
end from property as b

update property set building_ls = 
CASE WHEN EXISTS 
(SELECT * FROM property_buildingls as a
WHERE  a.pinnum = b.pinnum ) 
THEN 'yes' ELSE 'no'
end from property as b
