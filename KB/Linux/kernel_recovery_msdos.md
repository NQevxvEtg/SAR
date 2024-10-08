### Recovering a RHEL VM When GRUB Cannot Find the Kernel

In situations where GRUB cannot find the kernel, you may need to manually load the kernel and the initial RAM disk (initrd) from the GRUB command line. Follow these steps to recover your RHEL VM securely:

### Step 1: Access GRUB Command Line

1. **Restart the VM:** Reboot the virtual machine.
2. **Enter GRUB Menu:** During the boot process, hold down the `Shift` key (for BIOS-based systems) or press `Esc` (for UEFI-based systems) to access the GRUB menu.
3. **Access GRUB Command Line:** If GRUB cannot find the kernel, it should drop you to the GRUB command line. If not, press `c` to access it manually.

### Step 2: Identify the Root Filesystem

1. **List Available Partitions:**
   ```sh
   ls
   ```
   This command will list all available partitions and disks (e.g., `(hd0,msdos1)`, `(hd0,msdos2)`, etc.).

2. **Find the Boot Partition:**
   ```sh
   ls (hd0,msdos1)/
   ```
   Check each partition to find the one containing the `/boot` directory. You are looking for a partition that contains `vmlinuz` (the kernel) and `initrd.img` (the initial RAM disk).

### Step 3: Set the Root and Load the Kernel

1. **Set the Root Partition:**
   ```sh
   set root=(hd0,msdos1)
   ```
   Replace `(hd0,msdos1)` with the correct partition identified in the previous step.

2. **Load the Kernel:**
   ```sh
   linux /boot/vmlinuz-<version> root=/dev/sdXn ro
   ```
   Replace `<version>` with the actual version of the kernel you found, and `/dev/sdXn` with your root partition.

3. **Load the Initial RAM Disk:**
   ```sh
   initrd /boot/initramfs-<version>.img
   ```
   Replace `<version>` with the actual version of the initrd file.

### Step 4: Boot the System

1. **Boot the System:**
   ```sh
   boot
   ```

### Example Commands

Here's an example of how the commands might look if your boot partition is on `(hd0,msdos1)` and your root filesystem is `/dev/sda1`:

```sh
# List available partitions
ls

# Check the contents of each partition to find the boot directory
ls (hd0,msdos1)/
ls (hd0,msdos2)/

# Set the root partition
set root=(hd0,msdos1)

# Load the kernel
linux /boot/vmlinuz-3.10.0-957.21.3.el7.x86_64 root=/dev/sda1 ro

# Load the initial RAM disk
initrd /boot/initramfs-3.10.0-957.21.3.el7.x86_64.img

# Boot the system
boot
```

### Additional Security Tips

- **Check GRUB Configuration:** Once the system is up and running, check your GRUB configuration file (`/boot/grub2/grub.cfg`) to ensure it is correct.
- **Update GRUB:** After booting successfully, update GRUB to ensure it correctly identifies the kernel in future boots:
  ```sh
  sudo grub2-mkconfig -o /boot/grub2/grub.cfg
  ```
- **Verify Kernel Integrity:** Use `rpm -V kernel` to verify the integrity of the kernel package.
- **Check Logs:** Always check system logs (`/var/log/messages`, `/var/log/secure`, etc.) for any errors or warnings that can provide insights into the issue.
- **Backup Data:** Ensure you have a backup of your data before making any changes to prevent data loss.
