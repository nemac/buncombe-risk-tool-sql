
create or replace view bus_routes_count_ls_cbg as 
select count(a.geom), a.geo_id, b.geom 
from bus_routes_ls as a
join coa_census_block_groups as b
on a.geo_id = b.geo_id
where route_id is null
group by a.geo_id, b.geom;

create or replace view bus_routes_count_fld_cbg as 
select count(a.geom), a.geo_id, b.geom 
from bus_routes_fld as a
join coa_census_block_groups as b
on a.geo_id = b.geo_id
where route_id is null
group by a.geo_id, b.geom;

create or replace view bus_routes_fld_cbg as 
select sum(st_length(a.geom::geography)) * .0006 as flooded_miles, a.geo_id, b.geom 
from bus_routes_fld as a
join coa_census_block_groups as b
on a.geo_id = b.geo_id
where route_id is null
group by a.geo_id, b.geom;

create or replace view bus_routes_ls_cbg as 
select sum(st_length(a.geom::geography)) * .0006 as flow_path_miles, a.geo_id, b.geom 
from bus_routes_ls as a
join coa_census_block_groups as b
on a.geo_id = b.geo_id
where route_id is null
group by a.geo_id, b.geom;

