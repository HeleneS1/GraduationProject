""" Extract locations from Google distance matrix API"""
import requests 
import json
import pandas as pd
from tqdm import tqdm_gui

    
def get_google_dist_matrix(origin, destination):
    API_KEY = 'AIzaSyDWSe3IXVf3HWOoaOfjmTOI54gj0_HpkCc'
    units = 'metric'

    URL_root = f"https://maps.googleapis.com/maps/api/distancematrix/json?units={units}&origins={origin}&destinations={destination}&key={API_KEY}"
    r = requests.get(URL_root)
    root = r.content
    google = json.loads(root.decode('utf-8'))

    try:
        status_google = google['rows'][0]['elements'][0]['status']
        if status_google == 'OK':
            distance_google = google['rows'][0]['elements'][0]['distance']['text']
            distance = distance_google.split(' ')
            distance_km = distance[0]
            time_google = google['rows'][0]['elements'][0]['duration']['text']
            time = time_google.split(' ')
            for element in time:
                if len(time) == 4: 
                    minutes = int(time[0])*60 
                    minutes += int(time[2])
                elif len(time) == 2:
                    minutes = time[0]
                else: 
                    minutes = 0
            time_min = minutes       
    except:
        distance_km = 0
        time_min = 0
    
    return [distance_km, time_min]

def add_google_matrix():
    distance_km_list = []
    time_min_list = []
    id_list = []
    
    df_ulykke = pd.read_csv('./csv/komplett2010.csv', 'r', delimiter=',', encoding='iso-8859-1')
    df_ulykke = df_ulykke[['Ulykkes id','latitude', 'longitude','s_id','s_latitude', 's_longitude' ]]
    
    for i in tqdm_gui(range(len(df_ulykke))):
        try: 
            acc_id = df_ulykke['Ulykkes id'][i]
            lat = df_ulykke['latitude'][i]
            long = df_ulykke['longitude'][i]   
            origin = f'{lat},{long}' 
            s_lat = df_ulykke['s_latitude'][i]
            s_long = df_ulykke['s_longitude'][i]
            destination = f'{s_lat},{s_long}'
        except:
            pass
        try:
            get = get_google_dist_matrix(origin, destination)
        except:
            get = [0,0]
        distance_km = get[0]
        time_min = get[1]
        distance_km_list.append(distance_km)
        time_min_list.append(time_min)
        id_list.append(acc_id)
        print(f'Added info for ulykke {acc_id}')
    google_distance = pd.DataFrame({'sv_acc_id':id_list, 'road_km':distance_km_list, 'time_min':time_min_list})
    google_distance.to_csv('google_distance_matrix_test.csv')
    print('I made the file, now let me rest -.- ')
    
add_google_matrix()


