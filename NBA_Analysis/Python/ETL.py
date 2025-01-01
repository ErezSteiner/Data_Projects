import pandas as pd
import os

#raw csvs can be downloaded here https://github.com/DomSamangy/NBA_Shots_04_24/tree/main
folder_path = r'Data_Projects\NBA_Analysis\Data'
folder_list = os.listdir(folder_path)

raw_dataframes = {}
for file in folder_list:
    year = file.split('_')[1]#getting the year to use it as the name for the df
    raw_dataframes[year] = pd.read_csv(folder_path + '\\' + file)


#fixing the date format
for year,df in raw_dataframes.items():
    raw_dataframes[year].GAME_DATE = pd.to_datetime(raw_dataframes[year]['GAME_DATE'], dayfirst=False)


#data should be sorted by the date, then by GameID, then by teamID and then by playerID
for year, df in raw_dataframes.items():
   raw_dataframes[year].sort_values(['GAME_DATE', 'GAME_ID', 'TEAM_ID', 'PLAYER_ID'], inplace = True)


#now that the data is sorted I can combine all the DFs into one
complete_dataframe = pd.concat(list(raw_dataframes.values()), axis=0).reset_index(drop=True)

#saving the data as a pickle
file_name = 'full_data_pickle.pkl'
complete_dataframe.to_pickle(folder_path + '\\' + file_name)
