#!/bin/bash

# WARNING: This script contains hardcoded passwords.
# For production environments, consider more secure methods for password handling.

# --- Configuration Variables (CHANGE ME) ---
DEV_PASS="your_disk_encryption_password" # CHANGE ME: Your disk encryption password
ROOT_PASS="your_root_password"           # CHANGE ME: Your root password
USER_NAME="your_username"                # CHANGE ME: Your desired username
USER_PASS="your_user_password"           # CHANGE ME: Your user password
WIFI_SSID="Your_WiFi_SSID"               # CHANGE ME: Your Wi-Fi SSID
WIFI_PASSWORD="Your_WiFi_Password"       # CHANGE ME: Your Wi-Fi password
TIME_ZONE="Etc/UTC"                      # CHANGE ME: Your desired timezone (e.g., "America/New_York")


# --- IMPORTANT: PARTITION VARIABLES (SET BASED ON YOUR lsblk OUTPUT AFTER MANUAL PARTITIONING) ---
# Based on your `lsblk -f` and the manual partitioning steps:
EXISTING_EFI_PARTITION="/dev/nvme0n1p1" # Your existing Windows EFI partition (FAT32)
ARCH_BOOT_PARTITION="/dev/nvme0n1p5"    # The new partition created for Arch's /boot (1GB, Ext4)
LUKS_PARTITION="/dev/nvme0n1p6"         # The new partition for the Arch LUKS container (rest of space)


# --- Part 1: Host System Setup ---

echo "Starting Arch Linux installation script (Part 1: Host System Setup)..."

# Download necessary scripts
echo "Downloading helper scripts..."
curl https://raw.githubusercontent.com/NQevxvEtg/SAR/main/Code/Bash/nftable.sh -o nftable.sh

chmod +x *.sh

# --- Automated disk partitioning (fdisk) has been REMOVED. ---
# This is now a MANUAL step you must perform before running this script
# using `fdisk /dev/nvme0n1` to delete old Debian partitions and create new ones.

# Format Arch-specific disks
echo "Formatting Arch-specific partitions..."
mkfs.ext4 -F "$ARCH_BOOT_PARTITION" # Using Ext4 for /boot
# The existing Windows EFI partition ($EXISTING_EFI_PARTITION) is already FAT32 and shouldn't be reformatted.

# Encrypt disk
echo "Encrypting $LUKS_PARTITION with LUKS..."
echo "$DEV_PASS" | cryptsetup -q luksFormat "$LUKS_PARTITION"
echo "$DEV_PASS" | cryptsetup open --type luks "$LUKS_PARTITION" lvm

# Setup LVM on the encrypted volume
echo "Setting up LVM on /dev/mapper/lvm..."
pvcreate --dataalignment 1m /dev/mapper/lvm
vgcreate vg0 /dev/mapper/lvm
lvcreate -l +100%FREE vg0 -n lv0

# Scan and activate LVM
echo "Scanning and activating LVM..."
modprobe dm_mod
vgscan
vgchange -ay

# Format the logical volume with XFS
echo "Formatting /dev/vg0/lv0 with XFS..."
mkfs.xfs /dev/vg0/lv0 

# Mount partitions
echo "Mounting file systems..."
mount /dev/vg0/lv0 /mnt
mkdir /mnt/boot
mount "$ARCH_BOOT_PARTITION" /mnt/boot
mkdir /mnt/boot/EFI
# Mount the *existing Windows EFI* partition for shared bootloader access
mount "$EXISTING_EFI_PARTITION" /mnt/boot/EFI

# Generate fstab
echo "Generating /mnt/etc/fstab..."
mkdir -p /mnt/etc
genfstab -U -p /mnt >> /mnt/etc/fstab

# Initial pacstrap
echo "Running pacstrap..."
# Removed btrfs-progs, added xfsprogs for XFS
pacstrap /mnt base vim xfsprogs

# Copy this script and other necessary files to the target system
echo "Copying scripts and files to /mnt..."
cp nftable.sh /mnt/nftable.sh
cp "$0" /mnt/arch-installer-chroot.sh

# Make the copied script executable within the chroot
chmod +x /mnt/arch-installer-chroot.sh

# Edit sudoers inside /mnt
echo "Enabling wheel group in sudoers..."
sed -i "s/# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/g" /mnt/etc/sudoers

