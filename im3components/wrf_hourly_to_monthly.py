import os
from itertools import compress
import pandas as pd
import netCDF4
import warnings
import xarray

"""wrf_hourly_to_monthly

    Script to process WRF data to monthly mean values
    License:  BSD 2-Clause, see LICENSE and DISCLAIMER files

"""


def wrf_hourly_to_monthly(
        wrf_files,
        wrf_params=['RAINC', 'SNOWC'],
        aggregation_method=['sum'],
        out_dir='output',
        save='True'):
    """Convert WRF data to monthly mean values

    :param wrf_files:              list of full paths to wrf files to convert.
    :type wrf_files:               list

    :param wrf_params:             list of param names from the WRF netcdf files to process. Default = ['RAINC',SNOWC']
    :type wrf_params:              list

    :param out_dir:                name of folder to save outputs to. Default is 'output' in the working dir.
    :type out_dir:                 str

    :param aggregation_method:     Aggregation method for each parameter or a single element if all the same. Either 'sum' or 'mean'.
    :type aggregation_method:      list

    :param save:                    Boolean to save outputs as .csv. Default = 'True'
    :type save:                     bool

    :return:                        Pandas data frame with data aggregated per month

    USAGE:
    from im3components import wrf_hourly_to_monthly
    wrf_files = ['full_path_to_wrf_file1', 'full_path_to_wrf_file2']
    out_dir = 'output_folder_name' OR 'full_path_to_output_folder_name'
    wrf_hourly_to_monthly(wrf_files, out_dir)

    """

    # Alternative using xarray
    # import xarray as xr
    # from datetime import datetime
    #ds = open_dataset('C:/Z/models/xanthosWRFData/wrfout_d01_2009-01-01_00-00-00.nc')
    ## Set time
    #start = datetime.strptime(ds.START_DATE,'%Y-%m-%d_%H:%M:%S')
    #date_range = pd.date_range(start, periods=len(ds['Time']), freq="H")
    ## Set time dimension
    #ds['Time'] = date_range
    #da = ds.resample(Time="M").mean()

    # Resampling Resolution
    import matplotlib.pyplot as plt
    import numpy as np
    from mpl_toolkits.basemap import Basemap
    nc = netCDF4.Dataset('C:/Z/models/xanthosWRFData/wrfout_d01_2009-01-01_00-00-00.nc')
    lat = nc.variables['latitude'][:]
    lon = nc.variables['longitude'][:]
    time = nc.variables['time'][:]
    t2 = nc.variables['p2t'][:]  # 2 meter temperature
    mslp = nc.variables['msl'][:]  # mean sea level pressure
    u = nc.variables['p10u'][:]  # 10m u-component of winds
    v = nc.variables['p10v'][:]  # 10m v-component of winds

    print("Starting wrf_hourly_to_monthly...")

    # Check if wrf_files exist
    wrf_files_exist_check = list(map(os.path.exists, wrf_files))
    wrf_files_dont_exist_check = [not elem for elem in wrf_files_exist_check]
    wrf_files_exist = list(compress(wrf_files, wrf_files_exist_check))
    wrf_files_dont_exist = list(compress(wrf_files, wrf_files_dont_exist_check))
    if not any(wrf_files_exist):
        print(f'None of the wrf_files provided exist: {wrf_files}')  # fstring
        print('Stopping wrf_hourly_to_monthly run.')
        raise FileNotFoundError()
    elif len(wrf_files_dont_exist) > 0:
        print(f'The following wrf_files provided do not exist. Skipping these: {wrf_files_dont_exist}')
        print(f'Running wrf_hourly_to_monthly for remaining files: {wrf_files_exist}')
    else:
        print(f'Running wrf_hourly_to_monthly for files provided: {wrf_files_exist}')

    # Check out_dir name and path
    if not os.path.exists(out_dir):
        if (out_dir.find('/') != -1) or (out_dir.find('/') != -1):
            print(f'Path provided for out_dir is not correct: {out_dir}')
            print(f'Using default output directory : {os.getcwd() + "/output"}')
            out_dir_path = os.getcwd() + "/output"
            os.mkdir(out_dir_path)
        else:
            print(f'Saving outputs to : {os.getcwd() + "/" + out_dir}')
            out_dir_path = os.getcwd() + "/" + out_dir
            os.mkdir(out_dir_path)
    else:
        out_dir_path = out_dir

    # Check aggregation method
    # If length aggregation_method == 1 then set the value for all params.
    if len(aggregation_method) == 1:
        aggregation_method = [aggregation_method[0]] * len(wrf_params)
    elif len(aggregation_method) != len(wrf_params):
        raise ValueError(
            f'length of aggregation_method ({len(aggregation_method)}) should be the same length as wrf_params ({len(wrf_params)})')

    df_combined = pd.DataFrame([])  # Empty data frame to hold data

    # For each wrf_file that exists
    for wrf_file_i in wrf_files_exist:
        print(f'Reading wrf_file: {wrf_file_i}')
        ds = netCDF4.Dataset(wrf_file_i)

        # Get year and month
        year_i = ds.START_DATE[0:4]
        month_i = ds.START_DATE[5:7]

        # Get Lat & Lon
        df_lat = pd.melt(pd.DataFrame(ds['XLAT'][0])).drop('variable', axis=1)
        df_lat.columns = ['lat']
        df_lon = pd.melt(pd.DataFrame(ds['XLONG'][0])).drop('variable', axis=1)
        df_lon.columns = ['lon']
        df_lat_lon = pd.concat([df_lat, df_lon], axis=1)

        # Get mean over all hours for each param
        count_i = 0
        for param_i in wrf_params:
            aggregation_method_i = aggregation_method[count_i]
            print(f'Aggregating param: {param_i} using aggregation_method: {aggregation_method_i}')
            count_i = count_i + 1
            ds_param = ds[param_i][:]
            if aggregation_method_i == 'sum':
                df_param_aggregated = pd.melt(pd.DataFrame(ds_param.sum(axis=0))).drop('variable', axis=1)
            else:
                df_param_aggregated = pd.melt(pd.DataFrame(ds_param.mean(axis=0))).drop('variable', axis=1)
            df_param_aggregated['param'] = param_i
            df_param_aggregated['year'] = year_i
            df_param_aggregated['month'] = month_i

            # Bind rows to combined pandas dataframe with lat and lon
            df_combined = df_combined.append(pd.concat([df_lat_lon, df_param_aggregated], axis=1))

    # Calculate the mean over each month
    df_comb_monthly_aggregated = df_combined.groupby(['lat', 'lon', 'year', 'month', 'param']).agg(
        {'value': 'mean'}).reset_index()

    # Save as csv files
    if save:
        for year_i in df_comb_monthly_aggregated.year.unique():
            for param_i in df_comb_monthly_aggregated.param.unique():
                fname = out_dir_path + '/monthly_aggregated_' + param_i + '_' + year_i + '.csv'
                df_comb_monthly_aggregated_i = df_comb_monthly_aggregated[
                    df_comb_monthly_aggregated['year'].str.contains(year_i)]
                df_comb_monthly_aggregated_i = df_comb_monthly_aggregated_i[
                    df_comb_monthly_aggregated['param'].str.contains(param_i)]
                df_comb_monthly_aggregated_i.to_csv(fname, index=False)
                print(f'Saved file: {fname}.')
                if os.path.exists(fname):
                    warnings.warn(f'The following file already exists and will be overwritten: {fname}.')

    # Close out
    print(f'Converted files saved to: {out_dir_path}')
    print("wrf_hourly_to_monthly completed.")

    return df_comb_monthly_aggregated
