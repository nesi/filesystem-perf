# This test suite provides a comprehensive evaluation of GPFS client performance. Here's what it tests:

1. Sequential Read/Write Performance
    - Tests with different block sizes (1M to 16M)
    - Tests with varying numbers of threads (1 to 16)
    - Measures throughput and latency

2. Random Read/Write Performance
    - Mixed workload testing
    - Various thread counts and block sizes
    - IOPS measurement

3. Metadata Performance
    - File creation speed
    - Small file handling

## To use this test:

1. Make sure FIO is installed
2. Modify the `TEST_DIR` variable to point to your GPFS test directory. This will be used to write .dat files
3. Adjust `FILE_SIZE` and other parameters as needed
