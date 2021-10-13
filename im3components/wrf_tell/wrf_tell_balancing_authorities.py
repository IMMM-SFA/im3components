# wrf_tell_balancing_authorities.py
# Casey D. Burleyson
# Pacific Northwest National Laboratory
# 30-Sep 2021

# This script takes the .csv files of average WRF meteorology by county produced by
# wrf_to_tell_part_one.py and aggregates them into annual hourly time-series of
# population-weighted meteorology for each balancing authority (BA). This is the
# second step in a processing chain to go from the WRF output files to the input
# files needed for TELL. All times are in UTC. Missing values are reported as -9999.

# Import all of the required libraries and packages:
import argparse
import glob
import numpy as np
import pandas as pd
import os
import datetime
from typing import List


def wrf_to_tell_balancing_authorities(
    year: int,
    balancing_authority_to_fips_file: str,
    county_population_by_year_file: str,
    county_data_directory: str,
    output_directory: str,
    output_file_infix: str = 'WRF_Hourly_Mean_Meteorology',
    county_data_prefix: str = '',
    county_data_suffix: str = '_County_Mean_Meteorology.csv',
    county_data_time_format: str = '%Y_%m_%d_%H',
    variables: List[str] = None,
    precisions: List[int] = None,
):
    begin_time = datetime.datetime.now()

    if variables is None:
        variables = ['T2', 'Q2', 'U10', 'V10', 'SWDOWN', 'GLW']

    if precisions is None:
        precisions = [2, 5, 2, 2, 2, 2]

    # Read the BA to county mapping file
    ba_mapping_df = pd.read_csv(
        balancing_authority_to_fips_file,
        index_col=None,
        header=0,
    )[['county_fips', 'county_name', 'ba_number', 'ba_abbreviation']].rename(columns={
        'county_fips': 'County_FIPS',
        'county_name': 'County_Name',
        'ba_number': 'BA_Number',
        'ba_abbreviation': 'BA_Code',
    }).drop_duplicates()

    # Read the county population by year file
    population_df = pd.read_csv(
        county_population_by_year_file,
        index_col=None,
        header=0,
    )[['county_FIPS', f'pop_{year}']].rename(columns={
        'county_FIPS': 'County_FIPS',
        f'pop_{year}': 'Population',
    })

    # Merge by county
    ba_mapping_df = ba_mapping_df.merge(population_df, on='County_FIPS')
    # Calculate the total population within each BA:
    ba_mapping_df['Population_Sum'] = ba_mapping_df.groupby('BA_Code')['Population'].transform('sum')
    # Calculate the fraction of the BA's total population that lives in each county:
    ba_mapping_df['Population_Fraction'] = ba_mapping_df['Population'] / ba_mapping_df['Population_Sum']
    # Sort the data by BA number, drop duplicates and missing values, and return the dataframe:
    ba_mapping_df = ba_mapping_df.sort_values('BA_Number').dropna()

    # list of county data files for this year
    data_files = sorted(
        glob.glob(f'{county_data_directory}/{county_data_prefix}*{year}*{county_data_suffix}.csv'))

    # build county data dataframe - set the filename as a column but then parse the time out of it
    county_data = pd.concat(
        (pd.read_csv(f).assign(Time_UTC=os.path.basename(f)).rename(columns={'FIPS': 'County_FIPS'}) for f in data_files))
    county_data['Time_UTC'] = pd.to_datetime(county_data.Time_UTC, exact=False, format=county_data_time_format)

    if ('U10' in county_data) and ('V10' in county_data):
        # Compute the wind speed based on the U10 and V10 variables:
        county_data['WSPD'] = np.sqrt(np.square(county_data['U10']) + np.square(county_data['V10']))
        index_of_u10 = variables.index('U10')
        variables.pop(index_of_u10)
        precision = precisions.pop(index_of_u10)
        index_of_v10 = variables.index('V10')
        variables.pop(index_of_v10)
        precisions.pop(index_of_v10)
        variables.append('WSPD')
        precisions.append(precision)

    merged_df = ba_mapping_df.merge(county_data, how='inner', on='County_FIPS')

    # calculate the weighted means per BA per hour
    means = merged_df[variables].multiply(
        merged_df['Population_Fraction'],
        axis='index'
    ).join(
        merged_df[['BA_Number', 'Time_UTC']]
    ).groupby(
        ['BA_Number', 'Time_UTC']
    ).sum().round({
        key: precisions[i] for i, key in enumerate(variables)
    }).reset_index()

    # for each ba, write the output file
    for ba_number, group in means.groupby('BA_Number'):
        ba_name = ba_mapping_df[ba_mapping_df.BA_Number == ba_number]['BA_Code'].iloc[0]
        output_file = f'{output_directory}/{ba_name}_{output_file_infix}_{year}.csv'
        group[['Time_UTC'] + variables].to_csv(output_file, sep=',', index=False)

    print('Elapsed time = ', datetime.datetime.now() - begin_time)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        description='Read in a County output files and generate Balancing Authority level aggregations per time slice.'
    )
    parser.add_argument(
        'year',
        metavar='2021',
        type=int,
        help='year to process data for',
    )
    parser.add_argument(
        '-v',
        '--variables',
        nargs='+',
        type=str,
        default=['T2', 'Q2', 'U10', 'V10', 'SWDOWN', 'GLW'],
        help='list of variables to aggregate',
    )
    parser.add_argument(
        '-p',
        '--precisions',
        nargs='+',
        type=int,
        default=[2, 5, 2, 2, 2, 2],
        help='list of precisions for the variables to aggregate',
    )
    parser.add_argument(
        '-b',
        '--balancing-authority-to-county',
        type=str,
        help='path to .csv file that maps balancing authority to county FIPS',
        required=True,
    )
    parser.add_argument(
        '-c',
        '--county-population-by-year',
        type=str,
        help='path to .csv file containing county FIPS population per year',
        required=True,
    )
    parser.add_argument(
        '-d',
        '--county-mean-data-directory',
        type=str,
        help='path to directory containing mean county data',
        required=True,
    )
    parser.add_argument(
        '-o',
        '--output-directory',
        type=str,
        help='path to which output should be written',
        required=True,
    )
    parser.add_argument(
        '--output-file-infix',
        type=str,
        help='string to insert into the output file name',
        default='WRF_Hourly_Mean_Meteorology'
    )
    parser.add_argument(
        '--county-data-prefix',
        type=str,
        help='string appearing at the beginning of county mean file names',
        default=''
    )
    parser.add_argument(
        '--county-data-suffix',
        type=str,
        help='string appearing at the end of county mean file names',
        default='County_Mean_Meteorology'
    )
    parser.add_argument(
        '--county-data-time-format',
        type=str,
        help='time format as it appears in county mean file names',
        default='%Y_%m_%d_%H'
    )
    args = parser.parse_args()
    wrf_to_tell_balancing_authorities(
        year=args.year,
        balancing_authority_to_fips_file=args.balancing_authority_to_county,
        county_population_by_year_file=args.county_population_by_year,
        county_data_directory=args.county_mean_data_directory,
        output_directory=args.output_directory,
        output_file_infix=args.output_file_infix,
        county_data_prefix=args.county_data_prefix,
        county_data_suffix=args.county_data_suffix,
        county_data_time_format=args.county_data_time_format,
        variables=args.variables,
        precisions=args.precisions,
    )
