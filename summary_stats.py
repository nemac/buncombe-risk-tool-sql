import pandas
from sqlalchemy import create_engine
import numpy as np
import psycopg2
from subprocess import call, Popen

engine = create_engine('postgresql://postgres:'insert password here'@127.0.0.1/'insert database name here') 

sql = """select * from flood_summary_vw"""

flood_summary = pandas.read_sql(sql, engine)

flood_summary.to_csv('flood_summary.csv', encoding= 'utf-8')

sql = """select * from landslide_summary_vw"""

landslide_summary = pandas.read_sql(sql, engine)

landslide_summary.to_csv('landslide_summary.csv', encoding= 'utf-8')


print 'This is the flood summary:' 
print  flood_summary

print 'This is the landslide summary'
print landslide_summary
