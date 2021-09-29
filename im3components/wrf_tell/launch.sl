#!/usr/bin/env /bin/bash

#SBATCH -A <project>
#SBATCH -N 1
#SBATCH -C knl
#SBATCH -p regular
#SBATCH -t 08:00:00
#SBATCH --exclusive
#SBATCH --job-name wrf_to_tell_counties
#SBATCH --mail-type=begin,end,fail
#SBATCH --mail-user=<email address>

module load parallel
export HDF5_USE_FILE_LOCKING=FALSE

srun parallel --jobs 4 'python wrf_tell_counties.py \
    --number-of-tasks 8 \
    --variables T2 Q2 U10 V10 SWDOWN GLW \
    --precisions 2 5 2 2 2 2 \
    --shapefile-path ./Geolocation/tl_2020_us_county/tl_2020_us_county.shp \
    --weights-file-path ./grid_cell_to_county_weight.parquet \
    --output-path ./County_Output_Files \
' ::: ./Raw_Data/wrfout*
