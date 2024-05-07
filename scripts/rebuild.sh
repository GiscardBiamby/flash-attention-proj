#!/bin/bash

# Get the directory of this script so that we can reference paths correctly no matter which folder
# the script was launched from:
SCRIPTS_DIR="$(builtin cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJ_ROOT="$(realpath "${SCRIPTS_DIR}"/../)"
BUILD_DIR="${PROJ_ROOT}/build"

echo ""
echo ""
echo "=========================================================="
echo "Loading conda..."
export PYTHONPATH=""
unset PYTHONPATH
echo "PYTHONPATH: ${PYTHONPATH}"
CONDA_FN="conda"
if [[ -d "${HOME}/mambaforge" ]]; then
    CONDA_FN="mamba"
    CONDA_DIR="${HOME}/mambaforge"
elif [[ -d "${HOME}/anaconda3" ]]; then
    CONDA_DIR="${HOME}/anaconda3"
elif [[ -d "${HOME}/miniconda3" ]]; then
    CONDA_DIR="${HOME}/miniconda3"
elif [[ -d "/global/common/software/nersc/pm-2022q3/sw/python/3.9-anaconda-2021.11" ]]; then
    ## If you use conda on an HPC cluster:
    CONDA_DIR="/global/common/software/nersc/pm-2022q3/sw/python/3.9-anaconda-2021.11"
fi

echo "CONDA_FN: $CONDA_FN"
echo "CONDA_DIR: $CONDA_DIR"

##
## Activate Conda (or Miniconda, or Mamba)
echo "Sourcing CONDA_FN: '$CONDA_FN' from location: '${CONDA_DIR}'"
if [ -d "${CONDA_DIR}/etc/profile.d" ]; then
    source "${CONDA_DIR}/etc/profile.d/conda.sh"
fi
if [ -f "${CONDA_DIR}/etc/profile.d/mamba.sh" ]; then
    source "${CONDA_DIR}/etc/profile.d/mamba.sh"
fi


export NVCC_THREADS=16
export CUDA_LAUNCH_BLOCKING=1
export CUDA_VISIBLE_DEVICES="7,8"
export TORCH_USE_CUDA_DSA=1

pushd "${PROJ_ROOT}"
mamba activate flash

# * Clean Previous Builds
echo ""
echo "=============================================================================="
echo "Clearing build artifacts..."
# pip uninstall -y flash-attn
# rm -rf "${BUILD_DIR}"
# rm -rf "${PROJ_ROOT}/flash_attn.egg-info"
# rm -rf "${PROJ_ROOT}/flash_attn_2_cuda.cpython-*.so"

# * Build
echo ""
echo "=============================================================================="
echo "Building flash_attn..."
set +e
pip install -e . --no-build-isolation

echo ""
echo "=============================================================================="
echo "Testing flash_attn"
pytest --maxfail=5 -s tests/test_flash_attn.py
