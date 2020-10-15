import pandas as pd
import numpy as np
from math import radians, cos, sin, asin, sqrt

sykehus = pd.read_csv('Sykehus-lokasjoner.csv', 'r', delimiter=',', encoding='iso-8859-1')
trafikkulykke = pd.read_csv('ny_vegvesen_data.csv', 'r', delimiter=',', encoding='iso-8859-1')

def dist(lat1, long1, lat2, long2):
    lat1, long1, lat2, long2 = map(radians, [lat1, long1, lat2, long2])
    # haversine formula 
    dlon = long2 - long1 
    dlat = lat2 - lat1 
    a = sin(dlat/2)**2 + cos(lat1) * cos(lat2) * sin(dlon/2)**2
    c = 2 * asin(sqrt(a)) 
    # Radius of earth in kilometers is 6371
    km = 6371* c
    return km

def find_nearest(lat, long):
    distances = sykehus.apply(
        lambda row: dist(lat, long, row['latitude'], row['longitude']), 
        axis=1)
    return sykehus.loc[distances.idxmin(), 'Sykehus']

trafikkulykke['sykehus'] = trafikkulykke.apply(
    lambda row: find_nearest(row['latitude'], row['longitude']), 
    axis=1)
