#!/bin/bash
#
#SBATCH --error=error-%j
#SBATCH --mail-type=ALL
#SBATCH --cpus-per-task=32
#SBATCH --mem=250G
#SBATCH --constraint=broadwell
set -e # Abort if any command fails

export JAVA_OPTS="-Xmx120G"
source /home/spshriva/softwares/python-virtual-environments/env3/bin/activate

make all

