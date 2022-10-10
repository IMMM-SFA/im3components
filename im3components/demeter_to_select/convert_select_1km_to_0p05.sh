#!/bin/bash
#SBATCH --partition=short
#SBATCH --nodes=1
#SBATCH --time=01:00:00
#SBATCH --job-name=select
#SBATCH -A im3


# ------------------------
# README
#
# sbatch --array=1-45 /pic/projects/im3/mcmanamay/code/convert_select_1km_to_0p05.sh
# ------------------------

module purge
module load gdal/1.10.1
module load R/3.4.3

RCODE='/pic/projects/im3/mcmanamay/code/convert_select_1km_to_0p05.R'

Rscript $RCODE $SLURM_ARRAY_TASK_ID
