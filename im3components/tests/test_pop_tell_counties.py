import pkg_resources
import unittest

import pandas as pd

import im3components as cmp
import im3components.pop_tell_counties as pop


class TestPopTellCounties(unittest.TestCase):

    COMPONENT_NAME = 'population_tell_counties'
    COUNTY_SHAPEFILE = pkg_resources.resource_filename('im3components', 'tests/wrf_tell_data/test_counties.shp')
    RASTER_FILE = pkg_resources.resource_filename('im3components', 'tests/data/test_population.tif')

    EXPECTED_OUTPUT = pd.DataFrame({'FIPS': ['01001'], 'n_population': 19637.692808})

    def test_validate_year(self):
        """Ensure year responds as expected under different conditions."""

        # pass conditions
        condition_a = 2020
        condition_b = '2020'
        condition_c = 2020.0

        # fail conditions
        condition_d = 777
        condition_e = '2020.0'
        condition_f = 12777

        self.assertEqual(pop.validate_year(condition_a), 2020)
        self.assertEqual(pop.validate_year(condition_b), 2020)
        self.assertEqual(pop.validate_year(condition_c), 2020)

        with self.assertRaises(AssertionError):
            pop.validate_year(condition_d)

        with self.assertRaises(ValueError):
            pop.validate_year(condition_e)

        with self.assertRaises(AssertionError):
            pop.validate_year(condition_f)

    def test_validate_string(self):
        """Ensure string responds as expected under different conditions."""

        condition_a = 'SSP3'
        condition_b = 'District of Columbia'

        a = pop.validate_string(condition_a)
        b = pop.validate_string(condition_b)

        self.assertEqual(a, 'ssp3')
        self.assertEqual(b, 'district-of-columbia')

    def test_build_polygon_from_centroid(self):
        """Ensure polygon is built as expected given a centroid and expected resolution."""

        x_coordinate = 70.5
        y_coordinate = 70.5
        x_resolution = 1000
        y_resolution = 1000

        expected_bounds = (-429.5, -429.5, 570.5, 570.5)
        expected_exterior = [(-429.5, -429.5), (570.5, -429.5), (570.5, 570.5), (-429.5, 570.5), (-429.5, -429.5)]
        expected_length = 4000.0
        expected_area = 1000000.0

        poly = pop.build_polygon_from_centroid(x_coordinate, y_coordinate, x_resolution, y_resolution)

        self.assertEqual(expected_bounds, poly.bounds)
        self.assertEqual(expected_exterior, list(poly.exterior.coords))
        self.assertEqual(expected_length, poly.length)
        self.assertEqual(expected_area, poly.area)

    def test_population_to_tell_counties(self):
        """Ensure the function outputs as expected."""

        df = pop.population_to_tell_counties(raster_file=TestPopTellCounties.RASTER_FILE,
                                             county_shapefile=TestPopTellCounties.COUNTY_SHAPEFILE)

        pd.testing.assert_frame_equal(TestPopTellCounties.EXPECTED_OUTPUT, df)

    def test_registry(self):
        """Test component registry functionality."""

        reg = cmp.registry()

        # get a list of all components
        registry_list = reg.list_registry()

        # get a list of population components
        registry_asset = reg.list_related(asset='population')

        # ensure this component has been registered
        self.assertTrue(TestPopTellCounties.COMPONENT_NAME in registry_list)

        # ensure component is findable by asset name
        self.assertTrue(TestPopTellCounties.COMPONENT_NAME in registry_asset)

        # check asset function
        my_asset_function = reg.get_function(TestPopTellCounties.COMPONENT_NAME)

        df = my_asset_function(raster_file=TestPopTellCounties.RASTER_FILE,
                               county_shapefile=TestPopTellCounties.COUNTY_SHAPEFILE)

        pd.testing.assert_frame_equal(TestPopTellCounties.EXPECTED_OUTPUT, df)


if __name__ == '__main__':
    unittest.main()
