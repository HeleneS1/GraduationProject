#%% Import 
import pandas as pd
import numpy as np
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import MinMaxScaler
from sklearn.preprocessing import StandardScaler
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import confusion_matrix
from sklearn.impute import SimpleImputer
from sklearn.preprocessing import OneHotEncoder
import sklearn

ml = pd.read_csv('komplett2010.csv', 'r', delimiter=',', encoding='iso-8859-1') 
ml_copy = ml.copy() 

#%% Subset with new column

sub_set = ml_copy[['Ukedag',
                      'Uhell kategori',
                      'Dekketype',
                      'Føreforhold',
                      'Værforhold',
                      'Lysforhold',
                      'Antall kjørefelt',
                      'Fartsgrense',
                      'Temperatur',
                      'Alvorlighetsgrad',
                      'latitude',
                      'longitude',
                      'distance'
                      
                      ]]

#New empty columns in sub_set
sub_set['Killed_serious_injured'] = None


sub_set.loc[(sub_set["Alvorlighetsgrad"] == 'Dødsulykke') |
            (sub_set["Alvorlighetsgrad"] == 'Ulykke med alvorlig skadde') |
            (sub_set["Alvorlighetsgrad"] == 'Ulykke med meget alvorlig skadde') 
            ,'Killed_serious_injured'] = 1

sub_set.loc[(sub_set["Alvorlighetsgrad"] == 'Ulykke med lettere skadde') |
            (sub_set["Alvorlighetsgrad"] == 'Ulykke med ukjent alvorlighetsgrad') |
            (sub_set["Alvorlighetsgrad"] == 'Ulykke med uskadde') 
            ,'Killed_serious_injured'] = 0

del sub_set['Alvorlighetsgrad']

#%% #Onehotencoder weekday

weekday_ohe = OneHotEncoder()
weekday_ohe.fit(sub_set[['Ukedag']])
weektext = weekday_ohe.transform(sub_set[['Ukedag']]).todense()
sub_set['Mandag'] = weektext[:,2]
sub_set['Tirsdag'] = weektext[:,5]
sub_set['Onsdag'] = weektext[:,3]
sub_set['Torsdag'] = weektext[:,6]
sub_set['Fredag'] = weektext[:,0]
sub_set['lørdag'] = weektext[:,1]
sub_set['Søndag'] = weektext[:,4]
del sub_set['Ukedag']

#%% Onehotencoder accident categpry
uhell_ohe = OneHotEncoder()
uhell_ohe.fit(sub_set[['Uhell kategori']])
uhelltext = uhell_ohe.transform(sub_set[['Uhell kategori']]).todense()
sub_set['Bilulykke'] = uhelltext[:,0]
sub_set['MC-ulykke'] = uhelltext[:,2]
sub_set['Sykkelulykke'] = uhelltext[:,3]
sub_set['Forgjenger_eller_akende_involvert'] = uhelltext[:,1]
del sub_set['Uhell kategori']

#%% Nullvalues/ Onehotencoder surface 

sub_set['Dekketype'].fillna('Ukjent', inplace=True)

dekketype_ohe = OneHotEncoder()
dekketype_ohe.fit(sub_set[['Dekketype']])
dekketypetext = dekketype_ohe.transform(sub_set[['Dekketype']]).todense()
sub_set['Asfalt_oljegrus'] = dekketypetext[:,1]
sub_set['Grus'] = dekketypetext[:,4]
sub_set['Gatestein'] = dekketypetext[:,3]
sub_set['Betong_betongstein'] = dekketypetext[:,2]
sub_set['Annet_dekke'] = dekketypetext[:,0]
sub_set['Ukjent_dekketype'] = dekketypetext[:,5]
del sub_set['Dekketype']

#%% Nullvalues/ OneHotEncoder Driving Conditions

sub_set['Føreforhold'].fillna('Ukjent', inplace=True)

