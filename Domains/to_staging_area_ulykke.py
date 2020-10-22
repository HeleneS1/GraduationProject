import psycopg2
import pandas as pd
from sqlalchemy import create_engine

to_acc = pd.read_csv('komplett2010.csv', 'r', delimiter=',', encoding='iso-8859-1')
to_acc = to_acc[['Ulykkes id', 'URL',
       'Ukedag', 'Ulykkesdato', 'Ulykkesklokkeslett',
       'Behandlende politidistrikt', 'Uhell kategori',
       'Antall drepte i ulykken', 'Antall meget alvorlig skadet',
       'Antall alvorlig skadet', 'Antall lettere skadet', 'Alvorlighetsgrad',
       'Vegtype', 'Stedsforhold', 'Dekketype', 'Føreforhold', 'Værforhold',
       'Lysforhold', 'Kjørefelttype', 'Antall kjørefelt', 'Fartsgrense',
       'Temperatur', 'latitude', 'longitude', 's_id', 'distance']]

to_acc.rename(columns={'Ulykkes id':'acc_id', 
                       'URL':'url', 
                       'Ukedag':'weekday', 
                       'Ulykkesdato':'date', 
                       'Ulykkesklokkeslett':'time',
                       'Behandlende politidistrikt':'police_district', 
                       'Uhell kategori':'accident_category', 
                       'Antall drepte i ulykken':'killed_ct', 
                       'Antall meget alvorlig skadet':'very_seriously_injured_ct', 
                       'Antall alvorlig skadet':'serious_injured_ct', 
                       'Antall lettere skadet':'injured_ct', 
                       'Alvorlighetsgrad':'severity', 
                       'Vegtype':'road_type', 
                       'Stedsforhold':'area_type', 
                       'Dekketype':'road_surface', 
                       'Føreforhold':'driving_condition', 
                       'Værforhold':'weather_condition', 
                       'Lysforhold':'lighting_condition', 
                       'Kjørefelttype':'lane_type', 
                       'Antall kjørefelt':'lane_numbers', 
                       'Fartsgrense':'speed_limit',
                       'Temperatur': 'temperature',
                       'latitude': 'loc_lat',
                       'longitude':'loc_long'}, inplace=True)

def populate(username, password_name, df, tablename):
    hostname = "ds-etl-academy.cgbivchwjzle.eu-west-1.rds.amazonaws.com"
    user = username
    password = password_name
    dbname = "gp_lama"
    constring = f"postgresql+psycopg2://{user}:{password}@{hostname}/{dbname}"
    engine = create_engine(constring, echo=False)  
    df.to_sql(tablename, engine, index=False, schema='LamaV2', if_exists='append', method='multi', chunksize=1000)


populate('student_lene', 'osama', to_acc, 'accident_stage')
