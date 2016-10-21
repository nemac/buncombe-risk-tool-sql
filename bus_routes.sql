
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


CREATE OR REPLACE VIEW public.bus_routes_count_ls_cbg AS 
 SELECT count(a.geom) AS count,
    b.geom
   FROM bus_routes_ls a
     JOIN coa_census_block_groups b ON st_intersects(a.geom, b.geom)
  WHERE a.route_id IS NULL
  GROUP BY b.geom;


CREATE OR REPLACE VIEW public.bus_routes_count_fld_cbg AS 
 SELECT count(a.geom) AS count,
    b.geom
   FROM bus_routes_fld_500 a
     JOIN coa_census_block_groups b ON st_intersects(a.geom, b.geom)
  GROUP BY b.geom;


