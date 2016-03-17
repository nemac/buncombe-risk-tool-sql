create table tax_com_refinement(pinnum character varying(50), bldg_num numeric, code character varying(50), description character varying(50), 
units numeric, unit_type character varying(50)) ;

create table tax_com_section(pinnum character varying(50), bldg_num numeric, sect_code character varying(50), sect_desc character varying(50), 
sect_sq_ft numeric, sect_stories numeric) ;

create table tax_com_building(pinnum character varying(50), bldg_num numeric, class_desc character varying(50),
sect_stories character varying(50), sect_sq_ft numeric, year_built numeric, grade character varying(50), condition character varying(50), bldg_value numeric) ;

create table tax_com_building(pinnum character varying(50), bldg_num numeric, class_desc character varying(50),
sect_stories character varying(50), sect_sq_ft numeric, year_built numeric, grade character varying(50), condition character varying(50), bldg_value numeric) ;

create table tax_res_building(pinnum character varying(50), bldg_num numeric, style character varying(50) ,sq_ft numeric ,year_built numeric, grade character varying(50),condition character varying(50),
foundation character varying(50) , roof_type character varying(50), hvac character varying(50),full_bath numeric ,half_bath numeric,additional_plumbing_fixtures numeric,
fireplace numeric ,special_feature numeric ,bedroom numeric ,basement_garage_doors numeric, indoor_pool numeric ,extra_kitchen numeric,elevator numeric , bldg_value numeric);

create table tax_res_section(pinnum character varying(50), bldg_num numeric, sect_code character varying(50), sect_desc character varying(50), sq_ft numeric, sect_stories numeric);

create table tax_sales_master(pinnum character varying(50),sell_date character varying(50),sell_no character varying(50),
plat_book character varying(50),plat_page  character varying(50),deed_book  character varying(50),deed_page character varying(50),
deed_date  character varying(50),deed_inst  character varying(50) ,selling_price numeric ,qualified_sale character varying(50),
vacant_lot  character varying(50),disqual_code  character varying(50),seller_1_id  character varying(50)
,seller_2_id character varying(50),buyer_1_id  character varying(50),buyer_2_id  character varying(50));


update tax_com_section set pinnum = REPLACE(LTRIM(REPLACE(pinnum, '0', ' ')), ' ', '0');

update tax_com_refinement set pinnum = REPLACE(LTRIM(REPLACE(pinnum, '0', ' ')), ' ', '0');

update tax_com_section set pinnum = REPLACE(LTRIM(REPLACE(pinnum, '0', ' ')), ' ', '0');

update tax_res_building set pinnum = REPLACE(LTRIM(REPLACE(pinnum, '0', ' ')), ' ', '0');

update tax_res_section set pinnum = REPLACE(LTRIM(REPLACE(pinnum, '0', ' ')), ' ', '0');

update tax_sales_master set pinnum = REPLACE(LTRIM(REPLACE(pinnum, '0', ' ')), ' ', '0');

alter table building_footprints 
ADD refinement_bldg_num numeric,
ADD refinement_code character varying(50), 
ADD refinement_description character varying(50), 
ADD refinement_units numeric, 
ADD refinement_unit_type character varying(50), 
ADD section_bldg_num numeric, 
ADD section_sect_code character varying(50), 
ADD section_sect_desc character varying(50), 
ADD section_sect_sq_ft numeric, 
ADD section_sq_ft numeric,
ADD section_sect_stories numeric, 
ADD building_bldg_num numeric, 
ADD building_class_desc character varying(50),
ADD building_sect_stories character varying(50),
ADD building_sect_sq_ft numeric, 
ADD building_sq_ft character varying(50),
ADD building_year_built numeric, 
ADD building_grade character varying(50), 
ADD building_condition character varying(50), 
ADD building_bldg_value numeric, 
ADD building_foundation character varying(50),
ADD building_roof_type character varying(50), 
ADD building_hvac character varying(50), 
ADD building_full_bath numeric, 
ADD building_half_bath numeric, 
ADD building_additional_plumbing_fixtures numeric, 
ADD building_fireplace numeric,
ADD building_special_feature numeric , 
ADD building_bedroom numeric, 
ADD building_basement_garage_doors numeric, 
ADD building_indoor_pool numeric,
ADD building_extra_kitchen numeric, 
ADD building_elevator numeric, 
ADD sell_date character varying(50), 
ADD sell_no character varying(50),
ADD plat_book   character varying(50), 
ADD plat_page  character varying(50), 
ADD deed_book  character varying(50),
ADD deed_page character varying(50),
ADD deed_date   character varying(50), 
ADD deed_inst  character varying(50) , 
ADD selling_price numeric , 
ADD qualified_sale character varying(50),
ADD vacant_lot  character varying(50), 
ADD disqual_code character varying(50), 
ADD seller_1_id  character varying(50) , 
ADD seller_2_id character varying(50), 
ADD buyer_1_id  character varying(50), 
ADD buyer_2_id  character varying(50);


Update building_footprints SET 
refinement_bldg_num = bldg_num,
refinement_code = code,
refinement_description = description,
refinement_units = units,
refinement_unit_type = unit_type
from tax_com_refinement
where building_footprints.pinnum = tax_com_refinement.pinnum;

Update building_footprints SET
section_bldg_num = bldg_num,
section_sect_code = sect_code,
section_sect_desc = sect_desc,
section_sect_sq_ft = sect_sq_ft,
section_sect_stories = sect_stories
from tax_com_section
where building_footprints.pinnum = tax_com_section.pinnum;;

Update building_footprints SET
section_bldg_num = bldg_num,
section_sect_code = sect_code,
section_sect_desc = sect_desc,
section_sect_sq_ft = sq_ft,
section_sect_stories = sect_stories 
from tax_res_section
where building_footprints.pinnum = tax_res_section.pinnum;

Update building_footprints SET
building_bldg_num = bldg_num,
building_class_desc = class_desc,
building_sect_stories = sect_stories,
building_sect_sq_ft = sect_sq_ft,
building_bldg_value = bldg_value, 
building_condition = condition,
building_grade = grade
from tax_com_building
where building_footprints.pinnum = tax_com_building.pinnum;

Update building_footprints SET 
building_bldg_num = bldg_num,
building_style = style,
building_sq_ft = sq_ft,
building_grade = grade, 
building_condition = condition, 
building_foundation = foundation, 
building_roof_type = roof_type,
building_hvac = hvac, 
building_full_bath = full_bath,
building_special_feature = special_feature,
building_bedroom = bedroom,
building_additional_plumbing_fixtures = additional_plumbing_fixtures,
building_fireplace = fireplace,
building_basement_garage_doors = basement_garage_doors,
building_indoor_pool = indoor_pool, 
building_extra_kitchen = extra_kitchen, 
building_elevator = elevator 
from tax_res_building
where building_footprints.pinnum = tax_res_building.pinnum;




