--CREATE WILDFIRE SUMMARY STATISTICS EXPOSURE TABLE VIEW------------------- 
CREATE VIEW wf_statistics AS 
SELECT "case",
COUNT((case when max_pval = 'High Risk'then APPRAISEDV END)) AS High_Risk_parcels,
SUM((case when max_pval = 'High Risk'then APPRAISEDV END)) AS High_Risk,
COUNT((case when max_pval = 'Medium High Risk'  then APPRAISEDV END)) AS Medium_High_Risk_parcels,
SUM((case when max_pval = 'Medium High Risk'  then APPRAISEDV END)) AS Medium_High_Risk,
COUNT((case when max_pval = 'Medium'  then APPRAISEDV END)) AS Medium_Risk_parcels,
SUM((case when max_pval = 'Medium'  then APPRAISEDV END)) AS Medium_Risk,
COUNT((case when max_pval = 'Low Risk' then APPRAISEDV END)) AS Low_Risk_parcels,
SUM((case when max_pval = 'Low Risk' then APPRAISEDV END)) AS Low_Risk
from parcels_wildfire
group by "case"
UNION
SELECT 'Total',
COUNT((case when max_pval = 'High Risk'then APPRAISEDV END)) AS High_Risk_parcels,
SUM((case when max_pval = 'High Risk'then APPRAISEDV END)) AS High_Risk,
COUNT((case when max_pval = 'Medium High Risk'  then APPRAISEDV END)) AS Medium_High_Risk_parcels,
SUM((case when max_pval = 'Medium High Risk'  then APPRAISEDV END)) AS Medium_High_Risk,
COUNT((case when max_pval = 'Medium'  then APPRAISEDV END)) AS Medium_Risk_parcels,
SUM((case when max_pval = 'Medium'  then APPRAISEDV END)) AS Medium_Risk,
COUNT((case when max_pval = 'Low Risk' then APPRAISEDV END)) AS Low_Risk_parcels,
SUM((case when max_pval = 'Low Risk' then APPRAISEDV END)) AS Low_Risk
from parcels_wildfire;

---CREATE DEBRIS FLOW SUMMARY STATISTICS--------------

create or replace view debrflow_statistics as 
Select class as class,
sum(appraisedv) as ap,
sum(buildingva) as bv,
sum(landvalue) as lv,
count(*) as parcels
from parcels_debrflow
group by class
UNION 
SELECT 'TOTAL',
sum(appraisedv) as ap,
sum(buildingva) as bv,
sum(landvalue) as lv,
count(*) as parcels
from parcels_debrflow;


---CREATE DEBRIS FLOW SUMMARY STATISTICS BUILDINGS--------------

create or replace view debrflow_build_statistics as 
Select class as class,
sum(appraisedv) as ap,
sum(buildingva) as bv,
sum(landvalue) as lv,
count(*) as parcels
from build_debrflow
group by class
UNION 
SELECT 'TOTAL',
sum(appraisedv) as ap,
sum(buildingva) as bv,
sum(landvalue) as lv,
count(*) as parcels
from build_debrflow;

--CREATE 100 YEAR FLOODPLAIN SUMMARY STATISTICS------
create or replace view fl1yr_statistics as 
Select class as class,
sum(appraisedv) as ap,
sum(buildingva) as bv,
sum(landvalue) as lv,
count(*) as parcels
from parcels_fl1yr
group by class
UNION 
SELECT 'TOTAL',
sum(appraisedv) as ap,
sum(buildingva) as bv,
sum(landvalue) as lv,
count(*) as parcels
from parcels_fl1yr;


---CREATE 100 YEAR FLOODED BUILDINGS STATISTICS-----
create or replace view fl1yr_build_statistics as 
Select class as class,
sum(appraisedv) as ap,
sum(buildingva) as bv,
sum(landvalue) as lv,
count(*) as parcels
from buildings_fl1yr
group by class
UNION
SELECT 'TOTAL',
sum(appraisedv) as ap,
sum(buildingva) as bv,
sum(landvalue) as lv,
count(*) as parcels
from buildings_fl1yr;


--CREATE 500 YEAR FLOODPLAIN SUMMARY STATISTICS-------------------
create or replace view fl5yr_statistics as 
Select class as class,
sum(appraisedv) as ap,
sum(buildingva) as bv,
sum(landvalue) as lv,
count(*) as parcels
from parcels_fl5yr
group by class
UNION
SELECT 'TOTAL',
sum(appraisedv) as ap,
sum(buildingva) as bv,
sum(landvalue) as lv,
count(*) as parcels
from parcels_fl5yr;

---CREATE 500 YEAR FLOODED BUILDINGS STATISTICS-----
create or replace view fl5yr_statistics_build as 
Select class as class,
sum(appraisedv) as ap,
sum(buildingva) as bv,
sum(landvalue) as lv,
count(*) as parcels
from buildings_fl5yr
group by class
UNION
SELECT 'TOTAL',
sum(appraisedv) as ap,
sum(buildingva) as bv,
sum(landvalue) as lv,
count(*) as parcels
from buildings_fl5yr;


