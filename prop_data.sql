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
deed_date  character varying(50),deed_inst  character varying(50) ,selling_price numeric ,qualified_sale numeric ,
vacant_lot  character varying(50),disqual_code  character varying(50),seller_1_id  character varying(50)
,seller_2_id character varying(50),buyer_1_id  character varying(50),buyer_2_id  character varying(50));

