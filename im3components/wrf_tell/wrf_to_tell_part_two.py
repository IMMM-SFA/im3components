# wrf_to_tell_part_two.py
# Casey D. Burleyson
# Pacific Northwest National Laboratory
# 27-Aug 2021

# This script takes the .csv files of average WRF meteorology by county produced by
# wrf_to_tell_part_one.py and aggregates them into annual hourly time-series of
# population-weighted meteorology for each balancing authority (BA). This is the
# second step in a processing chain to go from the WRF output files to the input
# files needed for TELL. All times are in UTC. Missing values are reported as -9999.

# Import all of the required libraries and packages:
import glob
import numpy as np
import pandas as pd
import os
import datetime
from datetime import datetime as dt
import re

# Set a time variable to benchmark the run time:
begin_time = datetime.datetime.now()

# Set the data input and output directories:
data_input_dir = '/Users/burl878/OneDrive - PNNL/Documents/IMMM/Data/TELL_Input_Data/forward_execution/Climate_Forcing/County_Output_Files/'
data_output_dir = '/Users/burl878/OneDrive - PNNL/Documents/IMMM/Data/TELL_Input_Data/forward_execution/Climate_Forcing/BA_Output_Files/'
ba_geolocation_input_dir = '/Users/burl878/OneDrive - PNNL/Documents/IMMM/Data/TELL_Input_Data/inputs/Utility_Mapping/CSV_Files/'
population_input_dir = '/Users/burl878/OneDrive - PNNL/Documents/IMMM/Data/TELL_Input_Data/inputs/'

# Set the year to process:
year_to_process = '2019';

# Create a list of all of the WRF output files in the "data_input_dir":
list_of_files = sorted(glob.glob(os.path.join(data_input_dir + year_to_process + '*_County_Mean_Meteorology.csv')))

# Load in the BA service territory map and simplify the data frame:
ba_service_territory_filename = ba_geolocation_input_dir + 'fips_service_match_' + year_to_process + '.csv'
col_names = ['county_fips','county_name','ba_number','ba_abbreviation']
ba_mapping = pd.read_csv(ba_service_territory_filename,index_col=None,header=0)
ba_mapping = ba_mapping[col_names].copy(deep=False)
ba_mapping.rename(columns={"county_fips":"County_FIPS",
                           "county_name":"County_Name",
                           "ba_number":"BA_Number",
                           "ba_abbreviation":"BA_Code"},inplace=True)
ba_mapping = ba_mapping.sort_values("BA_Number")
ba_mapping = ba_mapping.drop_duplicates()
del col_names,ba_service_territory_filename

# Load in the population data and simplify the data frame:
population = pd.read_csv(population_input_dir + '/county_populations_2000_to_2019.csv')
col_names = ['county_FIPS','pop_'+year_to_process]
population = population[col_names].copy(deep=False)
population.rename(columns={"county_FIPS":"County_FIPS",
                           "pop_"+year_to_process:"Population"},inplace=True)
del col_names

# Merge the ba_mapping and population data frames together:
mapping_df = ba_mapping.merge(population, on=['County_FIPS'])
mapping_df = mapping_df.sort_values("BA_Number")
mapping_df['Population_Sum'] = mapping_df.groupby('BA_Code')['Population'].transform('sum')
mapping_df['Population_Fraction'] = mapping_df['Population'] / mapping_df['Population_Sum']
mapping_df = mapping_df.dropna()
del population,ba_mapping

# Initialize a set of empty pandas data frames:
Time = pd.DataFrame()
T2 = pd.DataFrame()
Q2 = pd.DataFrame()
WSPD = pd.DataFrame()
SWDOWN = pd.DataFrame()
GLW = pd.DataFrame()

