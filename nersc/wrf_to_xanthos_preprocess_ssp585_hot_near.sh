#!/bin/sh

#SBATCH -n 1
#SBATCH -t 25:00:00
#SBATCH -A m2702
#SBATCH -J wrf_to_xanthos
#SBATCH -C knl
#SBATCH -p regular
#SBATCH --array=33-50

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
# sbatch wrf_to_xanthos_process.sh 
# squeue -u USERNAME
#
# ------------------------------------------------------

# Set up Parallel Runs
path="/global/cfs/cdirs/m2702/gsharing/CONUS_TGW_WRF_SSP585_HOT_NEAR"
declare -a PARRAY_FILES=( "${path}"/* )
echo "PARRAY_FILES 0 to 6: ${PARRAY_FILES[@]:0:6}"
echo "PARRAY_FILES contains ${#PARRAY_FILES[*]} elements"
LAST_FILE=${#PARRAY_FILES[*]}
echo "LAST_FILE: ${LAST_FILE}"
echo "Last file is : ${PARRAY_FILES[@]:((LAST_FILE-1)):1}"

cd /global/cfs/cdirs/m2702/gcamusa/wrf_to_xanthos

NUM_DOWN="$((SLURM_ARRAY_TASK_ID*50))"
NUM_UP=50
echo "NUM_DOWN: ${NUM_DOWN}"
echo "NUM_UP: ${NUM_UP}"

RUN_FILES=${PARRAY_FILES[@]:NUM_DOWN:NUM_UP}
echo "Run ID: ${SLURM_ARRAY_TASK_ID}"
echo "RUN_FILES:  ${RUN_FILES}"

# Run R script to create .csv files
date
Rscript /global/cfs/cdirs/m2702/gcamusa/wrf_to_xanthos/wrf_to_xanthos_preprocess_ssp585_hot_near.R ${RUN_FILES}  ${SLURM_ARRAY_TASK_ID}
date
echo 'completed wrf_to_xanthos_preprocess_ssp5_hot_near.R'

