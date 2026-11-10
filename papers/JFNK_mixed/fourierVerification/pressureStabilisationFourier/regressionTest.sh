#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
CASE_DIR="${SCRIPT_DIR}/regressionTests/main"
CHECK_ONLY=false
for arg in "$@"; do
    case "$arg" in
        --check-only|--no-run) CHECK_ONLY=true ;;
        *) echo "Unknown option: $arg" >&2; exit 1 ;;
    esac
done
source solids4FoamScripts.sh

prepare_case()
{
    rm -rf "${CASE_DIR}"
    mkdir -p "${CASE_DIR}"
    for item in "${SCRIPT_DIR}"/*; do
        base_item=$(basename "${item}")
        case "$base_item" in
            regressionTests|postProcessing|log.*) continue ;;
        esac
        cp -a "$item" "${CASE_DIR}/"
    done
}

if [ "$CHECK_ONLY" = false ]; then
    prepare_case
    (cd "${CASE_DIR}" && ./Allclean > /dev/null 2>&1)
    (cd "${CASE_DIR}" && ./Allrun > log.Allrun 2>&1)
fi
if solids4Foam::regressionCaseSkipped "${CASE_DIR}/log.Allrun"; then
    echo "SKIP: pressureStabilisationFourier is not supported in this OpenFOAM flavour"
    exit 0
fi
python3 "${SCRIPT_DIR}/checkResults.py" "${CASE_DIR}/postProcessing/stabilisationFourierCheck"
