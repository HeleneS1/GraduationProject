import requests
import pandas as pd
import json
from datetime import date, timedelta
#%%
#enter start date & end date for date list  '2010,1,1' '2020,7,31'
def date_list_generator():
    sdate = date(2010,1,1)   
    edate = date(2020,1,31)
    delta = edate - sdate
    date_list = []
    for i in range(delta.days + 1):
        day = sdate + timedelta(days=i)
        date_list.append((str(day)))
    return date_list


#%%
def create_url(date):
    return f"https://nvdbapiles-v2.atlas.vegvesen.no/vegobjekter/570?segmentering=true&kartutsnitt=-1480772.1615443234%2C6203579.290491914%2C2680772.1615443234%2C8246420.709508086&egenskap=(5055%3D%27{date}%27)&inkluder=lokasjon%2Cmetadata%2Cegenskaper"   
#%%

def get_one_date(date):
    letters = set('POINT()Z')
    
    id_list = []
    url_list = []  
    ukedag_list = []
    dato_list = []
    klokke_list  = []
    distrikt_list = []
    kategori_list = []
    drepte_list = []
    m_alvorlig_list = []
    alvorlig_list = []
    lettere_list = []
    grad_list = []
    vegtype_list = []
    stedsforhold_list = []
    dekketype_list = []
    foreforhold_list = []
    verforhold_list = []
    lysforhold_list = []
    kjorefelttype_list = []
    kjorefelt_stk_list = []
    fartsgrense_list = []
    temperatur_list = []
    easting_list = []
    northing_list = []

    url = create_url(date)
    r = requests.get(url)
    root = r.content
    ulykker = json.loads(root.decode('utf-8'))
     
 
    for i in range(len(ulykker['objekter'])):
        Ulykkes_id = ulykker['objekter'][i]['id']
        url = ulykker['objekter'][i]['href']
        df = pd.json_normalize(ulykker['objekter'][i]['egenskaper'])
        df = df[['id', 'verdi']]  
        
        id_list.append(Ulykkes_id)
        url_list.append(url)
        
        
        try:
            Ukedag =                        df.loc[df['id']== 5054, 'verdi'].values[0]
            ukedag_list.append(Ukedag)
        except:
            ukedag_list.append(None)
        try:
            Ulykkesdato =                   df.loc[df['id']== 5055, 'verdi'].values[0]
            dato_list.append(Ulykkesdato)
        except:
            dato_list.append(None)
        try:
            Ulykkesklokkeslett =            df.loc[df['id']== 5056, 'verdi'].values[0]
            klokke_list.append(Ulykkesklokkeslett)
        except: 
            klokke_list.append(None)
        try:
            Behandlende_politidistrikt =    df.loc[df['id']== 5060, 'verdi'].values[0]
            distrikt_list.append(Behandlende_politidistrikt)
        except:
            distrikt_list.append(None)
        try:
            Uhell_katgori =                 df.loc[df['id']== 5065, 'verdi'].values[0]
            kategori_list.append(Uhell_katgori)
        except:
            kategori_list.append(None)
        try:
            Antall_drepte_i_ulykken =       df.loc[df['id']== 5070, 'verdi'].values[0]
            drepte_list.append(Antall_drepte_i_ulykken)
        except: 
            drepte_list.append(None)
        try:
            Antall_meget_alvorlig_skadet =  df.loc[df['id']== 5071, 'verdi'].values[0]
            m_alvorlig_list.append(Antall_meget_alvorlig_skadet)
        except:
            m_alvorlig_list.append(None)
        try:
            Antall_alvorlig_skadet =        df.loc[df['id']== 5072, 'verdi'].values[0]
            alvorlig_list.append(Antall_alvorlig_skadet)
        except:
            alvorlig_list.append(None)
        try: 
            Antall_lettere_skadet=          df.loc[df['id']== 5073, 'verdi'].values[0]
            lettere_list.append(Antall_lettere_skadet)
        except:
            lettere_list.append(None)
        try:
            Alvorlighetsgrad =              df.loc[df['id']== 5074, 'verdi'].values[0]
            grad_list.append(Alvorlighetsgrad)
        except:
            grad_list.append(None)
        try:
            Vegtype =                       df.loc[df['id']== 5075, 'verdi'].values[0]
            vegtype_list.append(Vegtype)
        except:
            vegtype_list.append(None)
        try:
            Stedsforhold =                  df.loc[df['id']== 5076, 'verdi'].values[0]
            stedsforhold_list.append(Stedsforhold)
        except:
            stedsforhold_list.append(None)
        try:
            Dekketype =                     df.loc[df['id']== 5077, 'verdi'].values[0]
            dekketype_list.append(Dekketype)
        except: 
            dekketype_list.append(None)
        try:
            Føreforhold =                   df.loc[df['id']== 5078, 'verdi'].values[0]
            foreforhold_list.append(Føreforhold)
        except:
            foreforhold_list.append(None)
        try:
            Værforhold =                    df.loc[df['id']== 5079, 'verdi'].values[0]
            verforhold_list.append(Værforhold)
        except:
            verforhold_list.append(None)
        try:
            Lysforhold =                    df.loc[df['id']== 5080, 'verdi'].values[0]
            lysforhold_list.append(Lysforhold)
        except:
            lysforhold_list.append(None)
        try:
            Kjørefelttype =                 df.loc[df['id']== 5081, 'verdi'].values[0]
            kjorefelttype_list.append(Kjørefelttype)
        except: 
            kjorefelttype_list.append(None)
        try:
            Antall_kjørefelt =              df.loc[df['id']== 5082, 'verdi'].values[0]
            kjorefelt_stk_list.append(Antall_kjørefelt)
        except:
            kjorefelt_stk_list.append(None)
        try:
            Fartsgrense =                   df.loc[df['id']== 5085, 'verdi'].values[0]
            fartsgrense_list.append(Fartsgrense)
        except: 
            fartsgrense_list.append(None)
        try:
            Temperatur =                    df.loc[df['id']== 5086, 'verdi'].values[0]
            temperatur_list.append(Temperatur)
        except:
            temperatur_list.append(None)
        try:
            Geometri_punkt =                df.loc[df['id']== 5123, 'verdi'].values[0]
            temp_geo = ''
            for char in Geometri_punkt:  
                 if char in letters:
                     pass
                 else:
                     temp_geo += char
            temp_geo = temp_geo.split(' ')
            easting = float(temp_geo[1])
            northing = float(temp_geo[2])
            easting_list.append(easting)
            northing_list.append(northing)
        except:
            easting_list.append(None)
            northing_list.append(None)    
        
    df_1_dag = pd.DataFrame({
                            'Ulykkes id': id_list, 
                            'URL': url_list,
                            'Ukedag': ukedag_list,
                            'Ulykkesdato': dato_list, 
                            'Ulykkesklokkeslett': klokke_list, 
                            'Behandlende politidistrikt': distrikt_list, 
                            'Uhell kategori':kategori_list, 
                            'Antall drepte i ulykken': drepte_list, 
                            'Antall meget alvorlig skadet':m_alvorlig_list, 
                            'Antall alvorlig skadet':alvorlig_list,
                            'Antall lettere skadet':lettere_list, 
                            'Alvorlighetsgrad':grad_list, 
                            'Vegtype':vegtype_list, 
                            'Stedsforhold':stedsforhold_list, 
                            'Dekketype':dekketype_list,
                            'Føreforhold':foreforhold_list,
                            'Værforhold':verforhold_list,
                            'Lysforhold':lysforhold_list,
                            'Kjørefelttype':kjorefelttype_list,
                            'Antall kjørefelt':kjorefelt_stk_list, 
                            'Fartsgrense':fartsgrense_list,
                            'Temperatur':temperatur_list,
                            'Easting':easting_list,
                            'Northing': northing_list                    
                            })
        
    return df_1_dag

