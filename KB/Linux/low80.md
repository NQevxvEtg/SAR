### **1. Kernel Tuning and Debugging**

1. **`echo "c" > /proc/sysrq-trigger`** - Trigger a manual kernel crash to analyze system panic behavior (use in testing environments only!).
2. **`perf record -F 99 -p <pid> -g -- sleep 60`** - Profile a process for 60 seconds to capture stack traces with flame graph potential.
3. **`echo 3 > /proc/sys/vm/drop_caches`** - Clear pagecache, dentries, and inodes (memory optimization after heavy file usage).
4. **`bpftrace -e 'tracepoint:syscalls:sys_enter_execve { printf("%s\n", str(args->filename)); }'`** - Trace every command executed on the system using BPF.
5. **`echo "1" > /proc/sys/net/ipv4/tcp_tw_reuse`** - Allow reuse of TIME_WAIT sockets (useful for busy systems).
6. **`trace-cmd record -e sched_switch`** - Record context switches for detailed kernel-level debugging.
7. **`dmesg -L --level=err,warn`** - Show only error and warning level logs in the kernel buffer.
8. **`cat /proc/interrupts | awk '{sum += $2} END {print sum}'`** - Summarize total CPU interrupts, useful for hardware diagnostics.
9. **`lsof | grep deleted`** - Check for deleted files still held open by processes, which can consume disk space.
10. **`sysctl -w kernel.perf_event_paranoid=-1`** - Temporarily enable full access to perf events (usually restricted).

### **2. Deep Process and Memory Manipulation**

11. **`gcore -o /tmp/core_dump <pid>`** - Generate a core dump of a running process without stopping it.
12. **`pmap -x <pid> | grep total`** - Display the exact memory usage breakdown for a process.
13. **`echo "scaling_governor=performance" > /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor`** - Set all CPUs to performance mode, maximizing processing power.
14. **`lsof -p <pid> | awk '{print $9}' | xargs -I {} du -sh {} 2>/dev/null | sort -h`** - Calculate disk usage of files opened by a specific process.
15. **`gdb -p <pid> --batch -ex "thread apply all bt" > /tmp/threads-backtrace.txt`** - Dump backtrace of all threads in a running process.
16. **`echo 1 > /proc/sys/vm/compact_memory`** - Initiate manual memory compaction, which can help defragment RAM.
17. **`nsenter -t <pid> -m -u -i -n -p`** - Enter namespaces of another process (useful for debugging containerized environments).
18. **`cat /proc/<pid>/smaps | awk '/Private_Dirty/ {sum += $2} END {print sum " KB"}'`** - Display dirty memory pages in KB for a specific process.
19. **`pgrep -l -P $(pgrep -f "parent_process_name")`** - List child processes of a specific parent process.
20. **`coredumpctl list | grep <service>`** - List core dumps generated by a specific service.

### **3. Ultra-Networking and Packet Analysis**

21. **`nmap -sn -PE -n <network>`** - Perform a quick ICMP ping sweep on an entire subnet without DNS resolution.
22. **`tcpdump -w /tmp/capture.pcap -C 100 -W 10 -i <interface>`** - Rotate packet capture files every 100MB, storing up to 10 files.
23. **`ipset create blacklist hash:ip`** - Create an IP blacklist using `ipset` for high-performance filtering with `iptables`.
24. **`tc qdisc add dev <interface> root netem delay 100ms`** - Add 100ms latency to all outgoing traffic (network simulation).
25. **`ss -o state established '( dport = :http or sport = :http )' | wc -l`** - Count all established HTTP connections.
26. **`ethtool -K <interface> tso off gso off gro off`** - Disable TCP segmentation, generic segmentation, and generic receive offload (useful for troubleshooting NIC issues).
27. **`ip link set dev <interface> mtu 9000`** - Increase MTU to 9000 for jumbo frame support on high-throughput networks.
28. **`iptables -I INPUT -m conntrack --ctstate INVALID -j DROP`** - Drop all invalid packets to enhance security.
29. **`bmon -p <interface>`** - Real-time bandwidth monitoring for a specific interface.
30. **`ss -Hant "( dport = 22 )"`** - Show all TCP connections on port 22 (SSH) with a clean format.

### **4. Advanced Red Hat Satellite & Capsule Commands**

31. **`hammer capsule content synchronize --name "<capsule_name>"`** - Synchronize all content from a specific Capsule.
32. **`foreman-rake katello:delete_orphaned_content`** - Delete orphaned content to free up storage in Satellite.
33. **`hammer content-view version export --id <view_id> --path /path/to/export`** - Export a specific content view version.
34. **`hammer task resume --search 'state=paused'`** - Resume all paused tasks.
35. **`foreman-maintain service status --exclude <service>`** - Check the status of all services except the specified one.
36. **`capsule-cmd content proxy --hostname <hostname> --add`** - Add a content proxy to a Capsule.
37. **`foreman-rake katello:purge_old_sync_status`** - Clear old sync status information.
38. **`hammer compute-resource list --organization "<org>"`** - List all compute resources for a specific organization.
39. **`hammer task cleanup --state pending --days-ago 5`** - Clean up tasks in a specific state older than a given number of days.
40. **`hammer host delete --name <hostname>`** - Force delete a host from Satellite.