# Loop over all the files in the list and extract then concatenate the meteorological variables:
for file in range(len(list_of_files)):
    # Read in the .csv file and replace missing values with nan:
    wrf_data = pd.read_csv(list_of_files[file]).replace(-9999,np.nan)

    # Drop all the rows with data outside of the 50 states:
    wrf_data = wrf_data[wrf_data.County_FIPS <= 56045]

    # Pull out a vector of the County_FIPS variable for use in subsequent subsetting:
    if file == 0:
       met_variable_mapping = pd.DataFrame(wrf_data['County_FIPS'].copy())

    # Extract the time string from the .csv filename:
    match = re.search(r"((\d+)_(\d+)_(\d+)_(\d+))",list_of_files[file])
    Time[file] = pd.DataFrame({'Date':[str(dt.strptime(match.group(1),'%Y_%m_%d_%H'))]})

    # Extract the meteorological variables and concatenate them into new dataframes:
    T2[file] = wrf_data['Mean_T2']
    Q2[file] = wrf_data['Mean_Q2']
    SWDOWN[file] = wrf_data['Mean_SWDOWN']
    GLW[file] = wrf_data['Mean_GLW']
    # Compute the total wind speed based on the U10 and V10 variables:
    WSPD[file] = ((wrf_data['Mean_U10']**2) + (wrf_data['Mean_V10']**2))**(1/2)

    # Clean up the mess and move on to the next file in the list:
    del wrf_data,match

# Make a list of the unique BAs in mapping_df:
unique_bas = mapping_df.BA_Number.unique()
unique_bas = unique_bas[unique_bas != 14725] # Remove PJM because it's throwing a weird matrix size error
unique_bas = unique_bas[unique_bas != 28503] # Remove WACM because it's throwing a weird matrix size error
unique_bas = unique_bas[unique_bas != 59504] # Remove SWPP because it's throwing a weird matrix size error

# Loop over the list of unique BAs and compute the population-weighted meteorology time-series:
for ba in range(len(unique_bas)):
    # Initialize an empty dataframe to store the results:
    output_df = pd.DataFrame()

    # Subset the mapping_df dataframe to only the counties in the given BA:
    mapping_df_subset = mapping_df[mapping_df['BA_Number'].isin([unique_bas[ba]])]

    # Find the indices of all the counties in the WRF dataset associated with that BA:
    matched_counties = met_variable_mapping['County_FIPS'].isin(mapping_df_subset['County_FIPS'])

    # Subset each of the WRF variables to only those counties: TO-DO - Make this a function
    T2_Subset = T2.loc[matched_counties]
    Q2_Subset = Q2.loc[matched_counties]
    WSPD_Subset = WSPD.loc[matched_counties]
    SWDOWN_Subset = SWDOWN.loc[matched_counties]
    GLW_Subset = GLW.loc[matched_counties]

    # Copy the time variable to the output dataframe:
    output_df['Time'] = Time.copy().transpose()

    # Multiply the WRF variable by the population fraction for that county, sum over the rows, and round off the results:
    output_df['Mean_T2'] = T2_Subset.mul(mapping_df_subset['Population_Fraction'].values,axis=0).sum().round(2)
    output_df['Mean_Q2'] = Q2_Subset.mul(mapping_df_subset['Population_Fraction'].values,axis=0).sum().round(5)
    output_df['Mean_WSPD'] = WSPD_Subset.mul(mapping_df_subset['Population_Fraction'].values,axis=0).sum().round(2)
    output_df['Mean_SWDOWN'] = SWDOWN_Subset.mul(mapping_df_subset['Population_Fraction'].values, axis=0).sum().round(2)
    output_df['Mean_GLW'] = GLW_Subset.mul(mapping_df_subset['Population_Fraction'].values, axis=0).sum().round(2)

    # Generate the name of the output file:
    output_filename =  mapping_df_subset['BA_Code'].iloc[0] + "_WRF_Hourly_Meteorology_Data_" +  year_to_process + ".csv"
    output_file = os.path.join(data_output_dir,output_filename)

    # Replace missing values and write the output dataframe to a .csv file:
    output_df = output_df.fillna(-9999)
    output_df.to_csv(output_file,sep=',',index=False)

    # Clean up some variables and move to the next BA in the loop:
    del T2_Subset,Q2_Subset,WSPD_Subset,SWDOWN_Subset,GLW_Subset,output_filename,output_file,mapping_df_subset,output_df,matched_counties

# Output the elapsed time in order to benchmark the run time:
print('Elapsed time = ',datetime.datetime.now() - begin_time)

# Clean up some junk variables because I'm OCD:
del ba,ba_geolocation_input_dir,file,begin_time,mapping_df,met_variable_mapping,population_input_dir,unique_bas