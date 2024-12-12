#!/bin/bash

# GPFS Waiter Monitoring Script
# This script monitors processes for D state and GPFS-related waiting

LOG_DIR="/path/to/logs"
INTERVAL=5  # Monitoring interval in seconds
GPFS_MOUNT="/scratch OR /persistent"  # Adjust to your GPFS mount point

mkdir -p "$LOG_DIR"

monitor_process() {
    local pid=$1
    local process_name=$2
    local logfile="${LOG_DIR}/gpfs_monitor_${pid}.log"
    
    echo "Starting monitoring for PID $pid ($process_name)" >> "$logfile"
    
    while kill -0 $pid 2>/dev/null; do
        # Check process state
        proc_state=$(ps -o state= -p $pid)
        
        if [[ "$proc_state" == "D" ]]; then
            echo "$(date '+%Y-%m-%d %H:%M:%S') - Process $pid in D state" >> "$logfile"
            
            # Collect detailed information
            echo "Process Stack:" >> "$logfile"
            cat /proc/$pid/stack >> "$logfile" 2>/dev/null
            
            # Check GPFS-specific information
            echo "GPFS I/O Statistics:" >> "$logfile"
            mmfsadm dump waiters >> "$logfile" 2>/dev/null
            
            # Check for file handles
            echo "Open Files:" >> "$logfile"
            lsof -p $pid >> "$logfile" 2>/dev/null
            
            # Check GPFS tokens
            echo "GPFS Tokens:" >> "$logfile"
            mmfsadm dump tokens >> "$logfile" 2>/dev/null
            
            # System I/O stats
            echo "I/O Stats:" >> "$logfile"
            iostat -x 1 1 >> "$logfile"
        fi
        
        sleep $INTERVAL
    done
}

monitor_pipeline() {
    # Monitor all processes accessing GPFS
    while true; do
        lsof "$GPFS_MOUNT" | awk '{print $2}' | grep -v PID | sort -u | while read pid; do
            if ! ps -p $pid > /dev/null; then
                continue
            fi
            
            # Check if we're already monitoring this PID
            if ! pgrep -f "monitor_process $pid" > /dev/null; then
                process_name=$(ps -p $pid -o comm=)
                monitor_process "$pid" "$process_name" &
            fi
        done
        sleep $INTERVAL
    done
}

# Cleanup function
cleanup() {
    echo "Cleaning up monitoring processes..."
    pkill -f "monitor_process"
    exit 0
}

trap cleanup SIGINT SIGTERM

# Start monitoring
monitor_pipeline