drop view bus_routes_fld;
drop view bus_routes_ls;

create or replace view bus_routes_wo_overpass as 
select * from bus_routes 
where route_id is null

create or replace view bus_routes_fld as 
select a.gid as gid, route_numb, geo_id, a.geom as geom
from bus_routes as a 
join fl5yr as b 
on st_intersects(a.geom, b.geom)
group by a.gid, a.geom;

create or replace view bus_routes_ls as 
select a.gid as gid, route_numb, geo_id, a.geom as geom
from bus_routes as a 
join debris_flow as b 
on st_intersects(a.geom, b.geom)
group by a.gid, a.geom;

create or replace view bus_routes_fld_cbg as 
select sum(st_length(a.geom::geography)) * .0006 as flooded_miles, a.geo_id, b.geom 
from bus_routes_fld as a
join coa_census_block_groups as b
on a.geo_id = b.geo_id
group by a.geo_id, b.geom

create or replace view bus_routes_ls_cbg as 
select sum(st_length(a.geom::geography)) * .0006 as flow_path_miles, a.geo_id, b.geom 
from bus_routes_ls as a
join coa_census_block_groups as b
on a.geo_id = b.geo_id
group by a.geo_id, b.geom

select count(a.*), route_numb, a.geo_id, b.geom 
from bus_routes_ls as a
join coa_census_block_groups as b
on a.geo_id = b.geo_id
group by route_numb, a.geo_id, b.geom

