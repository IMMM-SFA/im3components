import unittest

import im3components as cmp


class TestRDemo(unittest.TestCase):

    def test_r_demo(self):
        """Test the R demo code."""

        reg = cmp.registry()

        # get R demo function that returns the sum of two squares
        fx = reg.get_component('demo_demo_r')

        result = fx(2, 4)
        self.assertEqual(20, result)


if __name__ == '__main__':
    unittest.main()
