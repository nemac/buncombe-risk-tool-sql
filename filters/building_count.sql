select property_4326.pinnum, count(*) from property_4326, footprints_v2 where st_contains(property_4326.geom, footprints_v2.geom) 
group by property_4326.pinnum

create table building_counts as
select property_4326.pinnum, count(*) from property_4326, footprints_v2 where st_contains(property_4326.geom, footprints_v2.geom)  
group by property_4326.pinnum


update property as p
set building_counts = pr.count
from building_counts as pr
where p.pinnum = pr.pinnum
