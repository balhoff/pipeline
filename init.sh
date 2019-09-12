#!/usr/bin/env bash

#Covenience script to run the job

#Note:
##squeue -u spshriva ##to check the machine ip on which job is being run
##error-<id> - file containing error log
##slurm-<id>.out - contains output log

source ./env.sh
sbatch --mail-user=spshriva@renci.org ./slurm-script/kb_init.sh
