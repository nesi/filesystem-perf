import matplotlib.pyplot as plt
import pandas as pd
from datetime import datetime
import sys

# Debug: Print Python version and pandas version
print(f"Python version: {sys.version}")
print(f"Pandas version: {pd.__version__}")

try:
    # Read the processed data
    df = pd.read_csv('io_measurements_processed.csv')
    
    # Debug: Print the first few rows of the dataframe
    print("First few rows of the dataframe:")
    print(df.head())
    
    # Debug: Print dataframe info
    print("\nDataframe info:")
    print(df.info())

    # Convert Timestamp to datetime
    df['Timestamp'] = pd.to_datetime(df['Timestamp'])

    # Create the plot
    plt.figure(figsize=(12, 6))

    for operation in df['Operation'].unique():
        data = df[df['Operation'] == operation]
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

except Exception as e:
    print(f"An error occurred: {str(e)}")
    
    # Debug: If the file exists, print its contents
    try:
        with open('io_measurements_processed.csv', 'r') as f:
            print("Contents of io_measurements_processed.csv:")
            print(f.read())
    except FileNotFoundError:
        print("io_measurements_processed.csv file not found.")
