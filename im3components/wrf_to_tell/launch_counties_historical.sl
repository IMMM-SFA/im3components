#!/usr/bin/env /bin/bash

#SBATCH -A m2702
#SBATCH -N 1
#SBATCH -C knl
#SBATCH --qos=regular
#SBATCH -t 08:00:00
#SBATCH --exclusive
#SBATCH --job-name wrf_to_tell_counties_historical
#SBATCH --mail-type=begin,end,fail
#SBATCH --mail-user=casey.burleyson@pnnl.gov

module load parallel
export HDF5_USE_FILE_LOCKING=FALSE
ulimit -u unlimited

srun parallel --retries 3 --jobs 4 'python wrf_tell_counties.py \
    --number-of-tasks 4 \
    --variables T2 Q2 U10 V10 SWDOWN GLW \
    --precisions 2 5 2 2 2 2 \
    --shapefile-path /global/cscratch1/sd/cburley/wrf_to_tell/tl_2020_us_county/tl_2020_us_county.shp \
    --weights-file-path /global/cscratch1/sd/cburley/wrf_to_tell/grid_cell_to_county_weight.parquet \
    --output-directory /global/cfs/cdirs/m2702/wrf_to_tell/wrf_tell_counties_output/historic_1979_2020 \
    --output-filename-suffix _County_Mean_Meteorology \
' ::: /global/cfs/cdirs/m2702/gsharing/tgw-wrf-conus/historic_1979_2020/hourly/tgw_wrf_historic_hourly_*

# create empty county files for and report any missing data
# check the 'missing_data.txt' file in the output directory for a record of the missing timestamps
srun python wrf_tell_fill_missing_hours.py \
    --start 2080-01-01 \
    --end 2019-12-31 \
    --output-directory /global/cfs/cdirs/m2702/wrf_to_tell/wrf_tell_counties_output/historic_1979_2020 \
    --output-filename-suffix _County_Mean_Meteorology
