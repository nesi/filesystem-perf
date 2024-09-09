#!/bin/bash -e

#SBATCH --job-name=advanced_io_test
#SBATCH --output=slog/io_test_%j.out
#SBATCH --time=00:15:00
#SBATCH --nodes=4
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1

# Load necessary modules (adjust as needed for your system)
module load OpenMPI

# Run the advanced I/O measurement script
bash ./advanced_io_test.sh

# Preprocess the data file
awk '{
    gsub(/GB\/s/, "", $5); 
    gsub(/MB\/s/, "", $5); 
    if ($5 ~ /MB/) $5 = $5/1000; 
    print $1, $2, $3, $5
}' io_measurements.txt > io_measurements_processed.txt

# Run the Python plotting script
python plot_io_performance.py

echo "Job completed. Check io_performance.png for the plot."