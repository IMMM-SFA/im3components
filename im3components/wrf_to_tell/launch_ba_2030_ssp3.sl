#!/usr/bin/env /bin/bash

#SBATCH -A m2702
#SBATCH -N 1
#SBATCH -C knl
#SBATCH --qos=premium
#SBATCH -t 02:00:00
#SBATCH --exclusive
#SBATCH --job-name wrf_to_tell_bas_rcp45coolerssp3_2030
#SBATCH --mail-type=begin,end,fail
#SBATCH --mail-user=casey.burleyson@pnnl.gov

module load parallel

srun parallel --retries 3 --jobs 1 "python wrf_tell_balancing_authorities.py \
    --is-historical false \
    --variables T2 Q2 U10 V10 SWDOWN GLW \
    --precisions 2 5 2 2 2 2 \
    --balancing-authority-to-county /global/cscratch1/sd/cburley/wrf_to_tell/ba_service_territory_2019.csv \
    --county-population-by-year /global/cscratch1/sd/cburley/wrf_to_tell/ssp3_county_population.csv \
    --county-mean-data-directory /global/cfs/cdirs/m2702/wrf_to_tell/wrf_tell_counties_output/rcp45cooler_2019_2059 \
    --output-directory /global/cfs/cdirs/m2702/wrf_to_tell/wrf_tell_bas_output/rcp45cooler_ssp3 \
    --output-file-infix WRF_Hourly_Mean_Meteorology \
    --county-data-prefix '' \
    --county-data-suffix County_Mean_Meteorology \
    --county-data-time-format '%Y_%m_%d_%H' \
" ::: {2030..2031}
