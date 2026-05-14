#!/bin/bash
#SBATCH --job-name=beamGillebaart2015
#SBATCH --output=log.%x_%j.out
#SBATCH --error=log.%x_%j.err
#SBATCH --partition=main
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --time=24:00:00

cd "$SLURM_SUBMIT_DIR"

# Load OpenFOAM and the solids4Foam monolithic build
source /usr/lib/openfoam/openfoam2512/etc/bashrc
export PATH=/home/philipc/OpenFOAM/philipc-v2512/platforms/linux64GccDPInt32Opt/bin:/home/philipc/OpenFOAM/philipc-v2512/solids4foam.monolithic/applications/scripts:$PATH
export LD_LIBRARY_PATH=/home/philipc/OpenFOAM/philipc-v2512/platforms/linux64GccDPInt32Opt/lib:$LD_LIBRARY_PATH

./Allrun "${STUDY:-mesh}" &> "log.Allrun.${STUDY:-mesh}"