foreforhold_ohe = OneHotEncoder()
foreforhold_ohe.fit(sub_set[['Føreforhold']])
forforholdtext = foreforhold_ohe.transform(sub_set[['Føreforhold']]).todense()
sub_set['Ukjent_forforhold'] = forforholdtext[:,4]
sub_set['Tørr,bar_veg'] = forforholdtext[:,3]
sub_set['Våt,bar_veg'] = forforholdtext[:,5]
sub_set['Delvis_snø/isbelagt_veg'] = forforholdtext[:,0]
sub_set['Snø/isbelagt_veg'] = forforholdtext[:,2]
sub_set['Glatt_ellers'] = forforholdtext[:,1]

del sub_set['Føreforhold']

#%% Nullcalues/ OneHotEncoder weatherconditions

sub_set['Værforhold'].fillna('Ukjent', inplace=True)

vaer_ohe= OneHotEncoder()
vaer_ohe.fit(sub_set[['Værforhold']])
vaertext = vaer_ohe.transform(sub_set[['Værforhold']]).todense()
sub_set['Dårlig_sikt_forøvrig'] = vaertext[:,0]
sub_set['Dårlig_sikt,_nedbør'] = vaertext[:,1]
sub_set['Dårlig_sikt,tåke_eller_dis'] = vaertext[:,2]
sub_set['God_sikt,nedbør'] = vaertext[:,3]
sub_set['God sikt_opphold'] = vaertext[:,4]
sub_set['Ukjent_sikt'] = vaertext[:,5]   

del sub_set['Værforhold']

#%% Nullvalues / OneHotEncoder lighting conditions

sub_set['Lysforhold'].fillna('Ukjent', inplace=True)

lys_ohe = OneHotEncoder()
lys_ohe.fit(sub_set[['Lysforhold']])
lystext = lys_ohe.transform(sub_set[['Lysforhold']]).todense()
sub_set['Dagslys'] = lystext[:,0]
sub_set['Mørkt_med_vegbelysning'] = lystext[:,1]
sub_set['Mørkt uten vegbelysning'] = lystext[:,2]
sub_set['Tussmørke_skumring'] = lystext[:,3]
sub_set['Ukjent_lysforhold'] = lystext[:,4]

del sub_set['Lysforhold']

#%% Nullvalues/ MinMaxScaler lanes

antall_felt_imputer = SimpleImputer(strategy='most_frequent')
antall_felt_imputer.fit(sub_set[['Antall kjørefelt']])
sub_set['Antall kjørefelt'] = antall_felt_imputer.transform(sub_set[['Antall kjørefelt']])

felt_minmax = MinMaxScaler()
felt_minmax.fit(sub_set[['Antall kjørefelt']])
kjore_minmax = felt_minmax.transform(sub_set[['Antall kjørefelt']])

sub_set['Kjørefelt_ant'] = kjore_minmax

del sub_set['Antall kjørefelt']

#%% Nullvalues/ Minmax scaler speedlimit
#Fartsgrense
#Fjerner nullvalues fartsgrense
fartsgrense_imputer = SimpleImputer(strategy='most_frequent')
fartsgrense_imputer.fit(sub_set[['Fartsgrense']])
sub_set['Fartsgrense'] = fartsgrense_imputer.transform(sub_set[['Fartsgrense']])

fartsgrense_minmax = MinMaxScaler()
fartsgrense_minmax.fit(sub_set[['Fartsgrense']])
farts_minmax = fartsgrense_minmax.transform(sub_set[['Fartsgrense']])

sub_set['Fartsgrense_mm'] = farts_minmax
del sub_set['Fartsgrense']

#%% MinMax - Latitude
lat_minmax = MinMaxScaler()
lat_minmax.fit(sub_set[['latitude']])
lati_minmax = lat_minmax.transform(sub_set[['latitude']])

sub_set['latitude_mm'] = lati_minmax
del sub_set['latitude']

#%% MinMaxScaler - Longitude

