#!/usr/bin/env bash
# Test makefile with dummy programs.
# This script should be run from the base directory of this repo.

# stop if a command fails (non-zero exit status)
set -e

# if this script fails show a message with the line number 
SCRIPTNAME=$0
trap 'echo "ERROR on line $LINENO of $SCRIPTNAME"' ERR

# Put fake bin scripts first in the PATH
export PATH=$(pwd)/test/bin:$PATH

# start with a clean slate
make clean

# Run make to create our files
make all

# Check that the major files were created
echo "Checking that build/phenoscape-kb.ttl exists"
test -f build/phenoscape-kb.ttl

echo "Checking that build/phenoscape-kb-tbox-hierarchy.ttl exists"
test -f build/phenoscape-kb-tbox-hierarchy.ttl

echo "Checking that build/blazegraph-loaded-all.jnl exists"
test -f build/blazegraph-loaded-all.jnl


# Run make a second time
SECOND_TIME_OUTPUT=$(make all)

echo "Checking that second 'make all' found nothing to be done"
# grep will exit with 1 if nothing is found
echo $SECOND_TIME_OUTPUT | grep 'Nothing to be done'

echo ""
echo "SUCCESS: Makefile tests passed."
echo ""
