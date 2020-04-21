# Convenience script to launch docker container
# Launches container with interactive bash shell
# And runs command passed in by the user

# Usage example
# ./run.sh make all


# cd pipeline_dir
# docker pull phenoscape/pipeline-tools:latest

docker run --volume "$(pwd)":/pipeline --workdir /pipeline --rm -ti phenoscape/pipeline-tools "$@"

