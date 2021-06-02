import os

"""wrf_to_xanthos

    Script to process WRF data to the required format for Xanthos
    License:  BSD 2-Clause, see LICENSE and DISCLAIMER files

    USAGE:
    from im3components import wrf_to_xanthos
    wrf_files = ['full_path_to_wrf_file1', 'full_path_to_wrf_file2']
    out_dir = 'output_folder_name' OR 'full_path_to_output_folder_name'
    wrf_to_xanthos(wrf_files, out_dir)

"""


def wrf_to_xanthos(wrf_files,
                   out_dir='output'):
    """Convert WRF data to required format for Xanthos

    :param wrf_files:             list of full paths to wrf files to convert.
    :param out_dir:               name of folder to save outputs to. Default is 'output' in the working dir.
    :return:                      path to output directory

    """

    # Initialize
    print("Starting xrf_to_xanthos...")

    # Check if wrf_files exist
    wrf_files_exist = list(map(os.path.exists, wrf_files))

    if not any(wrf_files_exist):
        print('None of the wrf_files provided exist: {}'.format(wrf_files))
        print('Stopping wrf_to_xanthos run.')
        exit()

    ## If all wrf_files !exists stop error
    ## If some wrf_files !exists print message:
    ### "The following wrf_files provided do not exist: xxx"
    ### "Running wrf_to_xanthos for remaining files: xxxx"

    # Check out_dir name and path
    ## if !dir.exists(out_dir) message: "out_dir provided does not exist. Using default dir "working_dir_path/output"

    # Process Mean Monthly Precipitation

    # Process Mean Monthly Relative Humidity Percentage

    # Process Mean Monthly Surface Downwelling LongWave Radiation

    # Process Mean Monthly Surface Downwelling shortwave Radiation

    # Process Mean monthly Daily mean Surface Air Temperature

    # Process Mean Monthly Daily Minimum Surface Air Temperature

    # Process Mean Monthly Wind Speed in m/s

    # Close out
    out_dir_path = os.getcwd()
    print("xrf_to_xanthos completed. Converted files saved to:")

    return out_dir_path
