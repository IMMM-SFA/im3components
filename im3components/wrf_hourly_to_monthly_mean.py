import os
from itertools import compress
import pandas as pd
import numpy as np
import netCDF4

"""wrf_hourly_to_monthly_mean

    Script to process WRF data to monthly mean values
    License:  BSD 2-Clause, see LICENSE and DISCLAIMER files

"""


def wrf_hourly_to_monthly_mean(
        wrf_files,
        wrf_params = ['RAINC','SNOWC'],
        out_dir='output'):
    """Convert WRF data to monthly mean values

    :param wrf_files:             list of full paths to wrf files to convert.
    :type wrf_files:              list

    :param wrf_params:             list of param names from the WRF netcdf files to process. Default = ['RAINC',SNOWC']
    :type wrf_params:              list

    :param out_dir:               name of folder to save outputs to. Default is 'output' in the working dir.
    :type out_dir:                str

    :return:                      path to output directory

    USAGE:
    from im3components import wrf_hourly_to_monthly_mean
    wrf_files = ['full_path_to_wrf_file1', 'full_path_to_wrf_file2']
    out_dir = 'output_folder_name' OR 'full_path_to_output_folder_name'
    wrf_hourly_to_monthly_mean(wrf_files, out_dir)

    """

    print("Starting wrf_hourly_to_monthly_mean...")

    # Check if wrf_files exist
    wrf_files_exist_check = list(map(os.path.exists, wrf_files))
    wrf_files_dont_exist_check = [not elem for elem in wrf_files_exist_check]
    wrf_files_exist = list(compress(wrf_files, wrf_files_exist_check))
    wrf_files_dont_exist = list(compress(wrf_files, wrf_files_dont_exist_check))
    if not any(wrf_files_exist):
        print(f'None of the wrf_files provided exist: {wrf_files}')  # fstring
        print('Stopping wrf_hourly_to_monthly_mean run.')
        raise FileNotFoundError()
    elif len(wrf_files_dont_exist) > 0:
        print(f'The following wrf_files provided do not exist. Skipping these: {wrf_files_dont_exist}')
        print(f'Running wrf_hourly_to_monthly_mean for remaining files: {wrf_files_exist}')
    else:
        print(f'Running wrf_hourly_to_monthly_mean for files provided: {wrf_files_exist}')

    # Check out_dir name and path
    if not os.path.exists(out_dir):
        if ((out_dir.find('/') != -1) or (out_dir.find('/') != -1)):
            print(f'Path provided for out_dir is not correct: {out_dir}')
            print(f'Using default output directory : {os.getcwd() + "/output"}')
            out_dir_path = os.getcwd() + "/output"
        else:
            print(f'Saving outputs to : {os.getcwd() + "/" + out_dir}')
            out_dir_path = os.getcwd() + "/" + out_dir


    df_combined = pd.DataFrame([])

    # For each wrf_file that exists
    for wrf_file_i in wrf_files_exist:
        print(f'Reading wrf_file: {wrf_file_i}')
        ds = netCDF4.Dataset(wrf_file_i)

        # Get year and month
        year_i = ds.START_DATE[0:4]
        month_i = ds.START_DATE[5:7]

        # Get Lat & Lon
        df_lat = pd.melt(pd.DataFrame(ds['XLAT'][0])).drop('variable',axis=1)
        df_lat.columns = ['lat']
        df_lon = pd.melt(pd.DataFrame(ds['XLONG'][0])).drop('variable',axis=1)
        df_lon.columns = ['lon']
        df_lat_lon = pd.concat([df_lat,df_lon], axis=1)

        # Get mean over all hours for each param
        for param_i in wrf_params:
            print(f'Aggregating param: {param_i}')
            ds_param = ds[param_i][:]
            df_param_mean = pd.melt(pd.DataFrame(ds_param.mean(axis=0))).drop('variable',axis=1)
            df_param_mean['param'] = param_i
            df_param_mean['year'] = year_i
            df_param_mean['month'] = month_i

            # Bind rows to combined pandas dataframe with lat and lon
            df_combined = df_combined.append(pd.concat([df_lat_lon,df_param_mean], axis=1))

    # Calculate the mean over each month
    df_comb_monthly_mean = df_combined.groupby(['lat','lon','year','month','param']).agg({'value': 'mean'}).reset_index()

    # Close out
    print(f'Converted files saved to: {out_dir_path}')
    print("wrf_hourly_to_monthly_mean completed.")

    return df_comb_monthly_mean

# Process Mean Monthly Precipitation

# Process Mean Monthly Relative Humidity Percentage

# Process Mean Monthly Surface Downwelling LongWave Radiation

# Process Mean Monthly Surface Downwelling shortwave Radiation

# Process Mean monthly Daily mean Surface Air Temperature

# Process Mean Monthly Daily Minimum Surface Air Temperature

# Process Mean Monthly Wind Speed in m/s
