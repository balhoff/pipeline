#!/bin/bash
#
#SBATCH --error=error-%j
#SBATCH --mail-type=ALL
#SBATCH --cpus-per-task=32
#SBATCH --mem=250G
#SBATCH --constraint=broadwell
set -e # Abort if any command fails

export JAVA_OPTS="-Xmx120G"

make build/subclass-closure.ttl
