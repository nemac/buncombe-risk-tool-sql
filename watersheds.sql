update nlcd_bunc_vw 
set geom = st_makevalid(geom)

update nlcd_change_bunc_vw
set geom = st_makevalid(geom)

create or replace view nlcd_bunc_proportions as
select a.gid, 
sum((st_area(b.geom))/(st_area(a.geom)) * 100) as proportions, 
a.geom
from buncombe_watersheds as a, nlcd_bunc_vw as b
where st_intersects(b.geom, a.geom)
group by a.gid;

create or replace view nlcd_change_bunc_proportions as
select a.gid, 
sum((st_area(b.geom))/(st_area(a.geom)) * 100) as proportions,
a.geom
from buncombe_watersheds as a, nlcd_change_bunc_vw as b
where st_intersects(b.geom, a.geom)
group by a.gid;

alter table buncombe_watersheds 
add column total_amount double precision,
add column total_change double precision 

update buncombe_watersheds as a 
set total_amount = b.proportions
from nlcd_bunc_proportions as b
where a.gid = b.gid

update buncombe_watersheds as a 
set total_change = b.proportions
from nlcd_change_bunc_proportions as b
where a.gid = b.gid
