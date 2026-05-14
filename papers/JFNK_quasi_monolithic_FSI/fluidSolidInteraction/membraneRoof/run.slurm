#!/bin/bash
#SBATCH --job-name=membraneRoof
#SBATCH --output=log.%x_%j.out
#SBATCH --error=log.%x_%j.err
#SBATCH --partition=main
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --time=24:00:00

cd "$SLURM_SUBMIT_DIR"

. /usr/lib/openfoam/openfoam2512/etc/bashrc

export SOLIDS4FOAM_ROOT="${SOLIDS4FOAM_ROOT:-/home/philipc/OpenFOAM/philipc-v2512/solids4foam.monolithic}"

# Campaign controls can be overridden at submission time, e.g.
#   sbatch --export=ALL,STUDY=time,DT_VALUES="0.04 0.02 0.01" run.slurm
: "${STUDY:=mesh}"

./Allrun "$STUDY" &> "log.Allrun.${STUDY}"
