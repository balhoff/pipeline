#!/usr/bin/env bash
#SBATCH --mem=80G
#SBATCH --cpus-per-task=40

IMAGE_VERSION=v1.5.2
DOCKER_IMAGE=phenoscape/pipeline-tools:$IMAGE_VERSION

set -e # Abort if any command fails

TEST_DIR="test/test1"
BUILD_DIR="build"

# Ensure an empty build directory
if [ -e $BUILD_DIR ]
then
    rm -rf $BUILD_DIR
fi
mkdir $BUILD_DIR
mkdir $BUILD_DIR/mirror

# Copy test files into the build directory
cp $TEST_DIR/test1-bio-ontologies-merged.ofn $BUILD_DIR/bio-ontologies-merged.ofn
cp $TEST_DIR/test1-ontology-metadata.ttl $BUILD_DIR/ontology-metadata.ttl
cp -a $TEST_DIR/nexml-data/. $BUILD_DIR/test-phenoscape-data/


NEXMLS=$(find $BUILD_DIR/test-phenoscape-data -type f -name "*.xml")
#echo $NEXMLS
export NEXMLS

NEXML_DATA=$BUILD_DIR/test-phenoscape-data
#echo $NEXML_DATA
export NEXML_DATA

make -e $BUILD_DIR/phenex-data+tbox.ttl

IMAGE_VERSION=v1.5.2
DOCKER_IMAGE=phenoscape/pipeline-tools:$IMAGE_VERSION 
singularity run --bind "$(pwd)":/pipeline --pwd /pipeline docker://$DOCKER_IMAGE make -e $BUILD_DIR/phenex-data+tbox.ttl
