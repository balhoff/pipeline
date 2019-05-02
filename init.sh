#!/usr/bin/env bash

#squeue -u spshriva ##to check the machine ip on which job is being run
#error-<id> - file containing error log
#slurm-<id>.out - contains output log

sbatch --mail-user=spshriva@renci.org ./slurm-script/kb_init.sh
