import numpy as np
import pandas as pd
from pandas_profiling import ProfileReport
from sklearn.model_selection import train_test_split
from sklearn.impute import SimpleImputer

#load datasets
trafikkulykke = pd.read_csv('komplett2010.csv', 'r', delimiter=',', encoding='iso-8859-1')
google = pd.read_csv('google_distance_matrix.csv', 'r', delimiter=',', encoding='iso-8859-1')

#joining datasets to one using Ulykkes id
google.rename(columns = {'sv_acc_id':'Ulykkes id'}, inplace = True)
trafikkulykke = pd.merge(trafikkulykke, google, how='left', on='Ulykkes id')

#creating an empty column for label and populating it
trafikkulykke['alvorlig_ulykke'] = None

trafikkulykke.loc[(trafikkulykke["Alvorlighetsgrad"] == 'Dødsulykke') |
            (trafikkulykke["Alvorlighetsgrad"] == 'Ulykke med alvorlig skadde') |
            (trafikkulykke["Alvorlighetsgrad"] == 'Ulykke med meget alvorlig skadde') 
            ,'alvorlig_ulykke'] = 1
trafikkulykke.loc[(trafikkulykke["Alvorlighetsgrad"] == 'Ulykke med lettere skadde') |
            (trafikkulykke["Alvorlighetsgrad"] == 'Ulykke med ukjent alvorlighetsgrad') |
            (trafikkulykke["Alvorlighetsgrad"] == 'Ulykke med uskadde') 
            ,'alvorlig_ulykke'] = 0



#%% some necessary data prep on features
from sklearn.preprocessing import LabelEncoder
LE = LabelEncoder()
trafikkulykke['Ukedag'] = LE.fit_transform(trafikkulykke['Ukedag'])
trafikkulykke['Uhell kategori'] = LE.fit_transform(trafikkulykke['Uhell kategori'])

# 'Ukedag', 'Uhell kategori', 'Værforhold', 'Lysforhold', 'Kjørefelttype', 
#impute temp
impute_cols = trafikkulykke[['Ulykkes id', 'Antall kjørefelt', 'Fartsgrense', 'Temperatur']]
temp_impute = SimpleImputer(strategy = 'median')
temp_impute.fit(impute_cols)
temp_impute = temp_impute.transform(impute_cols) #fill missing values
features_column_names = list(impute_cols)
df_filled = pd.DataFrame(temp_impute, columns=features_column_names)

#merge prepped columns into df
trafikkulykker_merge = pd.merge(trafikkulykke, df_filled, how='left', on='Ulykkes id')

#%% choosing features as X and label as y

features = ['Ukedag','Uhell kategori', 'Antall kjørefelt_y', 'Fartsgrense_y', 'Temperatur_y', 'road_km', 'time_min', 'distance']
x = trafikkulykker_merge[features]
y = trafikkulykke[['alvorlig_ulykke']]


#%% split dataset

X_train, X_test, y_train, y_test = train_test_split(x, y, test_size=0.2, random_state=42)


#%%

# random forest for feature importance on a classification problem
from sklearn.datasets import make_classification
from sklearn.ensemble import RandomForestClassifier
from matplotlib import pyplot
from sklearn import metrics

# define dataset
X_train, y_train = make_classification(n_samples=1000, n_features=8, n_informative=4, n_redundant=3, random_state=1)
# define the model
model = RandomForestClassifier(max_depth=4, n_estimators=100)
# fit the model
model.fit(X_train, y_train)
y_pred = model.predict(X_test)

print('Score: ', model.score(X_train, y_train)) #0.947
y_test = y_test.astype('int')
print('Score: ', model.score(X_test, y_test)) #0.8522239563012095 beste score med 5 i depth

#importance and visual from datacamp
import pandas as pd
feature_imp = pd.Series(model.feature_importances_,index=features).sort_values(ascending=False)
feature_imp

import matplotlib.pyplot as plt
import seaborn as sns

# Creating a bar plot
sns.barplot(x=feature_imp, y=feature_imp.index)
# Add labels to the graph
plt.xlabel('Feature Importance Score')
plt.ylabel('Features')
plt.title("Visualizing Important Features")
plt.legend()
plt.show()
