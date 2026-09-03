#!/bin/bash
#SBATCH --job-name=cavityFlexibleBottom
#SBATCH --output=log.%x_%j.out
#SBATCH --error=log.%x_%j.err
#SBATCH --partition=main
#SBATCH --ntasks=48
#SBATCH --cpus-per-task=1
#SBATCH --time=12:00:00

# Good practice to navigate to the submission directory
cd $SLURM_SUBMIT_DIR

# Load OpenFOAM
source /usr/lib/openfoam/openfoam2512/etc/bashrc
#source /usr/lib/openfoam/openfoam2412/etc/bashrc
#source /usr/lib/openfoam/openfoam2312/etc/bashrc
#source /usr/lib/openfoam/openfoam2212/etc/bashrc
#source /usr/lib/openfoam/openfoam2112/etc/bashrc

# Set number of threads for programs that use OpenMP parallelisation
# Note that OMP_NUM_THREADS defaults to 1 if not set
#export OMP_NUM_THREADS=$SLURM_CPUS_PER_TASK
#export OMP_NUM_THREADS=10

# Campaign controls can be overridden at submission time, e.g.
#   sbatch --export=ALL,STUDY=time,METHODS="monolithic:default partitioned:IQNILS" run.slurm
: "${STUDY:=mesh}"
: "${TOTAL_CORES:=${SLURM_NTASKS:-1}}"

# Execute the run script
TOTAL_CORES="$TOTAL_CORES" ./Allrun "$STUDY" &> "log.Allrun.${STUDY}"
