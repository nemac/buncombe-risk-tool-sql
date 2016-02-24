create view vw_government_owned as
select * from property_class_4326
where class = '365' or
class = '306' or
class = '612' or
class = '613' or
class = '650' or
class = '651' or
class = '652' or
class = '653' or
class = '900' or
class = '930' or
class = '931' or
class = '932' or
class = '933' or
class = '934' or
class = '942' or 
class = '800' or 
class = '682';




create or replace view vw_vacant_lands as
select * from property_class_4326
where class = '300' or 
class = '340' 