### **5. File System Mastery and Forensics**

41. **`find / -inum <inode_number> -exec ls -ld {} \;`** - Find and display the path of a file based on inode.
42. **`debugfs -R "stat <inode>" /dev/<device>`** - Display metadata about a file or directory in ext4.
43. **`xfs_db -c "frag" /dev/<device>`** - Show the fragmentation level of an XFS filesystem.
44. **`btrfs filesystem defragment -r /path`** - Defragment a Btrfs filesystem recursively.
45. **`wipefs -a /dev/<device>`** - Erase all filesystem signatures (dangerous, but useful in disk repurposing).
46. **`mount -o loop,offset=$((512*2048)) <image> /mnt`** - Mount a partitioned disk image by specifying an offset.
47. **`xfs_repair -n /dev/<device>`** - Run an XFS filesystem check without making changes.
48. **`tune2fs -l /dev/<device> | grep "Filesystem created"`** - Find the creation date of an ext4 filesystem.
49. **`mount -o remount,ro /dev/<device>`** - Remount a device as read-only for forensic analysis.
50. **`blkid -p -o export /dev/<device>`** - Show detailed partition information.

### **6. Data Transformation and Parsing**

51. **`awk 'NR==FNR{a[$1];next}($1 in a)' file1 file2`** - Print lines in `file2` matching the first field of `file1`.
52. **`jq '.[] | select(.key=="value")' file.json`** - Parse JSON and filter by key-value in `jq`.
53. **`xargs -n1 -P4 <command>`** - Run a command in parallel with multiple arguments.
54. **`sed -n '/pattern/{n;p;}' file.txt`** - Print the line following the pattern match.
55. **`awk '{for(i=NF;i>=1;i--) printf "%s ",$i; print ""}' file.txt`** - Reverse each line’s word order.
56. **`column -t -s',' file.csv`** - Pretty-print a CSV file.
57. **`awk 'NR % 2 == 0' file.txt`** - Print only the even-numbered lines.
58. **`grep -A 3 'pattern' file.txt | tac | sed '1,/other_pattern/d' | tac`** - Search around a pattern while skipping unwanted sections.
59. **`awk 'ORS=NR%2?",":"\n"' file.txt`** - Join every two lines with a comma.
60. **`sort -

u -k2,2 file.txt | sort -o file.txt`** - Remove duplicates based on the second column.

### **7. System Resilience and Stability Testing**

61. **`stress-ng --cpu 4 --timeout 60s`** - Generate CPU load across four cores for one minute.
62. **`fio --name=randrw --ioengine=libaio --rw=randrw --bs=4k --numjobs=4 --size=1G --runtime=60 --group_reporting`** - Perform random read/write I/O load testing.
63. **`sysctl -w vm.overcommit_memory=2`** - Enforce strict memory overcommit for stability testing.
64. **`ab -n 1000 -c 50 http://localhost/`** - Load test a web server with Apache Benchmark.
65. **`taskset -c 1 <command>`** - Bind a process to a specific CPU core.
66. **`oomctl show`** - Display Out-of-Memory (OOM) events.
67. **`echo "offline" > /sys/devices/system/cpu/cpu2/online`** - Disable a specific CPU core for testing.
68. **`sysctl -w fs.file-max=100000`** - Temporarily increase the max open file descriptor count.
69. **`while :; do dd if=/dev/zero of=/tmp/testfile bs=1M count=1000; sync; rm /tmp/testfile; done`** - Continuous disk I/O testing.
70. **`ulimit -c unlimited`** - Enable unlimited core dumps for all processes.

### **8. Redundant Configuration and Load Balancing**

71. **`pacemaker status`** - Check status of Pacemaker-managed resources.
72. **`crm configure show`** - Display current Pacemaker cluster configuration.
73. **`haproxy -c -f /etc/haproxy/haproxy.cfg`** - Validate HAProxy configuration.
74. **`corosync-cfgtool -s`** - Show Corosync cluster membership and status.
75. **`crm configure primitive p_vip ocf:heartbeat:IPaddr2 params ip="192.168.0.100" cidr_netmask="24"`** - Add a virtual IP to a cluster.

### **9. Secure Environment Controls**

76. **`auditctl -a exit,always -F arch=b64 -S execve -k exec`** - Log every executed command on a 64-bit system.
77. **`tripwire --check`** - Run an integrity check of critical system files.
78. **`sssd -i -d 10`** - Start `sssd` in debug mode (useful for AD and LDAP).
79. **`openssl s_client -connect <host>:443`** - Test SSL/TLS connection manually.
80. **`selinuxenabled || echo "SELinux is disabled"`** - Check if SELinux is enabled in a single line.
