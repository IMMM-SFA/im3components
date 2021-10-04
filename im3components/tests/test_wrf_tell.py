import os
import numpy as np
import pandas as pd
import unittest

import pandas as pd

import im3components as cmp


class TestWrfTell(unittest.TestCase):
    """Tests for the WRF to TELL county mean aggregations"""

    def test_county_aggregation(self):
        """Ensure that a single time slice and county produces the same result."""

        data_path = f'{os.path.dirname(os.path.abspath(__file__))}/wrf_tell_data'

        registry = cmp.registry()
        wrf_to_tell_counties = registry.get_function(registry.list_related('tell')[0])

        # remove weights file if it exists
        try:
            os.remove(f'{data_path}/test_weights.parquet')
        except OSError:
            pass

        # remove output files if they exist
        try:
            os.remove(f'{data_path}/2019_01_01_01_UTC_County_Mean_Meteorology.csv')
        except OSError:
            pass
        try:
            os.remove(f'{data_path}/2019_01_01_02_UTC_County_Mean_Meteorology.csv')
        except OSError:
            pass

        # generate the weights and output files
        wrf_to_tell_counties(
            wrf_file=f'{data_path}/test_data.nc',
            wrf_variables=['T2', 'Q2', 'U10', 'V10', 'SWDOWN', 'GLW'],
            precisions=[2, 5, 2, 2, 2, 2],
            county_shapefile=f'{data_path}/test_counties.shp',
            weight_and_mapping_file=f'{data_path}/test_weights.parquet',
            output_directory=data_path,
            output_filename_suffix='_County_Mean_Meteorology',
            n_jobs=-1,
        )

        # load the output files and check results
        slice_one = pd.read_csv(f'{data_path}/2019_01_01_01_UTC_County_Mean_Meteorology.csv')
        slice_two = pd.read_csv(f'{data_path}/2019_01_01_02_UTC_County_Mean_Meteorology.csv')

        validation_data = pd.DataFrame({
            'FIPS': np.array([1001, 1001], dtype=int),
            'T2': np.array([293.03, 293.12], dtype=float),
            'Q2': np.array([0.01315, 0.01344], dtype=float),
            'U10': np.array([-0.46, 0.81], dtype=float),
            'V10': np.array([7.81, 7.06], dtype=float),
            'SWDOWN': np.array([0.0, 0.0], dtype=float),
            'GLW': np.array([411.66, 411.7], dtype=float),
        })

        pd.testing.assert_frame_equal(validation_data, pd.concat([slice_one, slice_two], ignore_index=True))
