#!/bin/bash

# Function to run serial write test
serial_write_test() {
    local size=$1
    local file="serial_write_test.tmp"
    echo "Running serial write test (${size}M)..."
    dd if=/dev/zero of=$file bs=1M count=$size conv=fdatasync 2>&1 | awk '/copied/ {print $0}' | sed 's/,//g' | awk '{print $8 " " $9}'
    rm $file
}

# Function to run serial read test
serial_read_test() {
    local size=$1
    local file="serial_read_test.tmp"
    dd if=/dev/zero of=$file bs=1M count=$size conv=fdatasync &>/dev/null
    echo "Running serial read test (${size}M)..."
    dd if=$file of=/dev/null bs=1M count=$size 2>&1 | awk '/copied/ {print $0}' | sed 's/,//g' | awk '{print $8 " " $9}'
    rm $file
}

# Function to run parallel write test using MPI
parallel_write_test() {
    local size=$1
    local nodes=$2
    local file="parallel_write_test.tmp"
    echo "Running parallel write test (${size}M, ${nodes} nodes)..."
    mpirun -n $nodes dd if=/dev/zero of=$file bs=1M count=$((size/nodes)) conv=fdatasync 2>&1 | awk '/copied/ {print $0}' | sed 's/,//g' | awk '{sum+=$8} END {print sum " " $9}'
    rm $file
}

# Function to run parallel read test using MPI
parallel_read_test() {
    local size=$1
    local nodes=$2
    local file="parallel_read_test.tmp"
    dd if=/dev/zero of=$file bs=1M count=$size conv=fdatasync &>/dev/null
    echo "Running parallel read test (${size}M, ${nodes} nodes)..."
    mpirun -n $nodes dd if=$file of=/dev/null bs=1M count=$((size/nodes)) 2>&1 | awk '/copied/ {print $0}' | sed 's/,//g' | awk '{sum+=$8} END {print sum " " $9}'
    rm $file
}

# Main test function
run_io_tests() {
    local size=$1
    local nodes=$2
    local output_file=$3

    echo "$(date '+%Y-%m-%d %H:%M:%S') Serial Write: $(serial_write_test $size)" >> $output_file
    echo "$(date '+%Y-%m-%d %H:%M:%S') Serial Read: $(serial_read_test $size)" >> $output_file
    echo "$(date '+%Y-%m-%d %H:%M:%S') Parallel Write: $(parallel_write_test $size $nodes)" >> $output_file
    echo "$(date '+%Y-%m-%d %H:%M:%S') Parallel Read: $(parallel_read_test $size $nodes)" >> $output_file
}

# Configuration
FILE_SIZE=1024  # Size in MB
NUM_NODES=4     # Number of nodes for parallel tests
OUTPUT_FILE="io_measurements.txt"
DURATION=600    # Total duration in seconds
INTERVAL=30     # Interval between tests in seconds

# Main loop
start_time=$(date +%s)
> $OUTPUT_FILE  # Clear the output file

while true; do
    current_time=$(date +%s)
    elapsed=$((current_time - start_time))
    
    if [ $elapsed -ge $DURATION ]; then
        break
    fi
    
    run_io_tests $FILE_SIZE $NUM_NODES $OUTPUT_FILE
    sleep $INTERVAL
done

echo "I/O tests completed. Results saved in $OUTPUT_FILE"