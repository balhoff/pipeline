# cd pipeline_dir
# docker pull phenoscape/pipeline-tools:latest

# Usage example
# ./run.sh make all

docker run --volume "$(pwd)":/pipeline --workdir /pipeline --rm -ti phenoscape/pipeline-tools "$@"

