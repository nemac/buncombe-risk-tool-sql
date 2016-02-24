create or replace view vw_residential_properties as 
select * from property_class_4326 where 
class = '100'
or class = '105'
or class = '120'
or class = '121'
or class = '122' 
or class = '170'
or class = '180'
or class = '411'
or class = '300'
or class = '311'
or class = '416'; 

create or replace view vw_non_bc_residents as
select * from vw_residential_properties 
where cityname != 'ASHEVILLE'
AND cityname != 'MILLS RIVER'
AND cityname != 'LEICESTER'
AND cityname != 'AVERY'
AND cityname != 'SWANNANOA'
AND cityname != 'BLACK MOUNTAIN'
AND cityname != 'FAIRVIEW' 
AND cityname != 'FLETCHER' 
AND cityname != 'BILTMANDE FANDEST' 
AND cityname != 'WEAVERVILLE'
AND cityname != 'WOODFIN'
AND cityname != 'MONTREAT'
AND cityname != 'AVERY CREEK'
AND cityname != 'CANDLER'
AND cityname != 'BARNARDSVILLE'
AND cityname != 'FANDKS OF IVY'
AND cityname != 'JUPITER'
AND cityname != 'RIDGECREST'
AND cityname != 'FLAT CREEK'
AND cityname != 'ENKA'
AND cityname != 'ROYAL PINES' 
AND cityname != 'ALEXANDER'
AND cityname != 'ARDEN'
AND cityname != 'SKYLAND'
AND cityname != 'STOCKSVILLE'
AND cityname != 'IVY'
AND cityname != 'SANDY MUSH'
AND cityname != 'HAZEL'
AND cityname != 'LIMESTONE'
AND cityname != 'BLACK MTN'
AND cityname != 'FRENCH BROAD'
AND cityname != 'MONTREAT'
AND cityname != 'BILTMORE FOREST'
and cityname != 'BILTMORE LAKE'
and cityname != 'PISGAH FOREST';

create or replace view vw_non_owner as 
select * from vw_residential_properties;

delete from vw_non_owner 
where streetname LIKE concat('%',address,'%') or 
address LIKE concat('%',streetname,'%')
