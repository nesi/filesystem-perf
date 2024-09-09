#!/bin/bash -e
#SBATCH --job-name=io_measurement
#SBATCH --output=slog/io_measurement_%j.out
#SBATCH --time=00:15:00
#SBATCH --nodes=1
#SBATCH --ntasks=1


# Run the I/O measurement script
./io_measure.sh

# Preprocess the data file
awk '{
    gsub(/GB\/s/, "", $4); 
    gsub(/MB\/s/, "", $4); 
    if ($4 ~ /MB/) $4 = $4/1000; 
    gsub(/GB\/s/, "", $7); 
    gsub(/MB\/s/, "", $7); 
    if ($7 ~ /MB/) $7 = $7/1000; 
    print $1, $2, $4, $7
}' io_measurements.txt > io_measurements_processed.txt

# After the measurement is complete, generate a plot using gnuplot
gnuplot <<EOF
set terminal png size 800,600
set output "io_performance.png"
set title "I/O Performance Over Time"
set xlabel "Time"
set ylabel "Speed (GB/s)"
set xdata time
set timefmt "%Y-%m-%d %H:%M:%S"
set format x "%H:%M"
set datafile separator whitespace
set key autotitle columnhead

# Check if the file is empty
if (system("[ -s io_measurements_processed.txt ] && echo 1 || echo 0") == 0) {
    set label "No data available" at screen 0.5,0.5 center
    plot NaN
} else {
    plot "io_measurements_processed.txt" using 1:3 with lines title "Write Speed", \
         "" using 1:4 with lines title "Read Speed"
}
EOF

# Display the contents of the processed file for debugging
echo "Contents of io_measurements_processed.txt:"
cat io_measurements_processed.txt
