#!/bin/bash
#
#SBATCH --error=error-%j
#SBATCH --mail-type=ALL
#SBATCH --cpus-per-task=20
#SBATCH --mem=75G

set -e # Abort if any command fails

export JAVA_OPTS="-Xmx70G"

make all