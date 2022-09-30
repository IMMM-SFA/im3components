#!/usr/bin/env /bin/bash

#SBATCH -A <project>
#SBATCH -N 1
#SBATCH -C knl
#SBATCH -p regular
#SBATCH -t 04:00:00
#SBATCH --exclusive
#SBATCH --job-name wrf_to_tell_bas
#SBATCH --mail-type=begin,end,fail
#SBATCH --mail-user=<email address>

module load parallel

srun parallel --retries 3 --jobs 1 "python wrf_tell_balancing_authorities.py \
    --is-historical true \
    --variables T2 Q2 U10 V10 SWDOWN GLW \
    --precisions 2 5 2 2 2 2 \
    --balancing-authority-to-county ./ba_service_territory_2019.csv \
    --county-population-by-year ./county_populations_2000_to_2019.csv \
    --county-mean-data-directory ./County_Output_Files \
    --output-directory ./BA_Output_Files \
    --output-file-infix WRF_Hourly_Mean_Meteorology \
    --county-data-prefix '' \
    --county-data-suffix County_Mean_Meteorology \
    --county-data-time-format '%Y_%m_%d_%H' \
" ::: {1980..2019}
