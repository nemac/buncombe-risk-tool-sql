create table non-owner as 
select * from property;

delete from non_owner 
where streetname LIKE concat('%',address,'%') or 
address LIKE concat('%',streetname,'%')

