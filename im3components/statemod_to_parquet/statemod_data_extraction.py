#!/usr/bin/env python3
# SBATCH -A im3
# SBATCH --nodes=4
# SBATCH --ntasks-per-node=16
# SBATCH --cpus-per-task=1
# SBATCH -p normal
# SBATCH -t 03:00:00
# SBATCH --exclusive
# SBATCH --job-name xdd_to_parquet

import concurrent.futures.thread
import argparse
import dask.dataframe as dd
from glob import glob
from importlib.util import find_spec, module_from_spec
import io
from joblib import Parallel, delayed
import logging
import numpy as np
import pandas as pd
from pathlib import Path
from pyarrow.lib import ArrowInvalid
import re
import shutil
import sys
from timeit import default_timer as timer
from typing import Iterable

mpi_module = 'mpi4py.MPI'
mpi_futures = 'mpi4py.futures'


class StateModDataExtractor:
    """Class to handle extracting structure, sample, and realization data from StateMod xdd files."""

    def __init__(
            self,
            structure_ids_file_path: str,
            output_path: str,
            glob_to_xdd: str = None,
            xdd_files: Iterable[str] = None,
            allow_overwrite: bool = False,
            has_mpi: bool = False
    ):

        # path to file with the structure ids of interest separated by newlines
        # absolute path is best; relative path must be relative to where you run from
        self.structure_ids_file_path = structure_ids_file_path
        self.ids_of_interest = np.genfromtxt(self.structure_ids_file_path, dtype='str').tolist()

        # glob path to xdd files
        # absolute path is best; relative path must be relative to where you run from
        self.glob_to_xdd = glob_to_xdd
        self.files = xdd_files
        if self.glob_to_xdd is None and self.files is None:
            raise IOError("Must supply at least one xdd file.")

        # output path
        # be sure to look at the log file generated here after running
        # absolute path is best; relative path must be relative to where you run from
        self.output_path = output_path

        # temporary path for intermediate files; will be removed afterward
        self.temporary_path = f'{output_path}/tmp'

        # allow overwriting files in the output directory
        # this check is implemented in a simplistic way:
        #   - do any parquet files exist in output_path or not
        self.allow_overwrite = allow_overwrite

        # is mpi in use and loaded
        self.use_mpi = has_mpi

        # expected data format
        self.metadata_rows = np.arange(1, 12)
        self.id_column = 0
        self.id_column_name = 'structure_id'
        self.id_column_type = object
        self.year_column = 2
        self.year_column_name = 'year'
        self.year_column_type = np.uint16
        self.month_column = 3
        self.month_column_name = 'month'
        self.demand_column = 4
        self.month_column_type = object
        self.demand_column_name = 'demand'
        self.demand_column_type = np.uint32
        self.shortage_column = 17
        self.shortage_column_name = 'shortage'
        self.shortage_column_type = np.uint32

        # these columns will be added to all rows
        self.sample_column_name = 'sample'
        self.sample_column_type = np.uint16
        self.realization_column_name = 'realization'
        self.realization_column_type = np.uint8

        # regex to get sample number from file name
        self.sample_number_regex = re.compile(r'_S(\d+)_')
        # regex to get realization number from file name
        self.realization_number_regex = re.compile(r'_(\d+)(?:\.xdd)?$')

        # these are used to check that the data is in the expected format (i.e. hasn't changed on you unexpectedly):
        # how many fields
        self.expected_column_count = 35
        # how many characters allotted to each field, not including whitespace between fields
        # note that in some files, several asterisks spilled into other fields, ruining ability to split by whitespace
        self.expected_column_sizes = np.asarray([
            11, 13, 5, 5, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 13, 12
        ])
        # the line separator counts as an extra character, hence the +1
        self.expected_line_size = self.expected_column_sizes.sum() + 1

    def parse_xdd_file(self, file_path: str) -> bool:
        """Parses a StateMod xdd file into a parquet file.

        Args:
            file_path (str): a file path to an xdd file

        Returns:
            bool: a boolean indicating whether or not parsing was successful (True means success)
        """

        path = Path(file_path)
        try:
            sample_number = int(self.sample_number_regex.search(path.stem).group(1))
            realization_number = int(self.realization_number_regex.search(path.stem).group(1))
        except (IndexError, AttributeError):
            logging.error(f"Unable to parse sample or realization number from file name: {path.stem}.")
            return False

        # stream will hold CSV of interesting data
        stream = io.StringIO()
        # read the file line by line
        with open(path, 'r') as file:
            id_start = np.sum(self.expected_column_sizes[:self.id_column])
            id_end = id_start + self.expected_column_sizes[self.id_column]
            for line in file:
                if line[id_start:id_end].strip() in self.ids_of_interest:
                    if len(line) != self.expected_line_size:
                        # unexpected line length; you need to double check the expected column sizes
                        logging.error(
                            f"Unexpected line length: {len(line)} instead of {self.expected_line_size}:\n{line}"
                        )
                        return False
                    # split data by character counts
                    data = []
                    position = 0
                    for count in self.expected_column_sizes:
                        data.append(line[position:position + count].strip())
                        # no space in between columns
                        position += count
                    if len(data) != self.expected_column_count:
                        # unexpected number of columns; you need to double check your data and settings
                        logging.error(
                            f"Unexpected column count: {len(data)} instead of {self.expected_column_count}:\n{line}"
                        )
                        return False
                    # only keep non-total rows
                    if not data[self.month_column].casefold().startswith('tot'):
                        stream.write(
                            ','.join(
                                [data[i] for i in [
                                    self.id_column,
                                    self.year_column,
                                    self.month_column,
                                    self.demand_column,
                                    self.shortage_column
                                ]]
                            )
                        )
                        stream.write('\n')
        stream.seek(0)

        df = pd.read_csv(
            stream,
            header=None,
            names=[
                self.id_column_name,
                self.year_column_name,
                self.month_column_name,
                self.demand_column_name,
                self.shortage_column_name
            ],
            dtype={
                self.id_column_name: self.id_column_type,
                self.year_column_name: self.year_column_type,
                self.month_column_name: self.month_column_type,
                self.demand_column_name: self.demand_column_type,
                self.shortage_column_name: self.shortage_column_type
            }
        )

        stream.close()

        df[self.sample_column_name] = self.sample_column_type(sample_number)
        df[self.realization_column_name] = self.realization_column_type(realization_number)

        df.to_parquet(
            Path(f'{self.temporary_path}/S{sample_number}_{realization_number}.parquet'),
            engine='pyarrow',
            compression='gzip'
        )
        return True

    def create_file_per_structure_id(self, structure_id: str) -> bool:
        """Reads a collection of parquet files and aggregates values for a structure_id into a single parquet file.

        Args:
            structure_id (str): the structure_id to aggregate

        Returns:
            bool: a boolean indicating whether aggregation was successful (True means success)
        """

        try:
            df = dd.read_parquet(
                Path(f'{self.temporary_path}/S*_*.parquet'),
                engine='pyarrow-dataset', filters=[[('structure_id', '=', structure_id)]]
            ).compute()
        except ArrowInvalid:
            logging.warning(f'Unable to parse file for structure_id: {structure_id}.')
            return False
        if len(df.index) == 0:
            logging.warning(f'No data for for structure_id: {structure_id}.')
            return False
        if not self.validate_data(df):
            logging.warning(f'WARNING: Anomalous data detected for structure_id: {structure_id}.')
        df.to_parquet(
            Path(f'{self.output_path}/{structure_id}.parquet'),
            engine='pyarrow',
            compression='gzip'
        )
        return True

    def validate_data(self, dataframe: pd.DataFrame) -> bool:
        """Attempts to determine if the data makes sense

        Args:
            dataframe (pd.DataFrame): the data to validate

        Returns:
            bool: a boolean indicating whether validation was successful (True means valid)
        """
        # TODO figure out how to validate data
        # TODO i.e. anomaly detection
        return True

    @staticmethod
    def pretty_timer(seconds: float) -> str:
        """Formats an elapsed time in a human friendly way.

        Args:
            seconds (float): a duration of time in seconds

        Returns:
            str: human friendly string representing the duration
        """
        if seconds < 1:
            return f'{round(seconds * 1.0e3, 0)} milliseconds'
        elif seconds < 60:
            return f'{round(seconds, 3)} seconds'
        elif seconds < 3600:
            return f'{int(round(seconds) // 60)} minutes and {int(round(seconds) % 60)} seconds'
        elif seconds < 86400:
            return f'{int(round(seconds) // 3600)} hours, {int((round(seconds) % 3600) // 60)} minutes, and {int(round(seconds) % 60)} seconds '
        else:
            return f'{int(round(seconds) // 86400)} days, {int((round(seconds) % 86400) // 3600)} hours, and {int((round(seconds) % 3600) // 60)} minutes'

    def extract(self):
        """Perform the data extraction"""

        # start a timer to track how long this takes
        t = timer()

        if not self.ids_of_interest or len(self.ids_of_interest) == 0:
            raise IOError(f"No structure_ids found in {self.structure_ids_file_path}. Aborting.")

        # get a list of the xdd files to parse
        files = self.files if self.files is not None and len(self.files) > 0 else glob(self.glob_to_xdd)

        # make sure we found some xdds
        if not files or len(files) == 0:
            raise IOError(f"Unable to find any files with '{self.glob_to_xdd}'")

        # check if output directory exists
        if not Path(self.output_path).is_dir():
            # create it if not
            Path(self.output_path).mkdir(parents=True, exist_ok=True)
        else:
            # check if it already has parquet files in it
            if len(list(Path(self.output_path).glob('*.parquet'))) > 0:
                # if overwrite not allowed, abort
                if not self.allow_overwrite:
                    raise FileExistsError(
                        'Parquet files exist in the output directory; ' +
                        'please move them or set `allow_overwrite` to True.'
                    )
        # create a temporary directory in output path to store intermediate files
        if not Path(self.temporary_path).is_dir():
            Path(self.temporary_path).mkdir(parents=True, exist_ok=True)
        elif len(list(Path(self.temporary_path).glob('*'))) > 0:
            # if the temporary path already has files, abort if overwrite not allowed
            raise FileExistsError(
                f'The temporary file path {self.temporary_path} ' +
                'already contains files; please move them or set `allow_overwrite` to True.'
            )

        # setup logging
        logging.basicConfig(
            level='INFO',
            format='%(asctime)s - %(filename)s: %(message)s',
            datefmt='%m/%d/%Y %I:%M:%S %p',
            handlers=[
                logging.FileHandler(Path(f'{self.output_path}/log.log')),
                logging.StreamHandler()
            ]
        )

        # check if MPI is available
        # if so, use mpi4py
        # if not, use joblib
        if self.use_mpi:
            context = futures.MPIPoolExecutor
            logging.info(f"Running with mpi4py; world size =  {mpi.COMM_WORLD.Get_size()}.")
        else:
            context = Parallel
            logging.info("Running with joblib.")

        with context(**(dict() if self.use_mpi else dict(n_jobs=-1, temp_folder=self.temporary_path))) as executor:

            # create the temporary files per xdd file
            logging.info('Creating temporary parquet files per xdd.')
            if self.use_mpi:
                successful_xdd = executor.map(self.parse_xdd_file, files, unordered=True)
            else:
                successful_xdd = executor(delayed(self.parse_xdd_file)(file) for file in files)
            # check how many failed
            failed_xdd = [files[i] for i, status in enumerate(successful_xdd) if status is False]
            if len(failed_xdd) > 0:
                logging.error("Failed to parse the following files:\n" + "\n".join(failed_xdd))

            # aggregate the temporary files per structure_id to create the final output files
            logging.info('Aggregating structure_id data to parquet files.')
            if self.use_mpi:
                successful_structure_id = executor.map(
                    self.create_file_per_structure_id,
                    self.ids_of_interest,
                    unordered=True
                )
            else:
                successful_structure_id = executor(
                    delayed(self.create_file_per_structure_id)(structure_id) for structure_id in self.ids_of_interest
                )
            # check how many failed
            failed_parquet = [
                self.ids_of_interest[i] for i, status in enumerate(successful_structure_id) if status is False
            ]
            if len(failed_parquet) > 0:
                logging.error(
                    "Failed to create parquet files for the following structure_ids:\n" + "\n".join(failed_parquet)
                )

        # remove temporary files
        shutil.rmtree(Path(self.temporary_path))

        logging.info(
            f'Processed {len(files) - len(failed_xdd)} xdd files ' +
            f'into {len(self.ids_of_interest) - len(failed_parquet)} parquet files ' +
            f'in {self.pretty_timer(timer() - t)}.'
        )
        if len(failed_xdd) > 0 or len(failed_parquet) > 0:
            logging.error(
                f"Failed to process to {len(failed_xdd)} xdd files and {len(failed_parquet)} structure_id files."
            )


