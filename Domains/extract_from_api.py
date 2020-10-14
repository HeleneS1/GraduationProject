""" This file extracts the requested info from vegvesenets API
    and returns a csv file with this info """ 
import requests
import json
import pandas as pd 
from datetime import date, timedelta

#enter start date & end date for date list
def date_list_generator():
    sdate = date(2020,1,1)   
    edate = date(2020,7,31)
    delta = edate - sdate
    date_list = []
    for i in range(delta.days + 1):
        day = sdate + timedelta(days=i)
        date_list.append((str(day)))
    return date_list


#%%    
# date must be on format '2020-02-08'   
def create_url(date):
    return f"https://nvdbapiles-v2.atlas.vegvesen.no/vegobjekter/570?segmentering=true&kartutsnitt=-1480772.1615443234%2C6203579.290491914%2C2680772.1615443234%2C8246420.709508086&egenskap=(5055%3D%27{date}%27)&inkluder=lokasjon%2Cmetadata%2Cegenskaper"   
  
#%%   

def fetch_from_date(date):
    url = create_url(date)
    r = requests.get(url)
    root = r.content
    ulykker = json.loads(root.decode('utf-8'))
       
    #extract important info 
    id_list = []
    id_url_list = []
    drepte_list = []
    north_list = []
    east_list = []
    date_list = []
    letters = set('POINT()Z')
    
    for i in range(len(ulykker['objekter'])):
        for j in range(len(ulykker['objekter'][i]['egenskaper'])):
            if ulykker['objekter'][i]['egenskaper'][j]['id'] == 5070:
                drepte = ulykker['objekter'][i]['egenskaper'][j]['verdi']
            if ulykker['objekter'][i]['egenskaper'][j]['id'] == 5123:
                dirty_geo = ulykker['objekter'][i]['egenskaper'][j]['verdi']
                temp_geo = ''
                for item in dirty_geo:  
                    if item in letters:
                        pass
                    else:
                        temp_geo += item
                geo_list = temp_geo.split(' ')
        try:
            east = float(geo_list[1])
            north = float(geo_list[2])
        except:
            east = 0
            north = 0
        else:
            pass
        id_ = ulykker['objekter'][i]['id']
        id_url = ulykker['objekter'][i]['href']
        try:
            id_list.append(id_)
        except:
            id_list.append(None)
        try:
            id_url_list.append(id_url)
        except:
            id_list.append(None)
        try:
            drepte_list.append(drepte)
        except:
            drepte_list.append(None)
        try:
            north_list.append(north)
        except:
            north_list.append(None)
        try:
            east_list.append(east)
        except:
            east_list.append(None)
        date_list.append(date)
    df_date = pd.DataFrame({'id':id_list, 'url':id_url_list, 'antall drepte':drepte_list, 'nord_coord':north_list, 'ost_coord':east_list, 'dato':date_list})
    return df_date

#%%
def fill_up_table():
    df_full = pd.DataFrame({'id':[], 'url':[], 'antall drepte':[], 'nord_coord':[], 'ost_coord':[], 'dato':[]})    
    date_list = date_list_generator()  
    ulykke_liste = []
    dato_list = []
    for dato in date_list:
        df_date = fetch_from_date(dato)
        df_full = pd.concat([df_full, df_date])
        print(f'Added {len(df_date)} rows to df_full for date:{dato}')
        ulykke_liste.append(len(df_date))
        dato_list.append(dato)
    df_full.to_csv('.\csv\MVP_ulykker.csv')
    df_logs = pd.DataFrame({'dato':dato_list, 'antall ulykker':ulykke_liste}) 
    df_logs.to_csv('.\csv\MVP_ulykker_log.csv')
    print('I made it :D')


if __name__=='__main__':
    fill_up_table()