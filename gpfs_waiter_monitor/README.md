## How to deploy gpgs_monitor.sh script via Nextflow

Modify Nextflow configuration to run this monitor alongside your pipeline. Add to your nextflow.config:

```bash
process {
    beforeScript = { """
        /path/to/gpfs_monitor.sh &
        MONITOR_PID=\$!
        trap "kill \$MONITOR_PID" EXIT
    """ }
}
```
* Monitor all processes accessing the GPFS mount point
* Detect when processes enter `D` state
* Collect detailed information including:

  - Process stack traces
  - GPFS waiter information
  - Open file handles
  - GPFS token status
  - I/O statistics