import argparse
import datetime
from os.path import isfile, join
from typing import List

import geopandas as gpd
from joblib import Parallel, delayed
import pandas as pd
import salem


def compute_county_weighted_mean(
        df: pd.DataFrame,
        columns: List[str],
        precisions: List[int],
        normalized_weights_key: str = 'weight',
        county_fips_key: str = 'FIPS',
) -> pd.DataFrame:
    """
    Compute the weighted mean for specific columns of a dataframe, aggregated by county FIPS code.

    :rtype: pandas.DataFrame
    :param pandas.DataFrame df: DataFrame for which to compute weighted means
    :param list(str) columns: columns within the DataFrame for which to compute weighted means
    :param list(int) precisions: precisions to retain for the means, corresponding to the columns
    :param str normalized_weights_key: column name within the DataFrame representing the weights
    :param str county_fips_key: column name within the DataFrame representing the county FIPS code
    :return: a new DataFrame containing the weighted means column aggregated to by county FIPS code
    """
    return df[columns].multiply(
        df[normalized_weights_key],
        axis='index'
    ).join(
        df[[county_fips_key]]
    ).groupby(
        county_fips_key, as_index=False
    ).sum().astype({
        county_fips_key: int,
    }).round({
        key: precisions[i] for i, key in enumerate(columns)
    })


def write_output_file(
        df: pd.DataFrame,
        t: pd.Timestamp,
        output_directory: str,
        filename_suffix: str,
) -> None:
    """
    Write a dataframe to file, using a timestamp to generate a file name.

    :param pandas.DataFrame df: DataFrame to write to file
    :param pandas.Timestamp t: Timestamp that will be used to create the file name
    :param str output_directory: path to a directory to which to write the output file
    :param str filename_suffix: string to append to the timestamp for the output file name
    """
    name = join(output_directory, f'{t.strftime("%Y_%m_%d_%H_UTC")}{filename_suffix}.csv')
    df.to_csv(name, index=False)


def process_time_slice(
        df: pd.DataFrame,
        wrf_variables: List[str],
        precisions: List[int],
        mapping: pd.DataFrame,
        output_path: str,
        filename_suffix: str,
) -> None:
    """
    Calculate the county weighted mean for a single time slice of WRF output data.

    :param pandas.DataFrame df: DataFrame containing data for a single time slice
    :param list(str) wrf_variables: list of columns in the DataFrame for which to calculate mean by county
    :param list(int) precisions: list of precisions corresponding to the columns
    :param pandas.DataFrame mapping: DataFrame containing the mapping of df index to county and weight
    :param str output_path: path to which to write the output aggregation
    :param str filename_suffix: string to append to the timestamp for the output file name
    """
    write_output_file(
        compute_county_weighted_mean(
            mapping.merge(df, how='left', left_on='cell_index', right_index=True),
            wrf_variables,
            precisions,
        ),
        df.time.iloc[0],
        output_path,
        filename_suffix,
    )


