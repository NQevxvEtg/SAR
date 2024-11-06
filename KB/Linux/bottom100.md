### **1. System Performance and Optimization**

1. **`dstat --top-cpu --top-io`** - Real-time CPU and I/O usage monitoring with top processes.
2. **`sar -u 1 5`** - Show CPU utilization every second for 5 seconds.
3. **`perf stat -a sleep 5`** - Collect system-wide performance stats for 5 seconds.
4. **`iostat -xz 1 5`** - Detailed I/O stats per device every second for 5 seconds.
5. **`numastat`** - Show memory allocation per NUMA node.
6. **`strace -p <pid>`** - Trace system calls made by a process (PID).
7. **`lsof +L1`** - Identify open files deleted by a process.
8. **`vmstat -s -SM`** - Display memory usage stats in MB with summary.
9. **`htop -u <user>`** - Monitor processes by a specific user in `htop`.
10. **`cpulimit -l <limit> -p <pid>`** - Limit CPU usage of a process to a specific percentage.

### **2. Advanced File and Process Management**

11. **`lsof -u <username>`** - List all files opened by a specific user.
12. **`pgrep -fa <pattern>`** - Find processes matching a pattern with details.
13. **`ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%cpu`** - Display processes sorted by CPU usage.
14. **`watch -n 1 "ps -eo pid,cmd,%mem,%cpu --sort=-%mem | head -10"`** - Monitor top memory-hungry processes.
15. **`ionice -c2 -p <pid>`** - Set I/O priority for a process.
16. **`nice -n -10 <command>`** - Run a command with increased priority.
17. **`chattr +i <file>`** - Make a file immutable (can’t be deleted or modified).
18. **`renice -n 10 -p <pid>`** - Adjust the priority of a running process.
19. **`pkill -u <username>`** - Kill all processes for a specific user.
20. **`find / -xdev -type f -size +500M -exec ls -lh {} \;`** - Find large files over 500MB.

### **3. Disk and Filesystem Management**

21. **`lvextend -l +100%FREE /dev/<vg>/<lv>`** - Extend a logical volume to use all free space.
22. **`xfs_repair -L /dev/<device>`** - Repair an XFS filesystem.
23. **`tune2fs -c 50 /dev/<device>`** - Set max mount count for `fsck` checks.
24. **`fstrim -v /mount_point`** - Manually trim SSD storage.
25. **`du -h / | sort -rh | head -10`** - Show top 10 largest directories.
26. **`lsblk -f`** - List block devices with filesystem type.
27. **`resize2fs /dev/<lv>`** - Resize an ext2/ext3/ext4 filesystem.
28. **`btrfs filesystem df /mount_point`** - Show detailed Btrfs space usage.
29. **`blkid`** - Display UUID and filesystem type of all block devices.
30. **`lsattr -R /`** - List all extended file attributes recursively.

### **4. Network Diagnostics and Management**

31. **`ipset list`** - Show all IP sets for advanced firewall management.
32. **`tcpdump -i <interface> 'port <port>'`** - Capture traffic on a specific port.
33. **`nmap -sT -p- <host>`** - Scan all 65535 TCP ports on a target.
34. **`ss -pant | grep ESTAB`** - List established TCP connections.
35. **`ip rule show`** - Display all IP routing rules.
36. **`arp -a`** - Show current ARP table.
37. **`dig +short @8.8.8.8 <hostname>`** - Query DNS directly from Google’s DNS.
38. **`iptables -t nat -L -v -n`** - Display all NAT table rules in iptables.
39. **`iwconfig`** - Show wireless network interface configuration.
40. **`ethtool -S <interface>`** - Show network interface statistics.

### **5. Red Hat Satellite & Capsule Deep Management**

41. **`hammer host update --parameters <key=value>`** - Update host parameters.
42. **`hammer content-view version promote --organization <org> --content-view <name> --to-lifecycle-environment <env>`** - Promote a content view version.
43. **`hammer lifecycle-environment list`** - List all lifecycle environments.
44. **`hammer repository-set enable --organization <org> --product <product> --name <repo_name>`** - Enable a repository set for syncing.
45. **`capsule-cmd content sync`** - Sync all content on Capsule.
46. **`foreman-rake katello:clean_backend_objects`** - Clean backend Pulp data for Satellite.
47. **`hammer sync-plan create --name "<name>" --interval daily --sync-date "YYYY-MM-DD HH:MM"`** - Create a sync plan.
48. **`capsule-cmd check-certificates`** - Validate SSL certificates on Capsule.
49. **`hammer report generate --report 'Host Subscription'`** - Generate subscription report.
50. **`hammer task resume --id <task_id>`** - Resume a paused task on Satellite.

### **6. Security and Compliance**

