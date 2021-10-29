import os
import numpy as np
import pandas as pd
import unittest

import im3components as cmp


class TestWrfTell(unittest.TestCase):
    """Tests for the WRF to TELL county mean aggregations"""

    COUNTY_COMPONENT_NAME = 'wrf_tell_counties'
    BA_COMPONENT_NAME = 'wrf_tell_balancing_authorities'

    def setUp(self):
        self.data_path = f'{os.path.dirname(os.path.abspath(__file__))}/wrf_tell_data'

    def test_balancing_authority_aggregation(self):
        """Ensure that counties to BAs aggregation produces the same result."""

        registry = cmp.registry()
        wrf_to_tell_balancing_authorities = registry.get_function(self.BA_COMPONENT_NAME)

        # remove output file if it exists
        try:
            os.remove(f'{self.data_path}/PSEI_WRF_Hourly_Mean_Meteorology_2019.csv')
        except OSError:
            pass

        # generate results
        wrf_to_tell_balancing_authorities(
            year=2019,
            balancing_authority_to_fips_file=f'{self.data_path}/fips_service_match_2019.csv',
            county_population_by_year_file=f'{self.data_path}/county_populations_2000_to_2019.csv',
            county_data_directory=f'{self.data_path}',
            output_directory=f'{self.data_path}',
            output_file_infix='WRF_Hourly_Mean_Meteorology',
            county_data_prefix='',
            county_data_suffix='county_test_data',
            county_data_time_format='%Y_%m_%d_%H',
            variables=['T2', 'Q2', 'U10', 'V10', 'SWDOWN', 'GLW'],
            precisions=[2, 5, 2, 2, 2, 2],
        )

        # load the output and check results
        data = pd.read_csv(f'{self.data_path}/PSEI_WRF_Hourly_Mean_Meteorology_2019.csv')

        validation_data = pd.DataFrame({
            'Time_UTC': np.array(['2019-01-01 01:00:00', '2019-01-01 02:00:00']),
            'T2': np.array([270.11, 269.43], dtype=float),
            'Q2': np.array([0.00242, 0.0023], dtype=float),
            'SWDOWN': np.array([0.0, 0.0], dtype=float),
            'GLW': np.array([218.16, 217.34], dtype=float),
            'WSPD': np.array([1.92, 2.34], dtype=float),
        })

        pd.testing.assert_frame_equal(validation_data, data)

    def test_county_aggregation(self):
        """Ensure that a single time slice and county produces the same result."""

        registry = cmp.registry()
        wrf_to_tell_counties = registry.get_function(self.COUNTY_COMPONENT_NAME)

        # remove weights file if it exists
        try:
            os.remove(f'{self.data_path}/test_weights.parquet')
        except OSError:
            pass

        # remove output files if they exist
        try:
            os.remove(f'{self.data_path}/2019_01_01_01_UTC_County_Mean_Meteorology.csv')
        except OSError:
            pass
        try:
            os.remove(f'{self.data_path}/2019_01_01_02_UTC_County_Mean_Meteorology.csv')
        except OSError:
            pass

        # generate the weights and output files
        wrf_to_tell_counties(
            wrf_file=f'{self.data_path}/test_data.nc',
            wrf_variables=['T2', 'Q2', 'U10', 'V10', 'SWDOWN', 'GLW'],
            precisions=[2, 5, 2, 2, 2, 2],
            county_shapefile=f'{self.data_path}/test_counties.shp',
            weight_and_mapping_file=f'{self.data_path}/test_weights.parquet',
            output_directory=self.data_path,
            output_filename_suffix='_County_Mean_Meteorology',
            n_jobs=-1,
        )

        # load the output files and check results
        slice_one = pd.read_csv(f'{self.data_path}/2019_01_01_01_UTC_County_Mean_Meteorology.csv')
        slice_two = pd.read_csv(f'{self.data_path}/2019_01_01_02_UTC_County_Mean_Meteorology.csv')

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
