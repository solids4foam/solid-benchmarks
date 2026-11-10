#!/usr/bin/env bash
#SBATCH --job-name=cook_norm
#SBATCH --output=slurm-%x-%j.out
#SBATCH --error=slurm-%x-%j.err
#SBATCH --partition=long
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --time=7-00:00:00

set -euo pipefail

cd "${SLURM_SUBMIT_DIR:?submit this script with sbatch}"
export OMP_NUM_THREADS=${SLURM_CPUS_PER_TASK:-1}

if [[ -n "${OPENFOAM_MODULE:-}" ]]
then
    module load "$OPENFOAM_MODULE"
fi

: "${OPENFOAM_BASHRC:?export OPENFOAM_BASHRC for the HPC OpenFOAM installation}"
: "${SOLIDS4FOAM_SOURCE:?export SOLIDS4FOAM_SOURCE for the matching solids4foam checkout}"

set +u
# shellcheck disable=SC1090
source "$OPENFOAM_BASHRC"
set -u

target=${COOKS_TARGET:-}
arguments=()
if [[ -n "$target" ]]
then
    arguments+=("$target")
fi

echo "Cook's membrane campaign started at $(date -Iseconds)"
echo "Host: $(hostname)"
echo "OpenFOAM: ${WM_PROJECT_VERSION:-unknown}"
echo "solids4foam source: $SOLIDS4FOAM_SOURCE"
echo "Target: ${target:-all}"

./Allrun "${arguments[@]}" > "log.Allrun.${SLURM_JOB_ID}" 2>&1

echo "Cook's membrane campaign completed at $(date -Iseconds)"
