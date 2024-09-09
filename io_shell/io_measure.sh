#!/bin/bash

# Output file
output_file="io_measurements.txt"

# Duration in seconds (10 minutes = 600 seconds)
duration=180

# Interval in seconds
interval=20

# Start time
start_time=$(date +%s)

# Clear the output file
> $output_file

while true; do
    current_time=$(date +%s)
    elapsed=$((current_time - start_time))
    
    if [ $elapsed -ge $duration ]; then
        break
    fi
    
    timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    
    # Measure write speed
    write_speed=$(dd if=/dev/zero of=testfile bs=1M count=1024 conv=fdatasync 2>&1 | awk '/copied/ {print $0}' | sed 's/,//g' | awk '{print $8 " " $9}')
    
    # Measure read speed
    read_speed=$(dd if=testfile of=/dev/null bs=1M count=1024 2>&1 | awk '/copied/ {print $0}' | sed 's/,//g' | awk '{print $8 " " $9}')
    
    echo "$timestamp Write: $write_speed Read: $read_speed" >> $output_file
    
    sleep $interval
done

# Clean up
rm testfile