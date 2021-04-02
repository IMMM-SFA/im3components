"""Tests for the StateMod data extraction.

:author:   Travis B. Thurber
:email:    travis.thurber@pnnl.gov

License:  BSD 2-Clause, see LICENSE and DISCLAIMER files

"""

from pathlib import Path
import pkg_resources
import pytest
import tempfile
import unittest
import warnings

import im3components as im3c


class TestStatemodDataExtraction(unittest.TestCase):
    """Tests for the StateMod data extraction."""

    def test_good_file(self):
        with tempfile.TemporaryDirectory() as tmp_dir:
            extractor = im3c.StateModDataExtractor(
                structure_ids_file_path=pkg_resources.resource_filename('im3components', 'tests/data/good_ids.txt'),
                glob_to_xdd=pkg_resources.resource_filename('im3components', 'tests/data/good_file_S101_1.xdd'),
                output_path=tmp_dir
            )
            extractor.extract()
            if not Path(f"{tmp_dir}/5104601.parquet").resolve().is_file():
                raise AssertionError("Failed to create parquet file for structure_id 5104601.")
            if not Path(f"{tmp_dir}/5102068.parquet").resolve().is_file():
                raise AssertionError("Failed to create parquet file for structure_id 5102068.")

    def test_bad_file(self):
        with tempfile.TemporaryDirectory() as tmp_dir:
            extractor = im3c.StateModDataExtractor(
                structure_ids_file_path=pkg_resources.resource_filename('im3components', 'tests/data/good_ids.txt'),
                glob_to_xdd=pkg_resources.resource_filename('im3components', 'tests/data/bad_file_S101_2.xdd'),
                output_path=tmp_dir
            )
            extractor.extract()
            if Path(f"{tmp_dir}/5104601.parquet").resolve().is_file():
                raise AssertionError("Failed to catch bad file format for structure_id 5104601.")
            if Path(f"{tmp_dir}/5102068.parquet").resolve().is_file():
                raise AssertionError("Failed to catch bad file format for structure_id 5102068.")

    @pytest.mark.filterwarnings("ignore::UserWarning")
    def test_missing_ids(self):
        with tempfile.TemporaryDirectory() as tmp_dir:
            extractor = im3c.StateModDataExtractor(
                structure_ids_file_path=pkg_resources.resource_filename('im3components', 'tests/data/no_ids.txt'),
                glob_to_xdd=pkg_resources.resource_filename('im3components', 'tests/data/good_file_S101_1.xdd'),
                output_path=tmp_dir
            )
            warnings.filterwarnings('ignore', category=UserWarning)
            self.assertRaises(IOError, extractor.extract)

    def test_missing_files(self):
        with tempfile.TemporaryDirectory() as tmp_dir:
            extractor = im3c.StateModDataExtractor(
                structure_ids_file_path=pkg_resources.resource_filename('im3components', 'tests/data/good_ids.txt'),
                glob_to_xdd=pkg_resources.resource_filename('im3components', 'tests/data/not_a_file.xdd'),
                output_path=tmp_dir
            )
            self.assertRaises(IOError, extractor.extract)
