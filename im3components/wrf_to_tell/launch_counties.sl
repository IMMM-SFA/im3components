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
    --output-directory ./County_Output_Files \
    --output-filename-suffix _County_Mean_Meteorology \
' ::: ./Raw_Data/wrfout*

# create empty county files for and report any missing data
# check the 'missing_data.txt' file in the output directory for a record of the missing timestamps
srun 'python wrf_tell_fill_missing_hours.py \
    --start 2019-01-01 \
    --end 2019-12-31 \
    --output-directory ./County_Output_Files \
    --output-filename-suffix _County_Mean_Meteorology \
'