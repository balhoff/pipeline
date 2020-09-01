#!/usr/bin/env bash

# Convenience script to launch docker container.
# Launches container and runs command passed in by the user.
# The current working directory is mounted within the container.

# Usage example
# ./run.sh make all

IMAGE_VERSION=v1.4

# cd pipeline_dir
# docker pull phenoscape/pipeline-tools:$IMAGE_VERSION

docker run --volume "$(pwd)":/pipeline --workdir /pipeline --rm -ti --user $(id -u):$(id -g) phenoscape/pipeline-tools:$IMAGE_VERSION "$@"

