import os

import swifter
import numpy as np
import pandas as pd
import xarray as xr
import geopandas as gpd

from shapely.geometry import Polygon


def validate_year(x: int) -> int:
    """Return a year integer in YYYY format if the input format is correct.

    :param x:                           Target year in YYYY format.
    :type x:                            int

    :return:                            Integer year in YYYY format.

    """

    if x is not None:

        # convert string to int if possible
        try:
            x = int(x)
        except ValueError:
            raise ValueError(f"Value for 'target_year' must be a 4-digit integer in YYYY format instead of '{x}'")

        # check year span
        thousands_place = x // 1000

        message = f"Value for 'target_year' must be greater than year 1000 and less than year 10000. Passed value: '{x}'"

        if thousands_place == 0:
            raise AssertionError(message)
        elif thousands_place >= 10:
            raise AssertionError(message)

        return x

    else:
        raise AssertionError("Must provide a 'target_year' value if writing to file.")


def validate_string(x: str = None) -> str:
    """Return a string that is all lower case and hyphen separated with no periods.  Ensure value is not None.

    :param x:                           Target string.
    :type x:                            str

    :return:                            Formatted string.

    """

    if x is not None:
        return x.strip().casefold().replace('.', '').replace(' ', '-')
    else:
        raise AssertionError("Must provide a 'scenario' value if writing to file.")


def validate_weights_file(weights_file: str = None, set_county_id_name: str = 'FIPS') -> pd.DataFrame:
    """Ensure weights file exists and has the required fields and return it as a DataFrame.

    :param weights_file:                Full path with file name and extension to the input weights file.
    :type weights_file:                 str

    :param set_county_id_name:          Field name of the unique county identifier
    :type set_county_id_name:           str

    :return:                            pd.DataFrame

    """

    required_columns = [set_county_id_name, 'weight', 'cell_index']
    data_types = {set_county_id_name: str, 'weight': float, 'cell_index': int}

    # ensure file exists
    if os.path.isfile(weights_file):
        df = pd.read_csv(weights_file, dtype=data_types)

        # ensure required columns exists
        missing = set(required_columns) - set(df.columns)

        if len(missing) > 0:
            raise AssertionError(f"'weights_file' is missing the following required columns:  {missing}")

        # ensure file has data other than column names
        if df.shape[0] == 0:
            raise AssertionError(f"'weights_file' has a header and no data.")

        return df

    else:
        raise FileNotFoundError(f"The 'weights_file' passed does not exist:  '{weights_file}'")


def build_polygon_from_centroid(x: float,
                                y: float,
                                x_resolution: float,
                                y_resolution: float) -> Polygon:
    """Construct a bounding polygon from a centroid.

    :param x:                   x coordinate value (longitude).
    :type x:                    float

    :param y:                   y coordinate value (latitude).
    :type y:                    float

    :param x_resolution:        Resolution along the x-axis.
    :type x_resolution:         float

    :param y_resolution:        Resolution along the y-axis.
    :type y_resolution:         float

    :return:                    Polygon geometry object

    """

    # get half distance along each axis
    x_half_resolution = x_resolution / 2
    y_half_resolution = y_resolution / 2

    # construct bounds
    xmin = x - x_half_resolution
    xmax = x + x_half_resolution
    ymin = y - y_half_resolution
    ymax = y + y_half_resolution
    bounds = ((xmin, ymin), (xmax, ymin), (xmax, ymax), (xmin, ymax), (xmin, ymin))

    # construct a Polygon object
    return Polygon(bounds)


