### 1. **Cgroups (Control Groups) on Red Hat**

#### Step 1: Install Required Packages
- **Install `libcgroup` package** (provides cgroup utilities on Red Hat-based systems):
  ```bash
  sudo yum install -y libcgroup
  ```

#### Step 2: Set Up Configuration Files

1. **Create Configuration Files**: Set up `/etc/cgconfig.conf` to define the cgroups and `/etc/cgrules.conf` to assign applications to these groups:
   ```bash
   sudo touch /etc/cgconfig.conf
   sudo touch /etc/cgrules.conf
   ```

2. **Configure `/etc/cgconfig.conf`**:
   - Open `/etc/cgconfig.conf` and define a group for your application. Here’s an example configuration for a cgroup named `app/appname` with CPU resource limits:
     ```ini
     group app/appname {
         cpu {
             cpu.shares = 700;
             cpu.cfs_quota_us = 70000;
         }
     }
     ```
   - **Explanation**:
     - `cpu.shares`: This allocates a relative weight for CPU time; higher values mean higher priority.
     - `cpu.cfs_quota_us`: This limits CPU usage in microseconds within each 100ms period, allowing 70% CPU access in this example.

3. **Configure `/etc/cgrules.conf`**:
   - Open `/etc/cgrules.conf` to assign the application to the `app/appname` group based on the binary name.
   - **Example Entry**:
     ```plaintext
     *:<binarynamereplaceme>    cpu     app/appname/
     ```
   - Replace `<binarynamereplaceme>` with the actual binary name, e.g., `httpd` for Apache.

#### Step 3: Load the Configuration and Start Daemons
1. **Load the cgroup configuration**:
   ```bash
   sudo cgconfigparser -l /etc/cgconfig.conf
   ```

2. **Start the `cgrulesengd` Daemon**:
   ```bash
   sudo systemctl start cgred
   ```

#### Step 4: Make the Configuration Persistent Using `systemd`
1. **Enable and Start the Cgroup Services at Boot**:
   ```bash
   sudo systemctl enable cgconfig --now
   sudo systemctl enable cgred --now
   ```

2. **Restart the Services After Changes**:
   - If you make changes to `/etc/cgconfig.conf`, reload with:
     ```bash
     sudo systemctl restart cgconfig
     sudo systemctl restart cgred
     ```

#### Verification
- To verify that the application is placed correctly in the cgroup:
  ```bash
  cgget -g cpu:app/appname
  ```

---

### 2. **Kernel Tuning with `sysctl` Parameters**

For Red Hat systems, `sysctl` allows temporary and persistent tuning of kernel parameters.

#### Example: Optimizing Network Buffer Sizes
1. **Apply Temporary Kernel Settings**:
   ```bash
   sudo sysctl -w net.core.rmem_max=16777216
   sudo sysctl -w net.core.wmem_max=16777216
   sudo sysctl -w net.ipv4.tcp_rmem="4096 87380 16777216"
   sudo sysctl -w net.ipv4.tcp_wmem="4096 87380 16777216"
   ```

2. **Make Changes Persistent**:
   - Add the configurations to `/etc/sysctl.conf`:
     ```bash
     echo "net.core.rmem_max=16777216" | sudo tee -a /etc/sysctl.conf
     echo "net.core.wmem_max=16777216" | sudo tee -a /etc/sysctl.conf
     echo "net.ipv4.tcp_rmem=4096 87380 16777216" | sudo tee -a /etc/sysctl.conf
     echo "net.ipv4.tcp_wmem=4096 87380 16777216" | sudo tee -a /etc/sysctl.conf
     ```

3. **Apply Persistent Changes**:
   ```bash
   sudo sysctl -p
   ```

---

### 3. **Performance Profiling with `perf`**

Using `perf`, you can identify performance bottlenecks on a Red Hat system.

#### Example: CPU Profiling for a Specific Process
1. **Run CPU Profiling for 10 Seconds**:
   ```bash
   sudo perf record -p <PID> -g -- sleep 10
   sudo perf report
   ```
   - Replace `<PID>` with the process ID of the application you wish to profile.

2. **Explanation**:
   - This captures a snapshot of CPU usage over 10 seconds with call graph information, showing where the CPU is spending most time within the application.

---

### 4. **Filesystem and I/O Optimization**

For I/O-intensive workloads, tuning filesystems and I/O scheduling can be critical.

#### Example: Formatting with XFS and Setting an I/O Scheduler
1. **Format Disk Partition with XFS**:
   ```bash
   sudo mkfs.xfs /dev/sdX
   ```

2. **Mount with Optimized Options**:
   ```bash
   sudo mount -o noatime,logbufs=8 /dev/sdX /mnt/mydisk
   ```

3. **Set the Deadline Scheduler**:
   ```bash
   echo "deadline" | sudo tee /sys/block/sdX/queue/scheduler
   ```

4. **Make Mount Persistent**:
   - Add to `/etc/fstab`:
     ```bash
     echo "/dev/sdX /mnt/mydisk xfs defaults,noatime,logbufs=8 0 0" | sudo tee -a /etc/fstab
     ```

---

### 5. **CPU and Process Affinity with `taskset` and `numactl`**

#### Example: Setting CPU Affinity for a High-Performance Application
1. **Assign a Process to Specific Cores**:
   ```bash
   sudo taskset -cp 0,1 <PID>
   ```

2. **Run a Process with NUMA Binding**:
   ```bash
   numactl --cpunodebind=1 --membind=1 /path/to/application
   ```

3. **Explanation**:
   - `taskset` pins the application to cores `0` and `1`, while `numactl` binds memory to a specific NUMA node, optimizing performance for memory-intensive applications on multi-core systems.

---

### 6. **Kernel Scheduler and Task Prioritization**

#### Example: Running a High-Priority Application
1. **Start a Command with High Priority**:
   ```bash
   sudo nice -n -10 /path/to/command
   ```

2. **Adjust Priority of Running Process**:
   ```bash
   sudo renice -n -5 -p <PID>
   ```

3. **Explanation**:
   - Setting a low `nice` value (closer to `-20`) gives higher priority, improving CPU access for critical processes.

---

### 7. **Using `tuned` and `tuned-adm` for Automated Optimization**

`tuned` on Red Hat systems provides profiles to match system workload needs.

#### Example: Enabling a Throughput Optimization Profile
1. **Install `tuned`**:
   ```bash
   sudo yum install -y tuned
   ```

2. **Activate the Throughput-Optimized Profile**:
   ```bash
   sudo tuned-adm profile throughput-performance
   ```

3. **Explanation**:
   - This profile optimizes system settings for applications requiring high throughput, adjusting kernel parameters, I/O scheduler, and more.