51. **`ausearch -c <command>`** - Search audit logs for a specific command.
52. **`auditctl -w /path/to/file -p warx -k <key>`** - Monitor file access using audit.
53. **`firewall-cmd --zone=public --list-all`** - List all settings in the public firewall zone.
54. **`setfacl -m u:<user>:rwx <file>`** - Set ACL permissions for a file.
55. **`grep -i "illegal" /var/log/secure`** - Check security logs for failed attempts.
56. **`semanage port -l | grep <port>`** - Check SELinux rules for a specific port.
57. **`psad -S`** - Check for intrusions using PSAD (Port Scan Attack Detector).
58. **`lynis audit system`** - Run a full security audit (if Lynis is installed).
59. **`chage -M 90 <username>`** - Set maximum password age.
60. **`modprobe -r <module>`** - Remove a kernel module (useful for security hardening).

### **7. Scripting and Automation**

61. **`for i in {1..10}; do touch file$i.txt; done`** - Create multiple files with a loop.
62. **`find /var/log -type f -name "*.log" -mtime +7 -exec rm -f {} \;`** - Delete logs older than 7 days.
63. **`awk '{sum+=$1} END {print sum}' numbers.txt`** - Sum a column of numbers in a file.
64. **`xargs -a list.txt rm -rf`** - Delete files listed in `list.txt`.
65. **`sed -i '/pattern/d' file.txt`** - Delete lines matching a pattern in a file.
66. **`while read line; do echo $line; done < file.txt`** - Read and echo each line of a file.
67. **`grep -r "error" /var/log`** - Search recursively for "error" in log files.
68. **`cat file1 file2 > merged_file`** - Concatenate two files into one.
69. **`(command1 && command2) || command3`** - Run command3 only if command1 and command2 fail.
70. **`export PS1='\[\e[0;31m\]\u@\h:\w$\[\e[m\] '`** - Customize the Bash prompt with colors.

### **8. Advanced Monitoring and Logging**

71. **`journalctl -p 3 -xb`** - Show all critical and higher priority logs since the last boot.
72. **`logrotate -f /etc/logrotate.conf`** - Force rotate all logs.
73. **`ngrep -d any 'GET|POST' tcp port 80`** - Monitor HTTP traffic with `ngrep`.
74. **`dmesg --ctime`** - View kernel ring buffer with readable timestamps.
75. **`ps axjf`** - Show process hierarchy.
76. **`iostat -c -d 1 10`** - Display CPU and I/O statistics in real time.
77. **`iftop -i <interface>`** - Monitor network bandwidth in real time.
78. **`atop -P CPU,NET`** - Focus on CPU and network usage in `

atop`.
79. **`watch -n 0.5 "ls -ltr /path/to/watch"`** - Monitor changes in a directory in near real-time.
80. **`sar -q 1 10`** - System load averages every second for 10 seconds.

### **9. Disk Encryption and Management**

81. **`cryptsetup luksFormat /dev/<device>`** - Format a partition with LUKS encryption.
82. **`cryptsetup luksOpen /dev/<device> encrypted_device`** - Open an encrypted LUKS partition.
83. **`mkfs.ext4 /dev/mapper/encrypted_device`** - Format an opened LUKS partition.
84. **`vgextend <vg_name> /dev/<device>`** - Extend a volume group with a new device.
85. **`lvreduce -L -10G /dev/<vg>/<lv>`** - Reduce the size of a logical volume by 10G.
86. **`btrfs scrub start /mount_point`** - Start data scrubbing on a Btrfs volume.
87. **`xfs_growfs /mount_point`** - Expand an XFS filesystem.
88. **`tune2fs -m 0 /dev/<device>`** - Set reserved space for root to zero on a filesystem.
89. **`pvdisplay -m`** - Display physical volume details with mapping.
90. **`blkdiscard /dev/<device>`** - Securely wipe a device (SSD-friendly).

### **10. Network Security & Firewalling**

91. **`iptables -A INPUT -p tcp --dport 22 -s <IP> -j ACCEPT`** - Allow SSH access from specific IP.
92. **`firewall-cmd --runtime-to-permanent`** - Make current firewall rules persistent.
93. **`firewalld-cmd --zone=public --remove-service=http --permanent`** - Remove HTTP service from firewall.
94. **`iptables -I INPUT -p tcp --dport 80 -j DROP`** - Temporarily block HTTP access.
95. **`fail2ban-client status sshd`** - Check status of SSH jail in Fail2ban.
96. **`nft list ruleset`** - Show all nftables rules.
97. **`pam_tally2 --user <username> --reset`** - Reset login failure count for a user.
98. **`aide --check`** - Run file integrity check using AIDE.
99. **`nmap --script vuln <IP>`** - Scan a host for common vulnerabilities.
100. **`tcpdump -w /path/to/output.pcap`** - Capture all network traffic to a file for later analysis.

