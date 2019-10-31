#!/usr/bin/env bash

#Covenience script to run the job

#Note:
##squeue -u spshriva ##to check the machine ip on which job is being run
##error-<id> - file containing error log
##slurm-<id>.out - contains output log

if [ $# -eq 0 ]
    then
        echo "No arguments supplied. Pass in user email address."
        exit 1
fi


source ./env.sh

#Take email address as argument
sbatch --mail-user=$1 ./slurm-script/kb_init.sh
