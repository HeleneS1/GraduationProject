""" The program in this file takes in a colosest_hosp.csv and calculates the distance 
between the location of the accident and the closest hospital. it returns a CSV file 
with the calculated distance.  """ 

import pandas as pd
import numpy as np
from math import radians, cos, sin, asin, sqrt
import haversine as hs

sykehus = pd.read_csv('Sykehus-lokasjoner.csv', 'r', delimiter=',', encoding='iso-8859-1')
trafikkulykke = pd.read_csv('MVP_ulykker_2010_latlon.csv', 'r', delimiter=',', encoding='iso-8859-1')

sykehus.rename(columns = {'id':'s_id'}, inplace = True)

## OBS! Husk å fjerne nullverdier fra dataframen where lat/long = [Null]


#find closest hospital id and add to df
def nearest(row, df):
    dist_squared = (row.latitude - df.latitude) ** 2 + (row.longitude - df.longitude) ** 2
    smallest_idx = dist_squared.argmin()
    return df.loc[smallest_idx, 's_id']
near = trafikkulykke.apply(nearest, args=(sykehus,), axis=1)
trafikkulykke['nearest_hospital'] = near

#calculate distance between two gps points for a sphere
def dist(lat1, long1, lat2, long2):
    lat1, long1, lat2, long2 = map(radians, [lat1, long1, lat2, long2])
    dlon = long2 - long1 
    dlat = lat2 - lat1 
    a = sin(dlat/2)**2 + cos(lat1) * cos(lat2) * sin(dlon/2)**2
    c = 2 * asin(sqrt(a))
    km = 6371* c
    return km


def find_nearest(lat, long):
    distances = sykehus.apply(
        lambda row: dist(lat, long, row['latitude'], row['longitude']), 
        axis=1)
    return sykehus.loc[distances.idxmin(), 'Sykehus']

def add_nearest_hospital():
    trafikkulykke['sykehus'] = trafikkulykke.apply(
    lambda row: find_nearest(row['latitude'], row['longitude']), 
    axis=1)

#rename to separate similar names when merged
sykehus.rename(columns = {'id':'s_id', 'latitude':'s_latitude', 'longitude':'s_longitude'}, inplace = True)
trafikkulykke.rename(columns = {'nearest_hospital':'s_id'}, inplace = True)

# add new column to separate hospitals with similar names
sykehus['hospital'] = sykehus['Sykehus'] + ', ' + sykehus['Kommune']

#merge sykehus and trafikkulykker
trafikkulykker_merge = pd.merge(trafikkulykke, sykehus, how='left', on='s_id')

#calculate and add the distance to a nearest hospital to the dataframe
trafikkulykker_merge['distance'] = [dist(trafikkulykker_merge.latitude[i],trafikkulykker_merge.longitude[i],trafikkulykker_merge.s_latitude[i],trafikkulykker_merge.s_longitude[i]) for i in range(len(trafikkulykker_merge))]
trafikkulykker_merge['distance'] = trafikkulykker_merge['distance'].round(decimals=3)

#save to csv
trafikkulykker_merge.to_csv('trafikkulykker_komplett2010.csv')

