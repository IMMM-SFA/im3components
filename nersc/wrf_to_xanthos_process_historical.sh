#!/bin/sh

#SBATCH -n 1
#SBATCH -t 20:00:00
#SBATCH -A m2702
#SBATCH -J wrf_to_xanthos
#SBATCH -C knl
#SBATCH -p regular

export HDF5_USE_FILE_LOCKING=FALSE

# User Settings
module load R/3.6.1-conda
module load gcc/9.3.0
module load python/3.8-anaconda-2020.11

# ------------------------------------------------------
# This script is used to run the entire work flow for 
# processing WRF data to Xanthos data.
# 
# To run this script:
# cd /global/cfs/cdirs/m2702/gcamusa/wrf_to_xanthos
# sbatch wrf_to_xanthos_process_historical.sh 
# squeue -u USERNAME
#
# ------------------------------------------------------

# Combine R pre-processed data

cd /global/cfs/cdirs/m2702/gcamusa/wrf_to_xanthos

# Run R script to create .csv files
date
R CMD BATCH /global/cfs/cdirs/m2702/gcamusa/wrf_to_xanthos/wrf_to_xanthos_process_historical.R 
date
echo 'completed wrf_to_xanthos_process_hisotrical.R'

# Preparing to run python scripts
cd /global/cfs/cdirs/m2702/gcamusa/wrf_to_xanthos/im3components
source venv/bin/activate
cd /global/cfs/cdirs/m2702/gcamusa/wrf_to_xanthos

# Run Python script to convert .csv files to .npy
date
python /global/cfs/cdirs/m2702/gcamusa/wrf_to_xanthos/wrf_to_xanthos_process_historical.py
date
echo 'completed wrf_to_xanthos_process_historical.py'
