#!/bin/bash
#SBATCH --job-name=gpfs_test
#SBATCH --output=%j.out
#SBATCH --time=02:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16  # Adjust based on your max thread count

module purge
module use ~/modules/all/
module load fio
module load libaio/0.3.113-GCCcore-12.3.0
# Load necessary modules (adjust for your system)


# Configuration
TEST_DIR="${PWD}/testdir"
FILE_SIZE="10G"
BLOCK_SIZES=("1M" "4M" "8M" "16M")
NUM_THREADS=(1 4 8 16)
TEST_DURATION=60
OUTPUT_DIR="$SLURM_SUBMIT_DIR/gpfs_results_${SLURM_JOB_ID}"

# Create output directory
mkdir -p $OUTPUT_DIR
mkdir -p $TEST_DIR

# Function to format sizes to human-readable
format_size() {
    local bytes=$1
    if [[ $bytes -gt 1073741824 ]]; then
        echo "$(awk "BEGIN {printf \"%.2f\", $bytes/1073741824}") GB/s"
    else
        echo "$(awk "BEGIN {printf \"%.2f\", $bytes/1048576}") MB/s"
    fi
}

# Function to run FIO test and parse results
run_fio_test() {
    local bs=$1
    local threads=$2
    local test_type=$3
    local result_file="$OUTPUT_DIR/result_${test_type}_${bs}_${threads}.json"
    
    echo "===========================================" | tee -a $OUTPUT_DIR/summary.txt
    echo "Test: $test_type | Block Size: $bs | Threads: $threads" | tee -a $OUTPUT_DIR/summary.txt
    echo "===========================================" | tee -a $OUTPUT_DIR/summary.txt
    
    # Run fio command as a single line without backslashes
    fio --name=gpfs_test --directory=$TEST_DIR --size=$FILE_SIZE --time_based --runtime=$TEST_DURATION --ioengine=psync --direct=1 --verify=0 --bs=$bs --rw=$test_type --numjobs=$threads --group_reporting --filename_format="f.\$jobnum.dat" --output-format=json --output="$result_file"

    # Check if the test ran successfully
    if [ -f "$result_file" ]; then
        local file_size=$(stat -f %z "$result_file" 2>/dev/null || stat -c %s "$result_file" 2>/dev/null)
        if [ "$file_size" -lt 100 ]; then
            echo "Warning: Test might not have run properly. Output file is too small." | tee -a $OUTPUT_DIR/summary.txt
        fi
    else
        echo "Error: Test failed to produce output file" | tee -a $OUTPUT_DIR/summary.txt
    fi

    # Parse and display results if file exists
    if [ -f "$result_file" ]; then
        local read_bw=$(jq '.jobs[0].read.bw' $result_file 2>/dev/null)
        local write_bw=$(jq '.jobs[0].write.bw' $result_file 2>/dev/null)
        local read_iops=$(jq '.jobs[0].read.iops' $result_file 2>/dev/null)
        local write_iops=$(jq '.jobs[0].write.iops' $result_file 2>/dev/null)
        
        {
            echo "Results:"
            [ ! -z "$read_bw" ] && [ "$read_bw" != "0" ] && \
                echo "Read Bandwidth: $(format_size $read_bw)"
            [ ! -z "$write_bw" ] && [ "$write_bw" != "0" ] && \
                echo "Write Bandwidth: $(format_size $write_bw)"
            [ ! -z "$read_iops" ] && [ "$read_iops" != "0" ] && \
                echo "Read IOPS: $read_iops"
            [ ! -z "$write_iops" ] && [ "$write_iops" != "0" ] && \
                echo "Write IOPS: $write_iops"
            echo ""
        } | tee -a $OUTPUT_DIR/summary.txt
    fi
}



# Modified version of the relevant section
{
    echo "=== GPFS Performance Test Results ===="
    echo "Job ID: $SLURM_JOB_ID"
    echo "Node: $SLURM_NODELIST"
    echo "Start Time: $(date)"
    echo ""
    echo "=== System Information ===="
    
    # Only run GPFS commands if we have access
    if command -v mmlsconfig &> /dev/null && [ -x "$(command -v mmlsconfig)" ]; then
        echo "GPFS Version: $(mmlsconfig | grep version)"
    else
        echo "GPFS Version: Unable to determine (requires GPFS command access)"
    fi
    
    if command -v mmlsnode &> /dev/null && [ -x "$(command -v mmlsnode)" ]; then
        echo "Client Info: $(mmlsnode -L)"
    else
        echo "Client Info: Unable to determine (requires GPFS command access)"
    fi
    
    echo "Mount Info: $(mount | grep gpfs)"
    echo "CPU Info: $(lscpu | grep "Model name")"
    echo "Memory Info: $(free -h | grep "Mem:")"
    echo ""
} | tee $OUTPUT_DIR/summary.txt

# Try to drop cache only if we have permission
echo "Cache control..." | tee -a $OUTPUT_DIR/summary.txt
if [ -w "/proc/sys/vm/drop_caches" ]; then
    sync
    echo 3 > /proc/sys/vm/drop_caches
    echo "Cache dropped successfully" | tee -a $OUTPUT_DIR/summary.txt
else
    echo "Warning: Cannot drop cache (requires root privileges)" | tee -a $OUTPUT_DIR/summary.txt
fi

# Run tests
echo "Starting performance tests..." | tee -a $OUTPUT_DIR/summary.txt

# Sequential Write Tests
for bs in "${BLOCK_SIZES[@]}"; do
    for threads in "${NUM_THREADS[@]}"; do
        run_fio_test $bs $threads "write"
    done
done

# Sequential Read Tests
for bs in "${BLOCK_SIZES[@]}"; do
    for threads in "${NUM_THREADS[@]}"; do
        run_fio_test $bs $threads "read"
    done
done

# Random Read/Write Tests
for bs in "${BLOCK_SIZES[@]}"; do
    for threads in "${NUM_THREADS[@]}"; do
        run_fio_test $bs $threads "randrw"
    done
done

# Modify the metadata test to use correct rw type
run_metadata_test() {
    echo "=== Metadata Performance Test ===" | tee -a $OUTPUT_DIR/summary.txt
    local metadata_result="$OUTPUT_DIR/result_metadata.json"
    
    fio --name=metadata --directory=$TEST_DIR --size=4k --nrfiles=10000 --rw=randwrite --ioengine=psync --output-format=json --output="$metadata_result"
    
    if [ -f "$metadata_result" ]; then
        echo "Metadata test completed. Results in $metadata_result" | tee -a $OUTPUT_DIR/summary.txt
    else
        echo "Error: Metadata test failed to produce output file" | tee -a $OUTPUT_DIR/summary.txt
    fi
}
# Add verification that tests are running for expected duration
verify_runtime() {
    local start_time=$(date +%s)
    local test_name=$1
    
    # Run your test command here
    $2
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    if [ $duration -lt $((TEST_DURATION - 5)) ]; then
        echo "Warning: $test_name completed in $duration seconds, which is less than expected ($TEST_DURATION seconds)" | tee -a $OUTPUT_DIR/summary.txt
    fi
}
# Clean up test files
rm -f $TEST_DIR/f_*.dat

# Final summary
echo "=== Test Complete ===" | tee -a $OUTPUT_DIR/summary.txt
echo "Results directory: $OUTPUT_DIR" | tee -a $OUTPUT_DIR/summary.txt
echo "Summary file: $OUTPUT_DIR/summary.txt" | tee -a $OUTPUT_DIR/summary.txt
echo "End Time: $(date)" | tee -a $OUTPUT_DIR/summary.txt
