#!/bin/bash
#SBATCH --partition=short
#SBATCH --nodes=1
#SBATCH --time=00:59:00
#SBATCH --job-name=urban
#SBATCH -A im3
#SBATCH --mail-type=all          # send email on job start, end and fault
#SBATCH --mail-user=chris.vernon@pnnl.gov

# ------------------------
# README
#
# sbatch --array=1-<your number> /pic/projects/im3/mcmanamay/code/adjust_demeter_urban.sh
# ------------------------

module purge
module load gdal/1.10.1
module load R/3.4.3

RCODE='/pic/projects/im3/mcmanamay/code/adjust_demeter_urban.R'

Rscript $RCODE $SLURM_ARRAY_TASK_ID
