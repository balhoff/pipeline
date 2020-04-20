# cd pipeline_dir
# docker pull phenoscape/pipeline-tools:latest

docker run -v "$(pwd)":/pipeline -ti phenoscape/pipeline-tools

# cd ../pipeline
# make all