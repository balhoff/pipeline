#!/bin/bash
#
#SBATCH --error=error-%j
#SBATCH --mail-type=ALL
#SBATCH --cpus-per-task=32
#SBATCH --mem=250G
#SBATCH --constraint=broadwell

set -e # Abort if any command fails

export JAVA_OPTS="-Xmx80G"

source ~/softwares/python-virtual-environments/env3/bin/activate

#pip install -r ./resources/requirements.txt

make -j 4 all
