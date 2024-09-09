import matplotlib.pyplot as plt
import pandas as pd
from datetime import datetime

# Read the processed data
df = pd.read_csv('io_measurements_processed.txt', sep=' ', header=None, 
                 names=['Date', 'Time', 'Operation', 'Type', 'Speed'])

# Combine Date and Time columns
df['Timestamp'] = pd.to_datetime(df['Date'] + ' ' + df['Time'])

# Create a new column for the operation type
df['OperationType'] = df['Operation'] + ' ' + df['Type'].str.rstrip(':')

# Create the plot
plt.figure(figsize=(12, 6))

for operation in df['OperationType'].unique():
    data = df[df['OperationType'] == operation]
    plt.plot(data['Timestamp'], data['Speed'], label=operation, marker='o')

plt.title('I/O Performance Over Time')
plt.xlabel('Time')
plt.ylabel('Speed (GB/s)')
plt.legend()
plt.grid(True)

# Rotate and align the tick labels so they look better
plt.gcf().autofmt_xdate()

# Save the plot
plt.savefig('io_performance.png')
plt.close()

print("Plot generated: io_performance.png")