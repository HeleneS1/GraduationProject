import psycopg2
import pandas as pd
from sqlalchemy import create_engine

to_acc = pd.read_csv('Sykehus-lokasjoner.csv', 'r', delimiter=',', encoding='iso-8859-1')
to_acc.rename(columns={'Id':'hosp_id', 
                       'Sykehus':'hosp_name', 
                       'Kommune':'hosp_city', 
                       'Lat':'hosp_lat',
                       'Long':'hosp_long'}, inplace=True)
to_acc['hosp_name_city'] = to_acc['hosp_name']+', ' + to_acc['hosp_city']
del to_acc['Pasientgrunnlag']

def populate(username, password_name, df, tablename):
    hostname = "ds-etl-academy.cgbivchwjzle.eu-west-1.rds.amazonaws.com"
    user = username
    password = password_name
    dbname = "gp_lama"
    constring = f"postgresql+psycopg2://{user}:{password}@{hostname}/{dbname}"
    engine = create_engine(constring, echo=False)  
    df.to_sql(tablename, engine, index=False, schema='LamaV2', if_exists='append', method='multi', chunksize=1000)


populate('student_lene', 'osama', to_acc, 'hospital_stage')

