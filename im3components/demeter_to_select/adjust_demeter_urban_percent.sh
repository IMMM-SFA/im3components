#!/bin/bash
#SBATCH --partition=slurm
#SBATCH --nodes=1
#SBATCH --time=07:00:00
#SBATCH --job-name=urban
#SBATCH -A im3
#SBATCH --mail-type=all          # send email on job start, end and fault
#SBATCH --mail-user=chris.vernon@pnnl.gov

# ------------------------
# README
#
# This script runs every year per 75 feasible scenarios (gcm, ssp, rcp combos that were solvable by GCAM)
# trailing argument 1 is unharmonized method, 2 is harmonized method
#
# sbatch --array=1-75 /pic/projects/im3/mcmanamay/code/adjust_demeter_urban_percent.sh 1
# ------------------------

module purge
module load gdal/1.10.1
module load R/3.4.3

RCODE='/pic/projects/im3/mcmanamay/code/adjust_demeter_urban_percent.R'

Rscript $RCODE $SLURM_ARRAY_TASK_ID $1
