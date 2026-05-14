#!/bin/bash
#SBATCH --job-name=perpendicularFlap
#SBATCH --output=log.%x_%j.out
#SBATCH --error=log.%x_%j.err
#SBATCH --partition=main
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --time=12:00:00

cd "$SLURM_SUBMIT_DIR"

. /usr/lib/openfoam/openfoam2512/etc/bashrc

: "${STUDY:=mesh}"

./Allrun "$STUDY" &> "log.Allrun.${STUDY}"
