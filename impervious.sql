update nlcd_bunc_vw 
set geom = st_makevalid(geom)

update nlcd_change_bunc_vw
set geom = st_makevalid(geom)

create or replace view nlcd_bunc_proportions as
select a.gid, 
sum((st_area(st_intersection(b.geom, a.geom))/(st_area(a.geom))) * 100) as proportions, 
a.geom
from buncombe_watersheds a, nlcd_bunc_vw as b
where st_intersects(b.geom, a.geom)
group by a.gid;

create or replace view nlcd_change_bunc_proportions as
select a.gid, 
sum(st_area(st_intersection(b.geom, a.geom))/(st_area(a.geom)) * 100) as proportions,
a.geom
from buncombe_watersheds as a, nlcd_change_bunc_vw as b
where st_intersects(b.geom, a.geom)
group by a.gid;

alter table buncombe_watersheds
drop column total_amount, 
drop column total_change;

alter table buncombe_watersheds 
add column total_amount double precision,
add column total_change double precision;

update coa_watersheds_4326 as a 
set total_amount = b.proportions
from nlcd_bunc_proportions as b
where a.gid = b.gid;

update coa_watersheds_4326 as a 
set total_change = b.proportions
from nlcd_change_bunc_proportions as b
where a.gid = b.gid

update nlcd_bunc_vw 
set geom = st_makevalid(geom);

update nlcd_change_bunc_vw
set geom = st_makevalid(geom);

create or replace view nlcd_bunc_proportions as
select a.gid, 
sum((st_area(st_intersection(b.geom, a.geom))/(st_area(a.geom))) * 100) as proportions, 
a.geom
from coa_census_block_groups a, nlcd_bunc_vw as b
where st_intersects(b.geom, a.geom)
group by a.gid;

create or replace view nlcd_change_bunc_proportions as
select a.gid, 
sum(st_area(st_intersection(b.geom, a.geom))/(st_area(a.geom)) * 100) as proportions,
a.geom
from coa_census_block_groups as a, nlcd_change_bunc_vw as b
where st_intersects(b.geom, a.geom)
group by a.gid;

alter table coa_census_block_groups 
add column total_amount double precision,
add column total_change double precision;

update coa_census_block_groups as a 
set total_amount = b.proportions
from nlcd_bunc_proportions as b
where a.gid = b.gid;

update coa_census_block_groups as a 
set total_change = b.proportions
from nlcd_change_bunc_proportions as b
where a.gid = b.gid
