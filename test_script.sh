#!/usr/bin/env bash


TEST_DIR="test/test1"
BUILD_DIR="build"
# MONARCH_DATA="test-monarch-data" #FIXME

#make clean
rm -rf $BUILD_DIR

mkdir $BUILD_DIR
mkdir $BUILD_DIR/mirror
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



