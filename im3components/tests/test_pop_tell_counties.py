import pkg_resources
import unittest

import pandas as pd

import im3components.wrf_tell.pop_tell_counties as pop


class TestPopTellCounties(unittest.TestCase):

    COUNTY_SHAPEFILE = pkg_resources.resource_filename('im3components', 'tests/wrf_tell_data/test_counties.shp')
    RASTER_FILE = pkg_resources.resource_filename('im3components', 'tests/wrf_tell_data/test_population.tif')

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

        expected_df = pd.DataFrame({'FIPS': ['01001'], 'n_population': 19637.692808})

        df = pop.population_to_tell_counties(raster_file=TestPopTellCounties.RASTER_FILE,
                                             county_shapefile=TestPopTellCounties.COUNTY_SHAPEFILE)

        pd.testing.assert_frame_equal(expected_df, df)


if __name__ == '__main__':
    unittest.main()
