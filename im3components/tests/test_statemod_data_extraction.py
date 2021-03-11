"""Tests for the StateMod data extraction.

:author:   Travis B. Thurber
:email:    travis.thurber@pnnl.gov

License:  BSD 2-Clause, see LICENSE and DISCLAIMER files

"""

from pathlib import Path
import tempfile
import unittest
import warnings

import im3components as im3c


class TestStatemodDataExtraction(unittest.TestCase):
    """Tests for the StateMod data extraction."""

    def test_good_file(self):
        with tempfile.TemporaryDirectory() as tmp_dir:
            extractor = im3c.StateModDataExtractor()
            extractor.structure_ids_file_path = 'im3components/tests/data/good_ids.txt'
            extractor.glob_to_xdd = 'im3components/tests/data/good_file_S101_1.xdd'
            extractor.output_path = tmp_dir
            extractor.temporary_path = f"{tmp_dir}/tmp"
            extractor.extract()
            if not Path(f"{tmp_dir}/5104601.parquet").resolve().is_file():
                raise AssertionError("Failed to create parquet file for structure_id 5104601.")
            if not Path(f"{tmp_dir}/5102068.parquet").resolve().is_file():
                raise AssertionError("Failed to create parquet file for structure_id 5102068.")

    def test_bad_file(self):
        with tempfile.TemporaryDirectory() as tmp_dir:
            extractor = im3c.StateModDataExtractor()
            extractor.structure_ids_file_path = 'im3components/tests/data/good_ids.txt'
            extractor.glob_to_xdd = 'im3components/tests/data/bad_file_S101_2.xdd'
            extractor.output_path = tmp_dir
            extractor.temporary_path = f"{tmp_dir}/tmp"
            extractor.extract()
            if Path(f"{tmp_dir}/5104601.parquet").resolve().is_file():
                raise AssertionError("Failed to catch bad file format for structure_id 5104601.")
            if Path(f"{tmp_dir}/5102068.parquet").resolve().is_file():
                raise AssertionError("Failed to catch bad file format for structure_id 5102068.")

    def test_missing_ids(self):
        with tempfile.TemporaryDirectory() as tmp_dir:
            extractor = im3c.StateModDataExtractor()
            extractor.structure_ids_file_path = 'im3components/tests/data/no_ids.txt'
            extractor.glob_to_xdd = 'im3components/tests/data/good_file_S101_1.xdd'
            extractor.output_path = tmp_dir
            extractor.temporary_path = f"{tmp_dir}/tmp"
            warnings.filterwarnings('ignore', category=UserWarning)
            self.assertRaises(IOError, extractor.extract)

    def test_missing_files(self):
        with tempfile.TemporaryDirectory() as tmp_dir:
            extractor = im3c.StateModDataExtractor()
            extractor.structure_ids_file_path = 'im3components/tests/data/good_ids.txt'
            extractor.glob_to_xdd = 'im3components/tests/data/not_a_file.xdd'
            extractor.output_path = tmp_dir
            extractor.temporary_path = f"{tmp_dir}/tmp"
            self.assertRaises(IOError, extractor.extract)
