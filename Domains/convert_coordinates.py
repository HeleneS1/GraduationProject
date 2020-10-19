""" This file contains a convertor that takes in a csv file with UTM coordinates 
and converts them to lat/lon coordinates. Returns a CSV file with the distance """ 


def convert_coordinates():
    import pandas as pd
    import utm

    df = pd.read_csv('ulykker.csv')
    latlon_list = []

    for i in range(len(df)):
        ost = df['Easting'][i]  
        nord = df['Northing'][i]
        latlon = utm.to_latlon(ost, nord, 33, 'U', strict=False)
        latlon_list.append(latlon)


    wee = list(zip(*latlon_list))
    (latitude, longitude) = wee

    df['Latitude'] = latitude
    del df['Easting']
    df['Longitude'] = longitude
    del df['Northing']

    df.to_csv('ulykker_latlon.csv')
    print('I made it :) ')

if __name__=='__main__':
    convert_coordinates()
