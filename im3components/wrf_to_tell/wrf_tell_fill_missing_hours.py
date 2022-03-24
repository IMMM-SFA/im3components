import argparse
import os

from datetime import datetime, timedelta
from glob import glob

import numpy as np
import pandas as pd


def fill_missing_hours(
    start: str,
    end: str,
    output_directory: str = './County_Output_Files',
    output_filename_suffix: str = '_County_Mean_Meteorology',
):
    """
    Check county output files for missing hours and create files for those hours filled with NaNs.

    :param str start: first expected datetime in ISO8601 format; if just a date assumes start of day (1am)
    :param str end: last expected datetime in ISO8601 format; if just a date assumes end of day (midnight)
    :param str output_directory: path to which output should be written
    :param str output_filename_suffix: string to append to the timestamp for the output file name
    :param str county_data_time_format: format string of the datetimes in the mean county data filenames
    """
    try:
        if (start is None) or (end is None):
            raise ValueError()
        if (start == '') or (end == ''):
            raise ValueError()
        start_dt = datetime.fromisoformat(start)
        end_dt = datetime.fromisoformat(end)
        # ensure minute, second, and microsecond are 0
        start_dt = start_dt.replace(microsecond=0, second=0, minute=0)
        end_dt = end_dt.replace(microsecond=0, second=0, minute=0)
        if len(start) == 10:
            # only a start date was provided, set start time to 1am
            start_dt = start_dt.replace(hour=1)
        if len(end) == 10:
            # only an end date was provided, set end time to midnight
            end_dt = end_dt.replace(hour=0) + timedelta(days=1)
    except ValueError:
        raise ValueError('Start and end must be provided in ISO8601 format.')

    county_files = sorted(glob(f"{output_directory}/*{output_filename_suffix}.csv"))
    county_datetimes = pd.to_datetime(county_files, exact=False, format='%Y_%m_%d_%H')
    expected_datetimes = pd.date_range(start_dt, end_dt, freq='1H')
    missing = expected_datetimes[~expected_datetimes.isin(county_datetimes)]

    # read the first file as a template
    data = pd.read_csv(county_files[0], dtype={'FIPS': str})
    data.loc[:, data.columns[data.columns != 'FIPS']] = np.NaN

    # write the NaN file for each missing hour
    for dt in missing:
        print(f'Missing data: {str(dt)}.')
        data.to_csv(f'{output_directory}/{dt.strftime("%Y_%m_%d_%H_UTC")}{output_filename_suffix}.csv')

    # write a file summarizing the missing data
    output_filename = os.path.join(output_directory, 'missing_data_' + start + '_to_' + end + '.txt')
    pd.Series(missing.format()).to_csv(output_filename, header=['Missing Data'], index=False)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        description='Check county output files for missing hours and create files for those hours filled with NaNs.'
    )
    parser.add_argument(
        '-s',
        '--start',
        type=str,
        help='first expected datetime in ISO8601 format; if just a date assumes start of day (1am)',
        required=True,
    )
    parser.add_argument(
        '-e',
        '--end',
        type=str,
        help='last expected datetime in ISO8601 format; if just a date assumes end of day (midnight)',
        required=True,
    )
    parser.add_argument(
        '-o',
        '--output-directory',
        type=str,
        help='path to which output should be written',
        required=True,
    )
    parser.add_argument(
        '--output-filename-suffix',
        type=str,
        help='string to append to the timestamp for the output file name',
        default='_County_Mean_Meteorology'
    )
    args = parser.parse_args()
    fill_missing_hours(
        start=args.start,
        end=args.end,
        output_directory=args.output_directory,
        output_filename_suffix=args.output_filename_suffix,
    )
