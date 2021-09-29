import argparse
import datetime
import geopandas as gpd
from joblib import Parallel, delayed
from os.path import isfile, join
import pandas as pd
import salem
from typing import List


def compute_county_weighted_mean(
        df: pd.DataFrame,
        columns: List[str],
        precisions: List[int],
        normalized_weights_key: str = 'weight',
        county_fips_key: str = 'FIPS',
):
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


def write_output_file(df: pd.DataFrame, t: pd.Timestamp, output_path: str):
    name = join(output_path, f'{t.strftime("%Y_%m_%d_%H_UTC")}_County_Mean_Meteorology.csv')
    df.to_csv(name, index=False)


def process_time_slice(
        df: pd.DataFrame,
        wrf_variables: List[str],
        precisions: List[int],
        mapping: pd.DataFrame,
        output_path: str,
):
    write_output_file(
        compute_county_weighted_mean(
            mapping.merge(df, how='left', left_on='cell_index', right_index=True),
            wrf_variables,
            precisions,
        ),
        df.time.iloc[0],
        output_path,
    )


def wrf_to_tell_counties(
        wrf_file: str,
        wrf_variables: List[str],
        precisions: List[int],
        county_shapefile: str = './Geolocation/tl_2020_us_county/tl_2020_us_county.shp',
        weight_and_mapping_file: str = './grid_cell_to_county_weight.parquet',
        output_path: str = './County_Output_Files',
        n_jobs: int = 1,
) -> None:
    """
    Aggregate WRF output data to county level using area weighted average.

    :param str wrf_file: path to the WRF output file to aggregate
    :param list(str) wrf_variables: list of variables to aggregate
    :param list(int) precisions: list of precisions corresponding to the variables to aggregate
    :param str county_shapefile: path to a shapefile (.shp) with county geometries
    :param str weight_and_mapping_file: path to read or write a weights file which maps WRF grid cell to county weight
    :param str output_path: path to which output should be written
    :param n_jobs: number of time slices to process in parallel
    """

    begin_time = datetime.datetime.now()

    if not isfile(wrf_file):
        print('No file to process, exiting...')
        exit()

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
        intersection = gpd.overlay(counties, wrf_df, how='intersection')
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
            output_path,
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
            output_path,
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
        '--output-path',
        type=str,
        help='path to which output should be written',
        required=True,
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
        output_path=args.output_path,
        n_jobs=args.number_of_tasks,
    )
