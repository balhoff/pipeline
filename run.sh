#!/usr/bin/env bash

# Convenience script to launch docker container
# Launches container with interactive bash shell
# And runs command passed in by the user

# Usage example
# ./run.sh make all

IMAGE_VERSION=v1.0.2

# cd pipeline_dir
# docker pull phenoscape/pipeline-tools:$IMAGE_VERSION

docker run --volume "$(pwd)":/pipeline --workdir /pipeline --rm -ti phenoscape/pipeline-tools:$IMAGE_VERSION "$@"