def population_to_tell_counties(raster_file: str,
                                county_shapefile: str,
                                state_name: str = None,
                                scenario: str = None,
                                output_directory: str = None,
                                data_field_name: str = 'n_population',
                                x_coordinate_field: str = 'x',
                                y_coordinate_field: str = 'y',
                                drop_nan: bool = True,
                                county_id_field: str = 'GEOID',
                                set_county_id_name: str = 'FIPS',
                                weights_file: str = None,
                                target_year: int = None) -> pd.DataFrame:
    """Sum gridded population data by its spatially corresponding counties using a weighted area approach.  Each grid
    cell population value gets adjusted using the fraction of its area that is contained within a county.

    :param raster_file:                 Full path with file name and extension to the input raster file.
    :type raster_file:                  str

    :param county_shapefile:            Full path with file name and extension to the input counties shapefile.
    :type county_shapefile:             str

    :param state_name:                  Name of state to write into output file name.  Only required if writing output
                                        file.
    :type state_name:                   str

    :param scenario:                    Name of scenario to write into output file name. Only required if writing output
                                        file.
    :type scenario:                     str

    :param output_directory:            Full path to the target output directory where files will be written.  If None,
                                        an output file will not be generated.
    :type output_directory:             str

    :param data_field_name:             Field name to set as the value field for the raster data.
    :type data_field_name:              str

    :param x_coordinate_field:          Field name of the x (longitude) coordinate value.
    :type x_coordinate_field:           str

    :param y_coordinate_field:          Field name of the y (latitude) coordinate value.
    :type y_coordinate_field:           str

    :param drop_nan:                    Choice to drop all records that have a NaN (nodata in the raster) value.  If
                                        True, all NaN records will be removed; else if False, all records will be used.
    :type drop_nan:                     bool

    :param county_id_field:             Field name of the ID field present in the counties shapefile.  This field will
                                        get renamed to the value of 'set_county_id_name'.
    :type county_id_field:              str

    :param set_county_id_name:          Field name to change the 'county_id_field' name to.
    :type set_county_id_name:           str

    :param weights_file:                Full path with file name and extension to an inputs file containing the
                                        grid cell id (cell_index), the counties unique field name
                                        (what 'set_county_id_name' was set to), and the weight ('weight).  If given,
                                        this file will be used instead of running a new intersection.
    :type weights_file:                 str

    :param target_year:                 The year to process in YYYY format.
    :type target_year:                  int

    :return:                            A Pandas DataFrame of population data aggregated by the 'set_county_id_name'
                                        having fields and types of: {county_id_field: str, data_field_name: float}

    """

    # raster to DataArray
    da_raster = xr.open_rasterio(raster_file)

    # convert to DataFrame and give data field name
    df_raster = da_raster.to_dataframe(name=data_field_name)
    df_raster.reset_index(inplace=True)

    # set nodata value from raster as NaN
    df_raster[data_field_name] = np.where(df_raster[data_field_name] == da_raster.nodatavals[0],
                                          np.nan,
                                          df_raster[data_field_name])

    # drop 'band' field since raster will be single band
    df_raster.drop(columns='band', inplace=True)

    # drop all NaN data if desired
    if drop_nan:
        df_raster = df_raster.loc[~df_raster[data_field_name].isnull()].copy()

    # [PARALLEL] generate a Polygon object for each centroid
    df_raster['geometry'] = df_raster.swifter.apply(lambda xdf: build_polygon_from_centroid(
                                                                    x=xdf[x_coordinate_field],
                                                                    y=xdf[y_coordinate_field],
                                                                    x_resolution=da_raster.res[1],
                                                                    y_resolution=da_raster.res[0]), axis=1)

    # drop coordinate columns
    df_raster.drop(columns=[x_coordinate_field, y_coordinate_field], inplace=True)

    # convert to GeoDataFrame and set the coordinate system to that of the input raster
    gdf_raster = gpd.GeoDataFrame(df_raster, geometry='geometry').set_crs(da_raster.crs)

    # assign grid cell index
    gdf_raster['cell_index'] = gdf_raster.index.values

    # read in county polygon data
    counties = gpd.read_file(county_shapefile)

    # ensure field exists
    if county_id_field in counties.columns:
        counties = counties[[county_id_field, 'geometry']].rename(
            columns={county_id_field: set_county_id_name}
        ).to_crs(da_raster.crs)

    else:
        raise KeyError(f"There is not a field named '{county_id_field}' in the input county data.")

    # if using a preexisting weights file
    if weights_file:

        # validate weights file and return as a DataFrame
        gdf_intersect = validate_weights_file(weights_file, set_county_id_name)

        # join population gridded values
        gdf_intersect = pd.merge(left=gdf_intersect,
                                 right=gdf_raster,
                                 on='cell_index')

    else:

        # intersect the counties data and the raster polygonized data
        gdf_intersect = gpd.overlay(counties, gdf_raster, how='intersection')

        # calculate the weighted area
        gdf_intersect['area'] = gdf_intersect.area
        gdf_intersect['weight'] = gdf_intersect['area'] / (da_raster.res[0] * da_raster.res[1])

    # update original value with weighted value
    gdf_intersect[data_field_name] = gdf_intersect[data_field_name] * gdf_intersect['weight']

    # sum by unique field for counties
    df_county_sum = gdf_intersect[[set_county_id_name, data_field_name]].groupby(set_county_id_name).sum()
    df_county_sum.reset_index(inplace=True)

    # write output file if desired
    if output_directory is not None:

        # ensure output directory exists
        if os.path.isdir(output_directory):

            # write a weights file if one was not passed in
            if weights_file is None:
                weights_file = os.path.join(output_directory, f'{state_name}_population_to_county_area_weights.csv')
                target_fields = ['cell_index', set_county_id_name, 'weight']
                gdf_intersect[target_fields].to_csv(weights_file, index=False)

            # make state name and scenario lower case and hyphen separated with no periods
            state_name = validate_string(state_name)
            scenario = validate_string(scenario)
            target_year = validate_year(target_year)

            output_file = os.path.join(output_directory, f'{scenario}_{state_name}_{target_year}_county_population.csv')

            df_county_sum.to_csv(output_file, index=False)

        else:
            raise NotADirectoryError(f"Argument 'output_directory' setting '{output_directory}' is not a directory.")

    return df_county_sum
