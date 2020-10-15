""" This file contains a convertor that takes in a csv file with UTM coordinates 
and converts them to lat/lon coordinates. Returns a CSV file with the distance """ 

import utm
import pandas as pd
import numpy as np

df = pd.read_csv('MVP_vegvesen_data.csv')
df_coord = df[['ost_coord','nord_coord']]

latlon_list = []
for i in range(len(df_coord)):
    ost = df_coord.iloc[i,0]   
    nord = df_coord.iloc[i,1]
    latlon = utm.to_latlon(ost, nord, 33, 'U', strict=False)
    latlon_list.append(latlon)


wee = list(zip(*latlon_list))
(latitude, longitude) = wee

df['latitude'] = latitude
del df['ost_coord']
df['longitude'] = longitude
del df['nord_coord']

df.to_csv('ny_vegvesen_data.csv')

