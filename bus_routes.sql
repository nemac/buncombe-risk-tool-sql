drop table bus_routs_poly_ls

create table bus_routes_poly_ls as 
select a.gid, a.geom from bus_routes_dissolve as a 
join debris_flow as b
on st_intersects(a.geom,b.geom);

create table bus_routes_poly_fld as 
select a.gid, a.geom from bus_routes_dissolve as a
join fl5yr as b
on st_intersects(a.geom,b.geom);

create or replace view bus_routes_ls_cbg as 
select (sum(st_length(a.geom::geography)) * .0006) /2 as flow_path_miles, b.geo_id, b.geom 
from bus_routes_poly_ls as a
join coa_census_block_groups as b
on st_intersects(a.geom,b.geom)
group by b.geo_id, b.geom;

create or replace view bus_routes_ls_cbg as 
select (sum(st_length(a.geom::geography)) * .0006) /2 as flow_path_miles, a.geo_id, b.geom 
from bus_routes_poly_fld as a
join coa_census_block_groups as b
on a.geo_id = b.geo_id
where route_id is null
group by a.geo_id, b.geom;