long_minmax = MinMaxScaler()
long_minmax.fit(sub_set[['longitude']])
longi_minmax = long_minmax.transform(sub_set[['longitude']])

sub_set['longitude_mm'] = longi_minmax
del sub_set['longitude']

#%% MinMaxScaler Distance 
dis_minmax = MinMaxScaler()
dis_minmax.fit(sub_set[['distance']])
distance_minmax = dis_minmax.transform(sub_set[['distance']])

sub_set['distance_mm'] = distance_minmax
del sub_set['distance'] 

#%% Nullvalues / Scaling temperature
#Fjener nullverdier
temp_imputertrain = SimpleImputer(strategy='median')
temp_imputertrain.fit(sub_set[['Temperatur']])
sub_set['Temperatur'] = temp_imputertrain.transform(sub_set[['Temperatur']])

sub_set['Temperatur'] = sub_set['Temperatur'] / 47

#%%% Split into train and test
sub_train, sub_test = train_test_split(sub_set, test_size=0.2, random_state=420)

#%% Undersampling and shuffle

sub_train['Killed_serious_injured'].value_counts()

nullres = sub_train[sub_train.Killed_serious_injured == 0].index
random_indices = np.random.choice(nullres, 5652, replace=False)
nullsamp = sub_train.loc[random_indices]

nullres = sub_train[sub_train.Killed_serious_injured == 1].index
random = np.random.choice(nullres, 5652, replace=False)
onesamp = sub_train.loc[random]

train_df = pd.concat([nullsamp, onesamp], axis=0)

shuffle_df = sklearn.utils.shuffle(train_df)

#%% Divide into features and label

y_train = shuffle_df['Killed_serious_injured']
x_train = shuffle_df
del x_train['Killed_serious_injured']

y_test = sub_test['Killed_serious_injured']
x_test = sub_test
del x_test['Killed_serious_injured']
 
#%% Secure same datatype and transform into numpy. 

y_train = y_train.astype('float64')
y_test = y_test.astype('float64')
x_train = x_train.astype('float64')
x_test = x_test.astype('float64')

y_train_np = np.c_[y_train].reshape(-1)
x_train_np = np.c_[x_train]
y_test_np = np.c_[y_test].reshape(-1)
x_test_np = np.c_[x_test]

#%%#Logistic model
model_log =  LogisticRegression(max_iter= 1000)
model_log.fit(x_train_np, y_train_np)

#Predictions
y_train_pred = model_log.predict(x_train_np)
y_test_pred = model_log.predict(x_test_np)

#Confusion matrix train
conmatreal = confusion_matrix(y_train_np, y_train_pred)
print(conmatreal)

#Precision: TP/ (TP+FP)
3322/(3322+2223)  # 0,59  
#Recall: TP/ (TP+FN)
3322/(3322+2330) #= 0.58 

#Confusion matrix test
conma = confusion_matrix(y_test_np, y_test_pred)
print(conma)
#Precision: TP/ (TP+FP)
794/(794+3498)  #  0,18
#Recall: TP/ (TP+FN)
794/(794+588) #  0.57 

# Visualisation
import matplotlib.pyplot as plt
from sklearn.metrics import plot_confusion_matrix
plot_confusion_matrix(model_log, y_test, y_test_pre)
plt.show()

#predict proba
y_train_pred_pb= model_log.predict_proba(x_train_np)
y_test_pred_pb= model_log.predict_proba(x_test_np)

conmat8= confusion_matrix(y_test_np, y_test_pred_pb[:,1]>0.3) 
print(conmat8)


#Precision: TP/ (TP+FP)
70/(70+402)  #= 0,14  
#Recall: TP/ (TP+FN)
70/(1984) #= 0.98

from sklearn.metrics import accuracy_score
accuracy_score(y_train_np, y_train_pred) # 59
accuracy_score(y_test_np, y_test_pred) # 60

accuracy_score(y_train_np, y_train_pred_pb) # 59
accuracy_score(y_test_np, y_test_pred_pb) # 60