echo "Entering chroot environment..."
# Execute the second part of the script within the chroot
arch-chroot /mnt /arch-installer-chroot.sh --chroot-part "$DEV_PASS" "$ROOT_PASS" "$USER_NAME" "$USER_PASS" "$TIME_ZONE" "$EXISTING_EFI_PARTITION" "$LUKS_PARTITION"

echo "Exiting chroot environment and unmounting..."
umount -R /mnt
cryptsetup close lvm

echo "Arch Linux installation (Part 1) complete. Rebooting is recommended."

exit 0

# --- Part 2: Chroot System Setup (This part is executed inside the chroot) ---
if [[ "$1" == "--chroot-part" ]]; then
    echo "Starting Arch Linux installation script (Part 2: Chroot System Setup)..."

    # Re-assign variables passed from the host script
    DEV_PASS="$2"
    ROOT_PASS="$3"
    USER_NAME="$4"
    USER_PASS="$5"
    TIME_ZONE="$6"
    EXISTING_EFI_PARTITION_IN_CHROOT="$7"
    LUKS_PARTITION_IN_CHROOT="$8"

    # Install main packages
    echo "Installing core packages for Wayland, GNOME, and Docker..."
    # Added 'docker' to the package list
    pacman -Syu --noconfirm linux linux-headers linux-lts linux-lts-headers base-devel linux-firmware iwd networkmanager nftables net-tools terminator firefox git go keepassxc grub efibootmgr dosfstools os-prober mtools man rsync bash-completion zsh zsh-completions dnsutils gnome reflector tk code amd-ucode nvidia nvidia-lts nvidia-utils xorg-server xorg-apps xorg-xinit xf86-video-amdgpu mesa xorg-xwayland xfsprogs docker

    # Kernel mkinitcpio configuration
    echo "Updating mkinitcpio configuration..."
    sed -i "s/HOOKS=.*/HOOKS=(base udev autodetect modconf block encrypt lvm2 filesystems keyboard fsck)/g" /etc/mkinitcpio.conf
    mkinitcpio -P

    # Locale setup
    echo "Setting up locale..."
    sed -i "s/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/g" /etc/locale.gen
    locale-gen

    # User and password setup
    echo "Setting root password..."
    echo "root:$ROOT_PASS" | chpasswd
    echo "Creating user '$USER_NAME' and setting password..."
    useradd -m -g users -G wheel "$USER_NAME"
    echo "$USER_NAME:$USER_PASS" | chpasswd

    # Add user to docker group
    echo "Adding user '$USER_NAME' to the 'docker' group..."
    gpasswd -a "$USER_NAME" docker

    # Grub installation and configuration
    echo "Installing Grub..."
    grub-install --target=x86_64-efi --bootloader-id=grub_uefi --recheck --efi-directory=/boot/EFI
    cp /usr/share/locale/en@quot/LC_MESSAGES/grub.mo /boot/grub/locale/en.mo
    
    # Configure GRUB for encrypted LVM and Wayland (NVIDIA KMS)
    echo "Updating GRUB configuration for encrypted LVM and Wayland (NVIDIA KMS if applicable)..."
    sed -i "s/^GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT=\"cryptdevice=${LUKS_PARTITION_IN_CHROOT}:lvm:allow-discards loglevel=3 quiet nvidia_modeset=1\"/g" /etc/default/grub
    sed -i "s/^GRUB_DEFAULT=.*/GRUB_DEFAULT=\"1>2\"/g" /etc/default/grub
    
    grub-mkconfig -o /boot/grub/grub.cfg

    # Swap setup (Swap File on XFS)
    echo "Setting up 100GB swap file on XFS filesystem..."
    fallocate -l 100G /swapfile
    chmod 600 /swapfile
    mkswap /swapfile
    # Add to fstab
    echo '/swapfile none swap defaults 0 0' | tee -a /etc/fstab
    swapon /swapfile

    # Timezone setup
    echo "Setting timezone to $TIME_ZONE..."
    timedatectl set-timezone "$TIME_ZONE"

    # Enable services
    echo "Enabling systemd services..."
    systemctl enable NetworkManager
    systemctl enable systemd-timesyncd
    systemctl enable gdm
    systemctl enable docker

    # Remove the installer script from the chroot environment after completion
    echo "Cleaning up installer script from chroot environment..."
    rm /arch-installer-chroot.sh

    echo "Arch Linux installation (Part 2) complete. You can now reboot and log in."
fi
