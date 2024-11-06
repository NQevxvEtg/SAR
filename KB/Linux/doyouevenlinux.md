### **1. Explain Event-Driven Architecture and Its Performance Benefits**

**Answer**: Event-driven architecture (EDA) allows applications to respond to events in real-time by asynchronously handling requests. Instead of continuous polling or blocking processes, EDA waits for specific triggers to initiate functions, enabling non-blocking, efficient resource use. **Benefits**:
   - Reduces idle CPU usage.
   - Scales horizontally with demand.
   - Improves latency by reducing resource contention.

### **2. Profiling an Application in a Linux Environment to Optimize Performance**

**Solution**:
To profile an application and identify performance bottlenecks:
- **`perf`** (kernel-level profiling): 
   ```bash
   perf record -p <pid> -g -- sleep 10
   perf report
   ```
   - **`strace`** (system calls):
     ```bash
     strace -c -p <pid>
     ```
   - **`gprof`** (GNU profiling): 
     ```bash
     gcc -pg -o myapp myapp.c
     ./myapp
     gprof myapp gmon.out > analysis.txt
     ```

### **3. Testing Connection on All Interfaces Using sysfs**

If `telnet` and common tools are unavailable, use `sysfs` to manually test connections:
```bash
for interface in /sys/class/net/*; do
    ip link set "$(basename "$interface")" up
    echo "Interface: $(basename "$interface") is up" > /dev/udp/8.8.8.8/53
done
```

### **4. Golden Rules for Reducing Impact of a Hacked System**

1. **Contain and Isolate**: Immediately disconnect the compromised machine from the network to prevent lateral movement.
2. **Collect Forensics and Restore**: Gather logs, snapshots, and memory dumps for forensic analysis before wiping. Rebuild from a trusted, clean backup.

### **5. Pros and Cons of Using OpenBSD Firewall in Core Networks**

**Pros**:
   - Highly secure by design, with proactive security mitigations.
   - PF (Packet Filter) is efficient and reliable for managing stateful connections.
   - Minimalist approach reduces attack surface.

**Cons**:
   - Limited support for high-throughput requirements in very large environments.
   - Smaller community and fewer enterprise-grade features compared to other firewalls.
   - Limited vendor support compared to mainstream firewalls like Cisco or Palo Alto.

**Conclusion**: OpenBSD’s firewall is a solid choice for security-focused environments but might need load-balancing and careful tuning in high-throughput core networks.

### **6. Allowing Multiple Cross-Domains with `Access-Control-Allow-Origin` in Nginx**

**Solution**: Use `map` in Nginx to selectively apply the `Access-Control-Allow-Origin` header:
```nginx
map $http_origin $cors_origin {
    "~^https?://(example.com|another.com)$" $http_origin;
    default "";
}

server {
    location / {
        if ($cors_origin) {
            add_header Access-Control-Allow-Origin $cors_origin;
            add_header Access-Control-Allow-Methods "GET, POST, OPTIONS";
            add_header Access-Control-Allow-Credentials true;
        }
    }
}
```

### **7. Understanding `:(){ :|:& };:` (Fork Bomb) and Stopping It**

**Explanation**: This is a shell-based fork bomb, recursively creating new processes until the system runs out of resources.

**Stopping it**:
1. Limit processes per user to prevent a fork bomb:
   ```bash
   ulimit -u 100
   ```
2. If already running, kill all fork bomb processes:
   ```bash
   pkill -u <username>
   ```

### **8. Recovering a Deleted File Held Open by Apache**

If a file is deleted but held open by a process (e.g., Apache), it can be recovered using:
```bash
lsof -p $(pgrep apache) | grep deleted
# Copy the contents of the file descriptor back to disk
cat /proc/<pid>/fd/<fd_number> > /path/to/recover/file.txt
```

### **9. Remote Reinstallation of Linux Without Console Access**

**Solution**: Use PXE or a network-based installation method. Alternatively:
   1. **Mount ISO remotely**: Set up an ISO image on an NFS share.
   2. **Download and start installation**:
      ```bash
      wget http://<server>/path/to/iso
      mount -o loop /path/to/iso /mnt
      rsync -a /mnt/ /boot/ # copy to /boot or dedicated boot partition
      ```
   3. Reboot into the mounted system to continue installation.

### **10. Controlling the Linux OOM Killer**

The OOM Killer chooses processes to kill based on their memory usage and `oom_score`. Control it by adjusting `oom_score_adj`:
```bash
echo -1000 > /proc/<pid>/oom_score_adj  # Less likely to be killed
```
Set memory limits to avoid triggering the OOM killer with large files:
```bash
ulimit -m 524288  # Set soft memory limit (in KB)
```

### **11. Reducing TIME_WAIT Sockets**

To reduce `TIME_WAIT` sockets:
   1. Enable TCP reuse:
      ```bash
      sysctl -w net.ipv4.tcp_tw_reuse=1
      ```
   2. Reduce `TIME_WAIT` duration:
      ```bash
      sysctl -w net.ipv4.tcp_fin_timeout=30
      ```

### **12. Difference Between `SO_REUSEADDR` and `SO_REUSEPORT`**

**`SO_REUSEADDR`**:
   - Allows multiple sockets to bind to the same IP/port, typically used for servers restarting without waiting for `TIME_WAIT`.
   - Does not allow load distribution.

**`SO_REUSEPORT`**:
   - Allows multiple sockets to bind to the same IP/port and distributes incoming connections among them.
   - Useful for load balancing in multi-threaded applications
