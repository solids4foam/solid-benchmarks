#!/bin/bash
#SBATCH --job-name=HronTurekFsi3
#SBATCH --output=log.%x_%j.out
#SBATCH --error=log.%x_%j.err
#SBATCH --partition=long
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --time=72:00:00

cd $SLURM_SUBMIT_DIR

# Load OpenFOAM
source /usr/lib/openfoam/openfoam2512/etc/bashrc

# Campaign controls can be overridden at submission time, e.g.
#   sbatch --export=ALL,STUDY=time,METHODS="monolithic:default partitioned:IQNILS" run.slurm
: "${STUDY:=mesh}"

./Allrun "$STUDY" &> "log.Allrun.${STUDY}"
