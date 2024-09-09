This setup will:

- Run both serial and parallel I/O tests (read and write) every 30 seconds for 10 minutes.
- Use 4 nodes for parallel tests (you can adjust this in both scripts if needed).
- Save the results in `io_measurements.txt`.
- Generate a plot of all four I/O speeds (serial read/write, parallel read/write) over time, saved as `io_performance.png`.

Key points:

- It uses MPI for parallel I/O tests, which is similar to how IOR operates.
- The script tests both read and write operations for serial and parallel scenarios.
