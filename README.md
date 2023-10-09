# gpfs-perf-check
The idea behind GPFS performance check is to run a series of high-loaded I/O operations on regular basis and chart the results. The software used to perform the required I/O operations is IOR. Test jobs are submitted using cron every 4 hours.The main script, which is executed on cron is submit_a
