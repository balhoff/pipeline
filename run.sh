#!/usr/bin/env bash
#SBATCH --mem=80G
#SBATCH --cpus-per-task=40

# Convenience script to launch docker container.
# Launches container and runs command passed in by the user.
# The current working directory is mounted within the container.

# Usage example
# ./run.sh make all
# or
# sbatch run.sh make all

IMAGE_VERSION=v1.5.2
DOCKER_IMAGE=phenoscape/pipeline-tools:$IMAGE_VERSION 

# cd pipeline_dir
# docker pull phenoscape/pipeline-tools:$IMAGE_VERSION

if [ -z "$SLURM_JOB_ID" ]
then
    docker run --volume "$(pwd)":/pipeline --workdir /pipeline --rm -ti --user $(id -u):$(id -g) $DOCKER_IMAGE "$@"
else
    # When run as part of a Slurm job (SLURM_JOB_ID is set)
    # use singularity because docker isn't cluster safe.
    singularity run --bind "$(pwd)":/pipeline --pwd /pipeline docker://$DOCKER_IMAGE "$@"
fi

