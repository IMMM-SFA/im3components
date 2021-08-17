import pandas as pd
import numpy as np
import os
import glob

"""wrf_xanthos_process

    Script to process WRF data to from .csv to .npy format
    License:  BSD 2-Clause, see LICENSE and DISCLAIMER files
    
    Contains the following functions:
    - wrf_xanthos_to_npy
    - utils_replace_nan_array
    - xanthos_expand_replace_data

"""

def wrf_xanthos_to_npy(
        files_path=[],
        folder_path="",
        out_dir='output'):
    """Convert WRF output data from the R function wrf_xanthos_resample .csv outputs to .npy for xanthos

    :param files_path:        full paths to .csv files to convert to .npy
    :type files_path:         list

    :param folder_path:        full path to folder with .csv files to convert to .npy
    :type folder_path:         str

    :param out_dir:                name of folder to save outputs to. Default is 'output' in the working dir.
    :type out_dir:             str

    USAGE:
    from im3components import wrf_xanthos_to_npy
    files_path = ['full_path_to_wrf_file1', 'full_path_to_wrf_file2']
    # OR folder_path = 'full_path_to_folder_with_files'
    out_dir = 'output_folder_name' OR 'full_path_to_output_folder_name'
    wrf_xanthos_to_npy(files_path, out_dir)

    """

    print("Starting wrf_xanthos_to_npy...")

    # Check out_dir name and path
    if not os.path.exists(out_dir):
        if (out_dir.find('/') != -1) or (out_dir.find('/') != -1):
            print(f'Path provided for out_dir is not correct: {out_dir}')
            print(f'Using default output directory : {os.getcwd() + "/output"}')
            out_dir_path = os.getcwd() + "/output"
            os.mkdir(out_dir_path)
        else:
            print(f'Saving outputs to : {os.getcwd() + "/" + out_dir}')
            out_dir_path = os.getcwd() + "/" + out_dir
            os.mkdir(out_dir_path)
    else:
        out_dir_path = out_dir

    # Check that at least one of files_path or folder_path are provided
    if (len(files_path) == 0 and len(folder_path) == 0):
        raise ValueError(f'At least one of the arguments files_path or folder_path should be provided')

    # If files_path provided add to list of files to convert
    files_to_convert = files_path

    # If folder_path provided get list of .csv files from folder
    if not os.path.exists(folder_path):
        raise ValueError(f'At least one of the arguments files_path or folder_path should be provided')
    else:
        files_to_convert = files_to_convert + (glob.glob(folder_path + "/*.csv"))

    if len(files_to_convert) > 0:
        for file_i in files_to_convert:
            print(f'Converting file: {file_i}')
            table_i = pd.read_csv(file_i)
            table_i = table_i.drop(["lat","lon","gridid","param","unit"],axis=1)
            file_name = out_dir_path + '/' + os.path.basename(file_i.replace(".csv", ".npy"))
            np.save(file_name, table_i)
            print(f'Saved converted file as: {file_name}')
            

def utils_replace_nan_array(
        nan_array,
        replace_array):
    """Replace values in nan_array by values from replace_array

    :param nan_array:        .npy ndarray with nan values to be replace
    :type nan_array:        ndarray

    :param replace_array:        .npy ndarray with nan values to be replace
    :type replace_array:        ndarray

    USAGE:
    import numpy as np
    import im3components
    nan_array = np.zeros((2,2))
    nan_array[1,1] = float("nan")
    replace_array = np.ones((2,2))
    new_array = im3components.utils_replace_nan_array(nan_array,replace_array)

    """

    print("Starting utils_replace_nan_array...")

    # Check that both nan_array and replace_array are ndarrays
    if not isinstance(nan_array, (list, tuple, np.ndarray)):
        raise ValueError(f'nan_array must be an array,list or tuple.')
    if not isinstance(replace_array, (list, tuple, np.ndarray)):
        raise ValueError(f'replace_array must be an array,list or tuple.')

    # Check that shape is the same
    if not nan_array.shape == replace_array.shape:
        raise ValueError(f'nan_array and replace_array must have the same size.')

    # Initialize return_array
    return_array = np.copy(nan_array)

    # Replace nan values
    for i in range(0,nan_array.shape[0]):
        for j in range(0,nan_array.shape[1]):
            if np.isnan(return_array[i,j]):
                return_array[i,j] = replace_array[i,j]

    print("utils_replace_nan_array complete.")

    return(return_array)

def utils_expand_subset_array(
        base_array,
        base_year_month_min,
        base_year_month_max,
        target_year_month_min,
        target_year_month_max):

    """Expand and subset base array based on year_month provided

    :param base_array:       .npy ndarray with values to be replaced
    :type base_array:        ndarray

    :param base_year_month_min:    min year and month for base data e.g. 1971_01
    :type base_year_month_min:     str

    :param base_year_month_max:    max year and month for base data e.g. 2001_12
    :type base_year_month_max:     str

    :param target_year_month_min:    min year and month for target data e.g. 1980_01
    :type target_year_month_min:     str

    :param target_year_month_max:    max year and month for target data e.g. 2100_12
    :type target_year_month_max:     str

    USAGE:
    import numpy as np
    import pandas as pd
    import im3components
    base_array = np.zeros((4,12))
    new_array = im3components.utils_expand_array(base_array = ,
        base_year_month_min,
        base_year_month_max,
        target_year_month_min,
        target_year_month_max)

    """

    print("Starting utils_expand_replace_data...")

    base_array = np.load("C:/Z/models/00tests/xanthos_im3_test/example/input/climate/pr_gpcc_watch_monthly_mmpermth_1971_2001.npy")

    # Convert to data.frame
    base_df = pd.DataFrame(base_array)

    # Add column names
    years = list(map(str,list(range(1971,2001+1))))
    months = list(["_01","_02","_03","_04","_05","_06","_07","_08","_09","_10","_11","_12"])
    years_month = [x + y for x in years for y in months]



    # Check that both nan_array and replace_array are ndarrays
    if not isinstance(nan_array, (list, tuple, np.ndarray)):
        raise ValueError(f'nan_array must be an array,list or tuple.')
    if not isinstance(replace_array, (list, tuple, np.ndarray)):
        raise ValueError(f'replace_array must be an array,list or tuple.')

    # Check that shape is the same
    if not nan_array.shape == replace_array.shape:
        raise ValueError(f'nan_array and replace_array must have the same size.')

    # Initialize return_array
    return_array = np.copy(nan_array)

    # Replace nan values
    for i in range(0,nan_array.shape[0]):
        for j in range(0,nan_array.shape[1]):
            if np.isnan(return_array[i,j]):
                return_array[i,j] = replace_array[i,j]

    print("utils_replace_nan_array complete.")

    return(return_array)