import urllib.request
import zipfile
import pandas as pd

url = 'https://www.ssa.gov/oact/babynames/names.zip'
temp_file, _ = urllib.request.urlretrieve(url)

frames = []
header = ['name', 'gender', 'births']
years = range(1880, 2022)

# open zipped TXT files into one dataset
with zipfile.ZipFile(temp_file) as z_file:
    for year in years:
        txt_file = z_file.open('yob{}.txt'.format(year))

        dframe = pd.read_csv(txt_file, names=header)
        
        # new column 'years'
        dframe['years'] = year

	# append each subframe to list
        frames.append(dframe)

# final dataframe from list            
df = pd.concat(frames, ignore_index=True)

# export data to CSV file for SQL Server Import Wizard
df.to_csv('names.csv', index=False)