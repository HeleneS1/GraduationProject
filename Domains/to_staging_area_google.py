import psycopg2
import pandas as pd
from sqlalchemy import create_engine

df = pd.read_csv('./csv/google_distance_matrix.csv')
df = df[['sv_acc_id', 'road_km', 'time_min']]

def populate(username, password_name, df, tablename):

    hostname = "ds-etl-academy.cgbivchwjzle.eu-west-1.rds.amazonaws.com"
    user = username
    password = password_name
    dbname = "gp_lama"
    constring = f"postgresql+psycopg2://{user}:{password}@{hostname}/{dbname}"
    engine = create_engine(constring, echo=False)  
    df.to_sql(tablename, engine, index=False, schema='LamaV2', if_exists='append', method='multi', chunksize=1000)


populate('student_lene', 'osama', df, 'google_stage')
