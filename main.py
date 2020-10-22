#IMPORT LIBRARIES 


##################################################################################################
1. def date_list_generator():
# spesify start and end date 
# returns a list of all dates between start and end date. 

2. def create_url(date):
# creates url for statens vegvesens API call
# takes in date
# returns url as a string 

3. def get_one_date(date):
# returns a dataframe with accidents from the inputted date. 
# takes in a date
# each row is one accident

4. def get_all_dates():
# runs the get_one_date function for each date in the date_list from date_list_generator. 
# concatenates all dataframes to one large 
# saves dataframe as csv file 'ulykker.csv'

CVS: ulykker.csv 

5. def convert_coordinates():
# takes in csv file 'ulykker.csv' as a dataframe
# converts UTM location coordinates to latitude/longitude coordinates 
# saves data as csv file 'ulykker_latlon.csv' 

CSV: ulykker_latlon.csv
CSV: Sykehus-lokasjoner.csv

6. def populate_hospitals()
# populate table hospital_stage in database with data from 'Sykehus-lokasjoner.csv'

#osama
7. def nearest(row, df):
# find closest hospital id and add to df

#osama
8. def dist(lat1, long1, lat2, long2):
#calculate distance between two gps points for a sphere

#osama
9. def find_nearest(lat, long):

#osama
10. def add_nearest_hospital():
# returns a csv file with information about closest hospital 

CSV: komplett2010.csv

11. def populate_accidents()
# populate table accident_stage in staging area of database with data from 'komplett2010.csv'

12. def get_google_dist_matrix(origin, destination)
# takes in coordinates for accident (origin) and for the nearest hospital (destination)
# utilises the google distance matrix api to calculate driving distance and estimated time of travel
# gives back distance in km and time in min. 

13. def add_google_matrix(): 
# extracts ulykkes_id, lat, long, s_id, s_lat & s_long from komplett2010.csv
# uses the get_google_dist_matrix function to generate info for all instances in the file. 

14. def populate_google(): 
# populate table google_stage in staging area of database with data from 'google_distance_matrix.csv''