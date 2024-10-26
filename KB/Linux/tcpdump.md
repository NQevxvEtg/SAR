### 1. **Basic Capture of All Traffic**

To start, a basic capture allows you to see all packets on a specific network interface:
```bash
sudo tcpdump -i eth0
```

- **Explanation**: This captures all packets on the `eth0` interface. However, this output can be very verbose, so filtering by protocols, hosts, or ports is often more useful.

---

### 2. **Capture and Display Only TCP Traffic**

For troubleshooting application-level issues, such as HTTP or database connection problems, capturing only TCP traffic narrows the focus.
```bash
sudo tcpdump -i eth0 tcp
```

- **Explanation**: This filters for TCP traffic on the `eth0` interface, excluding UDP and other protocols, making it easier to isolate issues with connection-oriented protocols.

---

### 3. **Capture Traffic to and from a Specific IP**

If you suspect issues with a specific host, capture traffic to or from that IP:
```bash
sudo tcpdump -i eth0 host 192.168.1.10
```

- **Explanation**: This command captures all traffic (both incoming and outgoing) between the `eth0` interface and the IP `192.168.1.10`, helping identify issues between your system and this specific host.

---

### 4. **Filter by Source or Destination IP Address**

To see only traffic sent from or received by a particular IP, use `src` or `dst` filters.

- **Capture Traffic from a Specific Source**:
  ```bash
  sudo tcpdump -i eth0 src 192.168.1.10
  ```
- **Capture Traffic to a Specific Destination**:
  ```bash
  sudo tcpdump -i eth0 dst 192.168.1.10
  ```

- **Explanation**: These commands are useful for troubleshooting issues originating from a particular IP or targeting a specific IP.

---

### 5. **Capture Traffic on a Specific Port**

If an application uses a known port, filter for that port to limit the capture to relevant data.

- **Example**: Capturing HTTP Traffic (port 80)
  ```bash
  sudo tcpdump -i eth0 port 80
  ```

- **Explanation**: This captures only packets on TCP port 80 (HTTP), making it easier to troubleshoot web server issues without extraneous data.

---

### 6. **Capture Packets with Specific Flags (e.g., SYN for Connection Issues)**

Capturing packets with specific TCP flags can help diagnose connection setup issues, such as failed handshakes.

- **Example**: Capturing SYN Packets Only
  ```bash
  sudo tcpdump -i eth0 'tcp[tcpflags] & tcp-syn != 0'
  ```

- **Explanation**: SYN packets indicate new connection attempts. By capturing only SYN packets, you can identify failed or repeated connection attempts, which may point to issues with the application server or network path.

---

### 7. **Capture DNS Traffic**

For troubleshooting domain name resolution issues, capture only DNS traffic (UDP port 53).

```bash
sudo tcpdump -i eth0 udp port 53
```

- **Explanation**: This captures DNS request and response packets, helping to diagnose DNS latency or resolution failures.

---

### 8. **Save Capture to a File for Later Analysis**

For complex troubleshooting, it’s often best to save a capture to a file and analyze it later with tools like Wireshark.

- **Command**:
  ```bash
  sudo tcpdump -i eth0 -w /tmp/network_capture.pcap
  ```

- **Explanation**: This captures all traffic on `eth0` and saves it in `network_capture.pcap`. The file can be opened later in Wireshark, which offers a GUI for detailed analysis and filtering.

---

### 9. **Capture Traffic for a Specific Time Limit**

If you need a short capture window, specify a duration in seconds with the `-G` option.

- **Example**: Capture Traffic for 10 Seconds
  ```bash
  sudo tcpdump -i eth0 -G 10 -w /tmp/capture_10sec.pcap
  ```

- **Explanation**: This captures all traffic on `eth0` for 10 seconds and saves it to `capture_10sec.pcap`. This is useful for intermittent issues that only require short monitoring periods.

---

### 10. **Capture Only Packet Headers**

To reduce data size and avoid capturing sensitive information, you can capture only packet headers (first 64 bytes).

```bash
sudo tcpdump -i eth0 -s 64
```

- **Explanation**: By capturing only the first 64 bytes, this command includes just the headers, which often suffice for protocol analysis without logging full payloads.

---

### 11. **Verbose Output for Detailed Packet Information**

For debugging with detailed packet information, use the `-v` option for verbose output, `-vv` for extra verbose, or `-vvv` for maximum verbosity.

```bash
sudo tcpdump -i eth0 -vv
```

- **Explanation**: This provides detailed packet information, such as protocol headers and flags, which can be helpful for advanced troubleshooting.

---

### 12. **Monitoring Bandwidth Usage**

Using `tcpdump` along with `pv` (pipe viewer), you can estimate bandwidth usage by monitoring packet flow rates.

- **Install `pv`**:
  ```bash
  sudo yum install -y pv
  ```
- **Command**:
  ```bash
  sudo tcpdump -i eth0 -w - | pv -br >/dev/null
  ```

- **Explanation**: This command pipes `tcpdump` output to `pv`, providing a real-time view of traffic throughput. The output shows data flow rate in bytes per second, which is useful for monitoring bandwidth usage in real time.

---

### 13. **Capture with Advanced Filtering: Combining Multiple Filters**

To troubleshoot specific scenarios, you can combine filters to capture only packets that match multiple criteria.

- **Example**: Capture TCP Traffic to Port 80 from IP `192.168.1.10`
  ```bash
  sudo tcpdump -i eth0 tcp and port 80 and src 192.168.1.10
  ```

- **Explanation**: This command filters for TCP traffic going to port 80 from the IP address `192.168.1.10`, which is helpful for analyzing traffic from a specific client to a specific service.

---

### 14. **Analyze HTTP GET Requests**

If you want to capture and analyze HTTP GET requests, use the `-A` option to print ASCII output, which can display text-based protocols like HTTP.

```bash
sudo tcpdump -i eth0 -A -s 0 'tcp port 80 and (((ip[2:2] - ((ip[0]&0xf)<<2)) - ((tcp[12]&0xf0)>>2)) != 0)'
```

- **Explanation**: This command captures and displays only HTTP GET requests by filtering packets with data payloads on port 80. The `-A` option displays the payloads in ASCII, which is helpful for analyzing HTTP request content.

