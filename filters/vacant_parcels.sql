create table vacant_parcels as 
select * from property where class = 'Vacant Lands'

create or replace view vw_vacant_parcels as 
select * from property where class = 'Vacant Lands'
