# cd pipeline_dir
# docker pull phenoscape/pipeline-tools:latest

docker run --volume "$(pwd)":/pipeline --workdir /pipeline --rm -ti phenoscape/pipeline-tools "$@"

# cd ../pipeline
# make all