if __name__ == '__main__':

    use_mpi = False
    mpi_spec = find_spec(mpi_module)
    if mpi_module in sys.modules:
        use_mpi = True
    elif mpi_spec is not None:
        mpi = module_from_spec(mpi_spec)
        futures_spec = find_spec(mpi_futures)
        futures = module_from_spec(futures_spec)
        sys.modules[mpi_module] = mpi
        sys.modules[mpi_futures] = futures
        mpi_spec.loader.exec_module(mpi)
        futures_spec.loader.exec_module(futures)
        if mpi.COMM_WORLD.Get_size() > 1:
            use_mpi = True

    if not use_mpi or mpi.COMM_WORLD.Get_rank() == 0:

        parser = argparse.ArgumentParser(
            description=
            "Extract data from XDD files for a given set of structure IDs, producing a parquet file for each ID."
        )
        parser.add_argument(
            '-f',
            '--force',
            action='store_true',
            dest='force',
            help="allow overwriting existing parquet files (default: false)"
        )
        parser.add_argument(
            '-i',
            '--ids',
            metavar='/path/to/id/file',
            action='store',
            required=True,
            dest='ids',
            help="path to a file containing whitespace delimited structure ids of interest (required)"
        )
        parser.add_argument(
            '-o',
            '--output',
            metavar='/path/to/output/directory',
            action='store',
            default=Path('./output'),
            dest='output',
            help="path to a directory to write the output files (default: './output')"
        )
        parser.add_argument(
            'files',
            metavar='file',
            nargs='+',
            help="glob to the XDD files to parse (i.e. './*.xdd')"
        )

        args = parser.parse_args()

        extractor = StateModDataExtractor(
            allow_overwrite=args.force,
            xdd_files=args.files,
            output_path=args.output,
            structure_ids_file_path=args.ids,
            has_mpi=use_mpi
        )
        extractor.extract()