def wrf_to_tell_counties(
        wrf_file: str,
        wrf_variables: List[str],
        precisions: List[int],
        county_shapefile: str = './Geolocation/tl_2020_us_county/tl_2020_us_county.shp',
        weight_and_mapping_file: str = './grid_cell_to_county_weight.parquet',
        output_directory: str = './County_Output_Files',
        output_filename_suffix: str = '_County_Mean_Meteorology',
        n_jobs: int = -1,
) -> None:
    """
    Aggregate WRF output data to county level using area weighted average.

    :param str wrf_file: path to the WRF output file to aggregate
    :param list(str) wrf_variables: list of variables to aggregate
    :param list(int) precisions: list of precisions corresponding to the variables to aggregate
    :param str county_shapefile: path to a shapefile (.shp) with county geometries
    :param str weight_and_mapping_file: path to read or write a weights file which maps WRF grid cell to county weight
    :param str output_directory: path to which output should be written
    :param str output_filename_suffix: string to append to the timestamp for the output file name
    :param int n_jobs: number of time slices to process in parallel
    """

    begin_time = datetime.datetime.now()

    if not isfile(wrf_file):
        raise FileNotFoundError('No file to process, exiting...')

    wrf = salem.open_wrf_dataset(wrf_file)

    # if there's not already a mapping file, create one
    if not isfile(weight_and_mapping_file):

        # using the first file and time:
        # * get the crs
        # * create the mapping of cell index to county and weight
        wrf_crs = wrf.pyproj_srs
        wrf_df = wrf[wrf_variables].isel(time=0).to_dataframe().reset_index(drop=True)
        wrf_df = gpd.GeoDataFrame(wrf_df, geometry=wrf.salem.grid.to_geometry().geometry).set_crs(wrf_crs)
        wrf_df['cell_index'] = wrf_df.index.values

        # load the counties and reproject to WRF projection
        counties = gpd.read_file(county_shapefile)[["GEOID", "geometry"]].rename(columns={
            'GEOID': 'FIPS',
        }).to_crs(wrf_crs)

        # find the intersection between counties and wrf cells
        try:
            intersection = gpd.overlay(counties, wrf_df, how='intersection')
        except ValueError as e:
            raise ValueError(f'''
                The intersection of county geometry and WRF grid cells resulted in invalid geometry.
                Please double check the geometry.
                
                {str(e)}
            ''')
        # weight by the intersection area
        intersection['area'] = intersection.area
        intersection['weight'] = (
            intersection['area'] / intersection[['FIPS', 'area']].groupby('FIPS').area.transform('sum')
        )

        # reuse this mapping for the remaining files and slices
        mapping = intersection[['cell_index', 'FIPS', 'weight']]
        mapping.to_parquet(weight_and_mapping_file)
        # create the first output file
        write_output_file(
            compute_county_weighted_mean(
                intersection,
                wrf_variables,
                precisions,
            ),
            wrf_df.time.iloc[0],
            output_directory,
            output_filename_suffix,
        )
        t_start = 1

    else:
        mapping = pd.read_parquet(weight_and_mapping_file)
        t_start = 0

    # create the remaining output for each time slice in each file
    Parallel(n_jobs=n_jobs)(
        delayed(process_time_slice)(
            wrf[wrf_variables].isel(time=i).to_dataframe().reset_index(drop=True),
            wrf_variables,
            precisions,
            mapping,
            output_directory,
            output_filename_suffix,
        ) for i in range(wrf.time.shape[0])[t_start:]
    )

    print('Elapsed time = ', datetime.datetime.now() - begin_time)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        description='Read in a WRF output file and generate county level aggregations per time slice.'
    )
    parser.add_argument(
        'file',
        metavar='/path/to/WRF/output/file',
        type=str,
        help='path to the WRF output file to aggregate',
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
        '-s',
        '--shapefile-path',
        type=str,
        help='path to a shapefile (.shp) with county geometries',
        required=True,
    )
    parser.add_argument(
        '-w',
        '--weights-file-path',
        type=str,
        help='path to the weights file mapping grid cell to county and weight; will be created if it does not exist',
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
        '--output-filename-suffix',
        type=str,
        help='string to append to the timestamp for the output file name',
        default='_County_Mean_Meteorology'
    )
    parser.add_argument(
        '-n',
        '--number-of-tasks',
        type=int,
        help='number of time slices to process in parallel',
        default=-1
    )
    args = parser.parse_args()
    wrf_to_tell_counties(
        wrf_file=args.file,
        wrf_variables=args.variables,
        precisions=args.precisions,
        county_shapefile=args.shapefile_path,
        weight_and_mapping_file=args.weights_file_path,
        output_directory=args.output_directory,
        output_filename_suffix=args.output_filename_suffix,
        n_jobs=args.number_of_tasks,
    )
