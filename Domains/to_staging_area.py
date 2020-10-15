
import psycopg2
import pandas as pd
from sqlalchemy import create_engine

#Hospitals
sykehus = pd.read_csv('Sykehus-lokasjoner.csv', 'r', delimiter=',', encoding='iso-8859-1') 

hospitals = sykehus[['Id',
                    'Sykehus',
                    'Kommune',
                    'Lat',
                    'Long']]
#renames columns-matching the tables in sql 
hospitals.rename(columns={'Id':'hosp_id', 'Sykehus':'hosp_name', 'Kommune':'hosp_city', 'Lat':'hosp_lat', 
                          'Long':'hosp_long'}, inplace=True)

accidents = pd.read_csv('MVP_ulykker.csv', delimiter=',', encoding='iso-8859-1')
accidents.columns
acc_new = accidents[['id',
                     'url',
                     'ost_coord',
                     'nord_coord',
                     'antall drepte',
                     'dato'
                     
                     ]]
acc_new.columns
acc_new.rename(columns={'id':'acc_id', 'url':'url',
                          'ost_coord':'loc_lat', 'nord_coord':'loc_long', 'antall drepte':'death', 'dato': 'date'}, inplace=True)


#Populate hospital
# hostname = "ds-etl-academy.cgbivchwjzle.eu-west-1.rds.amazonaws.com"
# user = "student_lene"
# password = "osama"
# dbname = "gp_lama"
# constring = f"postgresql+psycopg2://{user}:{password}@{hostname}/{dbname}"
# engine = create_engine(constring, echo=False)  
# hospitals.to_sql('d_hospital', engine, index=False, schema='public', if_exists='append', method='multi', chunksize=1000)

#populate as a function. 
def populate(username, password_name, df, tablename):
    hostname = "ds-etl-academy.cgbivchwjzle.eu-west-1.rds.amazonaws.com"
    user = username
    password = password_name
    dbname = "gp_lama"
    constring = f"postgresql+psycopg2://{user}:{password}@{hostname}/{dbname}"
    engine = create_engine(constring, echo=False)  
    df.to_sql(tablename, engine, index=False, schema='public', if_exists='append', method='multi', chunksize=1000)


populate('student_lene', 'osama', acc_new, 'accident_stage')