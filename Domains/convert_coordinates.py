""" This file contains a convertor that takes in a csv file with UTM coordinates 
and converts them to lat/lon coordinates. Returns a CSV file with the distance """ 

import pandas as pd
import utm

df = pd.read_csv('MVP_ulykker_2010.csv')
latlon_list = []

for i in range(len(df)):
    ost = df['ost_coord'][i]  
    nord = df['nord_coord'][i]
    latlon = utm.to_latlon(ost, nord, 33, 'U', strict=False)
    latlon_list.append(latlon)


wee = list(zip(*latlon_list))
(latitude, longitude) = wee

df['latitude'] = latitude
del df['ost_coord']
df['longitude'] = longitude
del df['nord_coord']

df[['id','url','antall drepte','latitude','longitude','dato']].to_csv('MVP_ulykker_2010_latlon.csv')

