import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns

def parse_fio_results(file_path):
    # Initialize lists to store data
    data = []
    
    with open(file_path, 'r') as f:
        lines = f.readlines()
        
    current_test = None
    metrics = {}
    
    for i, line in enumerate(lines):
        if 'Test:' in line:
            # If we have a previous test, save it
            if current_test and metrics:
                current_test.update(metrics)
                data.append(current_test.copy())
            
            # Extract test parameters
            parts = line.split('|')
            test_type = parts[0].split(':')[1].strip()
            block_size = parts[1].split(':')[1].strip()
            threads = int(parts[2].split(':')[1].strip())
            current_test = {'test_type': test_type, 'block_size': block_size, 'threads': threads}
            metrics = {}
            
        elif line.strip().startswith(('Read Bandwidth:', 'Write Bandwidth:', 'Read IOPS:', 'Write IOPS:')):
            # Extract exact values with full precision
            parts = line.strip().split(':')
            metric_name = parts[0].strip()
            try:
                metric_value = float(parts[1].strip().split()[0])
                metrics[metric_name] = metric_value
            except (ValueError, IndexError) as e:
                print(f"Error parsing line {i}: {line.strip()}")
                continue
    
    # Don't forget the last test
    if current_test and metrics:
        current_test.update(metrics)
        data.append(current_test.copy())
    
    df = pd.DataFrame(data)
    # Print verification of raw data parsing
    if 'randrw' in df['test_type'].values:
        print("\nVerification of parsed randrw data:")
        randrw_data = df[df['test_type'] == 'randrw'][['block_size', 'threads', 'Read Bandwidth', 'Write Bandwidth', 'Read IOPS', 'Write IOPS']]
        print(randrw_data.to_string())
    
    return df

def plot_performance(df, output_dir='./'):
    # Set style
    sns.set_theme()
    sns.set_palette("husl")
    
    # Create figure with subplots
    fig, ((ax1, ax2), (ax3, ax4)) = plt.subplots(2, 2, figsize=(15, 12))
    fig.suptitle('FIO Performance Analysis', fontsize=16)
    
    # Plot 1: Write Bandwidth by Block Size and Threads
    write_df = df[df['test_type'] == 'write']
    for thread in sorted(write_df['threads'].unique()):
        thread_data = write_df[write_df['threads'] == thread]
        ax1.plot(thread_data['block_size'], thread_data['Write Bandwidth'], 
                marker='o', label=f'{thread} Threads')
    ax1.set_title('Write Bandwidth vs Block Size')
    ax1.set_xlabel('Block Size')
    ax1.set_ylabel('Bandwidth (MB/s)')
    ax1.legend()
    ax1.grid(True)
    
    # Plot 2: Read Bandwidth by Block Size and Threads
    read_df = df[df['test_type'] == 'read']
    for thread in sorted(read_df['threads'].unique()):
        thread_data = read_df[read_df['threads'] == thread]
        ax2.plot(thread_data['block_size'], thread_data['Read Bandwidth'], 
                marker='o', label=f'{thread} Threads')
    ax2.set_title('Read Bandwidth vs Block Size')
    ax2.set_xlabel('Block Size')
    ax2.set_ylabel('Bandwidth (MB/s)')
    ax2.legend()
    ax2.grid(True)
    
    # Plot 3: Random R/W Read Bandwidth
    randrw_df = df[df['test_type'] == 'randrw']
    for thread in sorted(randrw_df['threads'].unique()):
        thread_data = randrw_df[randrw_df['threads'] == thread]
        ax3.plot(thread_data['block_size'], thread_data['Read Bandwidth'], 
                marker='o', label=f'{thread} Threads')
    ax3.set_title('Random Read Bandwidth vs Block Size')
    ax3.set_xlabel('Block Size')
    ax3.set_ylabel('Bandwidth (MB/s)')
    ax3.legend()
    ax3.grid(True)
    
    # Plot 4: Random R/W Write Bandwidth
    for thread in sorted(randrw_df['threads'].unique()):
        thread_data = randrw_df[randrw_df['threads'] == thread]
        ax4.plot(thread_data['block_size'], thread_data['Write Bandwidth'], 
                marker='o', label=f'{thread} Threads')
    ax4.set_title('Random Write Bandwidth vs Block Size')
    ax4.set_xlabel('Block Size')
    ax4.set_ylabel('Bandwidth (MB/s)')
    ax4.legend()
    ax4.grid(True)
    
    # Adjust layout and save
    plt.tight_layout()
    plt.savefig(f'{output_dir}/fio_performance_analysis.png', dpi=300, bbox_inches='tight')
    plt.close()

def main():
    # Parse the results
    df = parse_fio_results('summary.txt')
    
    # Create visualizations
    plot_performance(df)
    
    # Print summary statistics with more precision
    pd.set_option('display.precision', 6)
    print("\nSummary Statistics:")
    
    print("\nWrite Performance:")
    write_stats = df[df['test_type'] == 'write'].groupby('threads')['Write Bandwidth'].agg(['mean', 'max'])
    print(write_stats)
    
    print("\nRead Performance:")
    read_stats = df[df['test_type'] == 'read'].groupby('threads')['Read Bandwidth'].agg(['mean', 'max'])
    print(read_stats)
    
    print("\nRandom R/W Performance:")
    randrw_stats = df[df['test_type'] == 'randrw'].groupby('threads').agg({
        'Read Bandwidth': ['mean', 'max'],
        'Write Bandwidth': ['mean', 'max'],
        'Read IOPS': ['mean', 'max'],
        'Write IOPS': ['mean', 'max']
    })
    print(randrw_stats)

if __name__ == "__main__":
    main()
