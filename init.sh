#!/usr/bin/env bash

#squeue -u spshriva ##to check the machine ip on which job is being run
#error - file containing error log
#slurm<id>.out - contains output log

sbatch --mail-user=spshriva@renci.org kb_init.sh