#%%
    
def get_all_dates():
    date_list = date_list_generator()
    df_all_dates = pd.DataFrame({'Ulykkes id': [], 'URL': [],'Ukedag': [], 'Ulykkesdato': [], 
                            'Ulykkesklokkeslett': [], 'Behandlende politidistrikt': [], 
                            'Uhell kategori':[], 'Antall drepte i ulykken': [], 'Antall meget alvorlig skadet':[], 
                            'Antall alvorlig skadet':[], 'Antall lettere skadet':[], 
                            'Alvorlighetsgrad':[], 'Vegtype':[], 'Stedsforhold':[], 'Dekketype':[],
                            'Føreforhold':[], 'Værforhold':[],'Lysforhold':[],'Kjørefelttype':[],
                            'Antall kjørefelt':[], 'Fartsgrense':[],'Temperatur':[],'Easting':[],'Northing': []})
    ulykke_liste = []
    dato_list = []
    for dato in date_list:
        try:
            df_1_date = get_one_date(dato)
            df_all_dates = pd.concat([df_all_dates, df_1_date])
            print(f'Added {len(df_1_date)} rows to df_full for date:{dato}')
            ulykke_liste.append(len(df_1_date))
            dato_list.append(dato)
        except:
            print(f'I failed at date: {dato}')
    df_all_dates.to_csv('ulykker.csv', encoding='iso-8859-1')
    df_logs = pd.DataFrame({'dato':dato_list, 'antall ulykker':ulykke_liste}) 
    df_logs.to_csv('ulykker_log.csv', encoding='iso-8859-1')
    print('I made it :D')

if __name__=='__main__':
    get_all_dates()