#!/usr/bin/env /bin/bash

#SBATCH -A m2702
#SBATCH -N 1
#SBATCH -C knl
#SBATCH -p regular
#SBATCH -t 04:00:00
#SBATCH --exclusive
#SBATCH --job-name wrf_to_tell_bas_historical
#SBATCH --mail-type=begin,end,fail
#SBATCH --mail-user=casey.burleyson@pnnl.gov

module load parallel

srun parallel --retries 3 --jobs 1 "python wrf_tell_balancing_authorities.py \
    --is-historical true \
    --variables T2 Q2 U10 V10 SWDOWN GLW \
    --precisions 2 5 2 2 2 2 \
    --balancing-authority-to-county /global/cscratch1/sd/cburley/wrf_to_tell/ba_service_territory_2019.csv \
    --county-population-by-year /global/cscratch1/sd/cburley/wrf_to_tell/county_populations_2000_to_2019.csv \
    --county-mean-data-directory /global/cfs/cdirs/m2702/wrf_to_tell/wrf_tell_counties_output/historic_1979_2020 \
    --output-directory /global/cfs/cdirs/m2702/wrf_to_tell/wrf_tell_bas_output/historic \
    --output-file-infix WRF_Hourly_Mean_Meteorology \
    --county-data-prefix '' \
    --county-data-suffix County_Mean_Meteorology \
    --county-data-time-format '%Y_%m_%d_%H' \
" ::: {1980..2019}
