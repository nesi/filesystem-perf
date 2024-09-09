#!/bin/bash -e

#SBATCH --job-name=advanced_io_test
#SBATCH --output=slog/io_test_%j.out
#SBATCH --time=00:15:00
#SBATCH --nodes=4
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1

# Load necessary modules (adjust as needed for your system)
module load Python/3.11.6-foss-2023a

# Run the advanced I/O measurement script
bash ./io_serial_parallel.sh

# Preprocess the data file
awk '
BEGIN {
    FS=" "
    OFS=","
    print "Timestamp,Operation,Speed"
}
{
    if (NF >= 4) {
        timestamp = $1 " " $2
        operation = $3 " " $4
    }
    if (NF == 2 && $2 ~ /[GM]B\/s/) {
        speed = $1
        if ($2 == "MB/s") {
            speed = speed / 1000
        }
        if (timestamp != "" && operation != "" && speed != "") {
            print timestamp, operation, speed
        }
    }
}' io_measurements.txt > io_measurements_processed.csv

# Debug: Display the contents of io_measurements_processed.csv
echo "Contents of io_measurements_processed.csv:"
cat io_measurements_processed.csv

# Run the Python plotting script
python plot_io_performance.py

echo "Job completed. Check io_performance.png for the plot."
