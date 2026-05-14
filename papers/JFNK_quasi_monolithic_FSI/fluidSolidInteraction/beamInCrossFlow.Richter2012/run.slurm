#!/bin/bash
#SBATCH --job-name=stb.prt+Mono-beamInCrssFlw
#SBATCH --output=log.%x_%j.out
#SBATCH --error=log.%x_%j.err
#SBATCH --partition=main
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --time=24:00:00

# Good practice to navigate to the submission directory
cd $SLURM_SUBMIT_DIR

# Load OpenFOAM and the solids4Foam monolithic build
source /usr/lib/openfoam/openfoam2512/etc/bashrc
export PATH=/home/philipc/OpenFOAM/philipc-v2512/platforms/linux64GccDPInt32Opt/bin:/home/philipc/OpenFOAM/philipc-v2512/solids4foam.monolithic/applications/scripts:$PATH
export LD_LIBRARY_PATH=/home/philipc/OpenFOAM/philipc-v2512/platforms/linux64GccDPInt32Opt/lib:$LD_LIBRARY_PATH

# Set number of threads for programs that use OpenMP parallelisation
# Note that OMP_NUM_THREADS defaults to 1 if not set
#export OMP_NUM_THREADS=$SLURM_CPUS_PER_TASK
#export OMP_NUM_THREADS=10

# Execute the run script
./Allrun "${STUDY:-mesh}" &> log.Allrun.${STUDY:-mesh}
