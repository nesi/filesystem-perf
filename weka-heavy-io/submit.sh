#!/bin/bash

# Configure job parameters
NODES=6          # Number of nodes to use
TASKS_PER_NODE=1 # Number of tasks per node
TIME="01:00:00"  # Maximum job runtime
PARTITION="genoa2"  # Specify your slurm partition

# Submit the job
sbatch \
  --nodes=${NODES} \
  --ntasks-per-node=${TASKS_PER_NODE} \
  --time=${TIME} \
  --partition=${PARTITION} \
  io_test_script.sh

echo "Job submitted. Check queue with 'squeue' and results in weka_io_test_*.out files"
