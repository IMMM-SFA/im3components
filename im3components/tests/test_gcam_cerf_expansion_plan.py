"""Tests for the configuration reader functionality.

:author:   Chris R. Vernon
:email:    chris.vernon@pnnl.gov

License:  BSD 2-Clause, see LICENSE and DISCLAIMER files

"""


import unittest

import im3components as im3c


class TestGcamCerfExpansionPlan(unittest.TestCase):
    """Tests for the GCAM to CERF expansion plan conversion."""

    def test_dummy_value(self):
        """Test for initial dummy value return."""

        # get result
        registry = im3c.registry()
        method = registry.get_component(registry.list_related('gcam')[0])
        result = method(0, 0)

        # function should return 0
        self.assertEqual(0, result, msg=f"Result for `gcam_cerf_expansion_plan` returned {result} instead of 0")
