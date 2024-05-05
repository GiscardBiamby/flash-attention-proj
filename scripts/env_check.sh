#!/bin/bash
set -e

# Get the directory of this script so that we can reference paths correctly no matter which folder
# the script was launched from:
SCRIPTS_DIR="$(builtin cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJ_ROOT="$(realpath "${SCRIPTS_DIR}"/../)"

PYTHON_VERSION=3.10
ENV_NAME="flash"
# use export for this one so FORCE_CUDA is set for any sub-processes launched by this script:
export FORCE_CUDA=1
echo "ENV_NAME: ${ENV_NAME}"

# Feel free to customize this section, but this setup just picks the first comda or mamba
# installation tht it finds in the following order:
if [[ -d "${HOME}/mambaforge" ]]; then
    ## If you use mamba:
    CONDA_FN="mamba"
    CONDA_DIR="${HOME}/mambaforge"
elif [[ -d "${HOME}/anaconda3" ]]; then
    ## If you use conda on a normal (local) computer:
    CONDA_FN="conda"
    CONDA_DIR="${HOME}/anaconda3"
elif [[ -d "/global/common/software/nersc/pm-2022q3/sw/python/3.9-anaconda-2021.11" ]]; then
    ## If you use conda on an HPC cluster:
    CONDA_FN="conda"
    CONDA_DIR="/global/common/software/nersc/pm-2022q3/sw/python/3.9-anaconda-2021.11"
fi

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
## Activate env:
$CONDA_FN activate "${ENV_NAME}"
echo "Current environment: "
$CONDA_FN info --envs | grep "*"

## Show the python environment:
$CONDA_FN list

## Print env vars:
env

## Check if we can load cuda:
echo "Doing a quick check for torch.cuda:"
python -c "import torch; print('torch.cuda.is_available: ', torch.cuda.is_available())"

## Check if we can load cuda:
# echo "Check for llava module:"
# python -c "import llava; print('llava.file: ', llava.__file__)"


echo "Done!"
