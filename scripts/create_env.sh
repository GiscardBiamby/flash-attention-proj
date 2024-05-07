#!/bin/bash
set -e

# Get the directory of this script so that we can reference paths correctly no matter which folder
# the script was launched from:
SCRIPTS_DIR="$(builtin cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJ_ROOT="$(realpath "${SCRIPTS_DIR}"/../)"

PYTHON_VERSION=3.8
TORCH_VERSION=2.1.0
ENV_NAME="flash"
# * use export for this one so FORCE_CUDA is set for any sub-processes launched by this script:
export FORCE_CUDA=1
echo "ENV_NAME: ${ENV_NAME}"
echo "hostname: ${HOSTNAME}"

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


##
## Remove env if exists:
set +e
echo ""
echo ""
echo "=========================================================="
CONDA_ENV_DIR=$(conda info | grep -i "envs directories" | sed "s/envs directories : //")
CONDA_ENV_DIR=$(echo "${CONDA_ENV_DIR}" | sed 's/[[:blank:]]//g')
CONDA_ENV_DIR="${CONDA_ENV_DIR}/${ENV_NAME}"
echo "Checking if we need to remove env ('${CONDA_ENV_DIR}')"
if [ -d "${CONDA_ENV_DIR}" ]; then
    echo "removing environment: ${ENV_NAME}"
    $CONDA_FN deactivate && $CONDA_FN env remove --name "${ENV_NAME}" -y || true
    echo "deleting ${CONDA_ENV_DIR}"
    rm -rf "${CONDA_ENV_DIR}" || true
fi
echo "Finished removing env"
ls -lah "${CONDA_ENV_DIR}" || true
set -e


##
## Create env:
echo ""
echo ""
echo "=========================================================="
echo "Creating conda env: ${ENV_NAME}"
$CONDA_FN create --name "${ENV_NAME}" python=="${PYTHON_VERSION}" setuptools pip wheel ninja cython -y
$CONDA_FN activate "${ENV_NAME}"
$CONDA_FN install conda-libmamba-solver -y
echo "Current environment: "
$CONDA_FN info --envs | grep "*"

##
## Base dependencies
echo ""
echo ""
echo "=========================================================="
echo "Installing requirements..."

function install_pytorch_cuda() {
    echo "Installing pytorch"
    $CONDA_FN install \
        pytorch[build=*cuda*,channel=pytorch,version="${TORCH_VERSION}"] \
        pytorch-cuda==12.1 \
        torchaudio \
        torchvision \
        -c pytorch -c nvidia --solver=libmamba -y
}
install_pytorch_cuda


##
## Custom dependencies
## Move to project root
pushd "${PROJ_ROOT}"

echo ""
echo ""
echo "=========================================================="
echo "Installing requirements_gb.txt..."
## Install this repo (llarva):
pip install -r requirements_gb.txt
# Make the python environment available for running jupyter kernels:
python -m ipykernel install --user --name="${ENV_NAME}"


echo ""
echo ""
echo "=========================================================="
echo "Installing flash-attention..."
# * These are defined in setup.py, and the comments come from there:

# * FLASH_ATTENTION_FORCE_BUILD: Force a fresh build locally, instead of attempting to find prebuilt
# * wheels (Default: FALSE)
export FLASH_ATTENTION_FORCE_BUILD="TRUE"

# * SKIP_CUDA_BUILD: Intended to allow CI to use a simple `python setup.py sdist` run to
# * copy over raw files, without any cuda compilation (Default: FALSE)
export FLASH_ATTENTION_SKIP_CUDA_BUILD="FALSE"

# * FLASH_ATTENTION_FORCE_CXX11_ABI: For CI, we want the option to build with C++11 ABI since
# * the nvcr images use C++11 ABI (Default: FALSE)
export FLASH_ATTENTION_FORCE_CXX11_ABI="FALSE"

# * --no-build-isolation: This can be disabled using the --no-build-isolation flag --
# *       users supplying this flag are responsible for ensuring the build environment is
# *       managed appropriately, including ensuring that all required build-time dependencies
# *       are installed, since pip does not manage build-time dependencies when this flag is
# *       passed.
pip install -e . flash-attn --no-build-isolation

popd


## We are done, show the python environment:
$CONDA_FN list

## Check if we can load cuda:
"${PROJ_ROOT}/scripts/env_check.sh"
echo "Done!"
