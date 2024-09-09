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

# Generate plot using gnuplot
gnuplot <<EOF
set terminal png size 1200,900
set output "io_performance.png"
set title "I/O Performance Over Time"
set xlabel "Time"
set ylabel "Speed (GB/s)"
set xdata time
set timefmt "%Y-%m-%d %H:%M:%S"
set format x "%H:%M"
set datafile separator whitespace
set key autotitle columnhead
set key outside right
set style data linespoints

plot "io_measurements_processed.txt" using 1:(\$3 eq "Serial" && \$4 eq "Write:" ? \$5 : 1/0) title "Serial Write" lc rgb "red", \
     "" using 1:(\$3 eq "Serial" && \$4 eq "Read:" ? \$5 : 1/0) title "Serial Read" lc rgb "blue", \
     "" using 1:(\$3 eq "Parallel" && \$4 eq "Write:" ? \$5 : 1/0) title "Parallel Write" lc rgb "green", \
     "" using 1:(\$3 eq "Parallel" && \$4 eq "Read:" ? \$5 : 1/0) title "Parallel Read" lc rgb "purple"
EOF

echo "Plot generated: io_performance.png"