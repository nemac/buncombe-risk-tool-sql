create table parcel_type as
select gid, pinnum, (CASE WHEN class >= '100' AND class < '200' THEN 'Residential'
WHEN class = '411' THEN 'Residential'
WHEN class = '416' THEN 'Residential'
WHEN class = '635' THEN 'Residential'
WHEN class = '250' THEN 'Biltmore Estate'
WHEN class >= '300' AND class < '400' THEN 'Vacant Land'
WHEN class >= '400' AND class < '411' THEN 'Commercial'
WHEN class >= '412' AND class < '416' THEN 'Commercial'
WHEN class >= '417' AND class < '500' THEN 'Commercial'
WHEN class >= '500' AND class < '600' THEN 'Recreation'
WHEN class >= '600' AND class < '635' THEN 'Community Services'
WHEN class >= '636' AND class < '700' THEN 'Community Services'
WHEN class >= '700' AND class < '800' THEN 'Industrial'
WHEN class >= '800' AND class < '900' THEN 'State Assessed/Utilities'
WHEN class >= '900' AND class < '1000' THEN 'Conserved Area/Park'
ELSE 'Unclassified' END) as type, geom
from property_4326;

create table ownership as 
select gid, pinnum,
(CASE
            WHEN ((((property_4326.housenumbe::text || ' '::text) || property_4326.streetname::text) || ' '::text) || property_4326.streettype::text) = property_4326.address::text THEN 'owner_residence'::text
            WHEN property_4326.state::text <> 'NC'::text THEN 'out_of_state'::text
            WHEN property_4326.zipcode::text = ANY ('{28806,28804,28801,28778,28748,28715,28803,28704,28732,28730,28711,28709,28787,28805,28701}'::text[]) THEN 'in_county'::text
            ELSE 'in_state'::text
        END) AS ownership, 
        geom
from property_4326

create table ownership_residential as 
select gid, pinnum, class,
(CASE
            WHEN ((((property_4326.housenumbe::text || ' '::text) || property_4326.streetname::text) || ' '::text) || property_4326.streettype::text) = property_4326.address::text THEN 'owner_residence'::text
            WHEN property_4326.state::text <> 'NC'::text THEN 'out_of_state'::text
            WHEN property_4326.zipcode::text = ANY ('{28806,28804,28801,28778,28748,28715,28803,28704,28732,28730,28711,28709,28787,28805,28701}'::text[]) THEN 'in_county'::text
            ELSE 'in_state'::text
        END) AS ownership, 
        geom
from property_4326
where
class >= '100' and class < '200' 
or class = '416' 
or class = '411'
or class = '635'  
