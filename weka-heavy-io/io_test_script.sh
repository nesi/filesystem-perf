#!/bin/bash
#SBATCH --job-name=weka_io_test
#SBATCH --output=weka_io_test_%j.out
#SBATCH --error=weka_io_test_%j.err
#SBATCH --ntasks-per-node=1
#SBATCH --nodes=4         # Modify this to match your cluster size
#SBATCH --time=01:00:00   # Adjust time limit as needed

# Get node-specific variables
NODE_ID=$SLURM_NODEID
TOTAL_NODES=$SLURM_NNODES
JOB_ID=$SLURM_JOB_ID

# Create a unique test directory for this job
BASE_DIR="/nesi/nobackup/nesi99999/dsen018-test/heavy-io-output"  # Change this to your Weka filesystem mount point
TEST_DIR="${BASE_DIR}/io_test_${JOB_ID}"

# Settings for the I/O test
FILES_PER_NODE=500000          # Adjust to reach your target of few million files
FILE_SIZE=4K                   # Size of each file
READ_SAMPLE_PERCENTAGE=5       # Percentage of files to read after creation

echo "Starting I/O test on node ${NODE_ID} of ${TOTAL_NODES} at $(date)"

# Create node-specific directory
NODE_DIR="${TEST_DIR}/node_${NODE_ID}"
mkdir -p ${NODE_DIR}

echo "Creating ${FILES_PER_NODE} files in ${NODE_DIR}"

# Function to create files in parallel
create_files() {
    local start=$1
    local end=$2
    local dir=$3
    
    for ((i=start; i<=end; i++)); do
        dd if=/dev/urandom of="${dir}/file_${i}.dat" bs=${FILE_SIZE} count=1 status=none
    done
}

# Determine number of parallel processes based on CPU cores
NUM_CORES=$(nproc)
FILES_PER_CORE=$((FILES_PER_NODE / NUM_CORES))

# Create files in parallel
for ((core=0; core<NUM_CORES; core++)); do
    START=$((core * FILES_PER_CORE + 1))
    END=$(((core + 1) * FILES_PER_CORE))
    create_files $START $END ${NODE_DIR} &
done

# Wait for all background processes to complete
wait

echo "Finished creating files on node ${NODE_ID} at $(date)"

# Sync to ensure all files are written to disk
sync

# Barrier to make sure all nodes have finished creating files
srun --ntasks=${TOTAL_NODES} /bin/true

# Read some files as a test
echo "Starting to read files on node ${NODE_ID} at $(date)"
FILES_TO_READ=$((FILES_PER_NODE * READ_SAMPLE_PERCENTAGE / 100))

# Read random files
for ((i=0; i<FILES_TO_READ; i++)); do
    RANDOM_FILE_NUM=$((RANDOM % FILES_PER_NODE + 1))
    cat "${NODE_DIR}/file_${RANDOM_FILE_NUM}.dat" > /dev/null
done

echo "Finished reading ${FILES_TO_READ} files on node ${NODE_ID} at $(date)"

# Optional: Clean up files (comment out if you want to keep the files)
#echo "Cleaning up files on node ${NODE_ID}"
#rm -rf ${NODE_DIR}

echo "I/O test completed on node ${NODE_ID} at $(date)"

# Collect and report performance statistics if needed
# You can add code here to collect and report statistics

exit 0
