import pandas as pd
import numpy as np
import os
import glob

"""wrf_xanthos_process

    Script to process WRF data to from .csv to .npy format
    License:  BSD 2-Clause, see LICENSE and DISCLAIMER files
    
    Contains the following functions:
    - wrf_xanthos_to_npy

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


def wrf_xanthos_combine_npy(
        folder_paths="",
        out_dir='output'):
    """Convert WRF output data from the R function wrf_xanthos_resample .csv outputs to .npy for xanthos

    :param folder_paths:        full path to folders with .npy files to combine
    :type folder_paths:         str

    :param out_dir:            name of folder to save outputs to. Default is 'output' in the working dir.
    :type out_dir:             str

    USAGE:
    from im3components import wrf_xanthos_combine_npy
    folder_paths = ['full_path_to_folder_with_files1','full_path_to_folder_with_files1']
    out_dir = 'output_folder_name' OR 'full_path_to_output_folder_name'
    wrf_xanthos_combine_npy(files_path, out_dir)

    """

    print("Starting wrf_xanthos_combine_npy...")

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
    if (len(folder_paths) == 0):
        raise ValueError(f'At least one of the arguments files_path or folder_path should be provided')

    # Get length of list of files in folder
    files_to_convert = (glob.glob(folder_paths[0] + "/*.npy"))

    # Check if all folders provided exist
    for i in range(0,len(folder_paths)):
        if not os.path.exists(folder_paths[i]):
            raise OSError(f'Folder path {folder_paths[i]} does not exist.')
        else:
            if(len(glob.glob(folder_paths[i] + "/*.npy")) != len((glob.glob(folder_paths[0] + "/*.npy")))):
                raise OSError(f'All folders should have the same number of files.')

    # For each file in combine them across the folders in the order given
    for i in range(0,len(files_to_convert)):
        comb_file_i = files_to_convert[i]
        size_i = len(comb_file_i)
        start_date = comb_file_i[size_i-22:size_i-15]
        print(f'Combining file: {comb_file_i} with: ')

        for j in range(1,len(folder_paths)):
            files_j = (glob.glob(folder_paths[j] + "/*.npy"))
            file_j = files_j[i]
            size_j = len(file_j)
            end_date = file_j[size_j - 11:size_j - 4]
            comb_npy_i = np.concatenate((np.load(comb_file_i), np.load(file_j)), axis=1)
            print(f'{file_j}')

        comb_file_name_i = comb_file_i[:size_i-22] + start_date + "_to_" + end_date + ".npy"
        comb_file_name_i_path = out_dir_path + '/' + os.path.basename(comb_file_name_i)
        np.save(file=comb_file_name_i_path, arr=comb_npy_i)
        print(f'Saved converted file as: {comb_file_name_i_path}')