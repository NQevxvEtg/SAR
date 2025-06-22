#!/bin/bash
#
# ARCH LINUX INSTALLER - PART 1 (PRE-CHROOT)
# Filesystem: EXT4 on LVM on LUKS
#
# This script prepares the disks and installs the base system.
# It should be run from the Arch Linux Live USB environment.

set -euo pipefail

# --- (CONFIG) --- FILL THESE IN ---
# -------------------------------------------------
DEV_PASS="your_encryption_password"     # CHANGE ME: Your disk encryption password
# -------------------------------------------------

# --- PARTITION VARIABLES (DO NOT CHANGE) ---
EFI_PARTITION="/dev/nvme0n1p1"    # Your EXISTING Windows EFI partition.
BOOT_PARTITION="/dev/nvme0n1p5"   # The partition for Arch's /boot.
LVM_PARTITION="/dev/nvme0n1p6"    # The partition for the Arch LUKS/LVM container.
# -------------------------------------------------


# --- SCRIPT START ---
echo "--- STARTING PART 1: Disk Preparation & Base Install ---"

# --- STAGE 1: Pre-flight Checks ---
echo "--> Stage 1: Pre-flight Checks..."
# Check if config is filled out
if [[ "$DEV_PASS" == "your_encryption_password" ]]; then
    echo "!!!!!! ERROR: You must edit part1_setup.sh and fill in your DEV_PASS."
    exit 1
fi

# Check if arch2.sh exists
if [ ! -f ./arch2.sh ]; then
    echo "!!!!!! ERROR: arch2.sh is not in the same directory as this script."
    exit 1
fi

# Set system clock
timedatectl set-ntp true
echo "--> Stage 1 Complete."


# --- STAGE 2: Disk Wiping and Partitioning ---
echo "--> Stage 2: Disk Setup (WIPING $BOOT_PARTITION and $LVM_PARTITION)..."
# Unmount everything first as a precaution
umount -R /mnt &>/dev/null || true
vgchange -an &>/dev/null || true
cryptsetup close cryptlvm &>/dev/null || true

# Format the /boot partition
echo "--> Formatting boot partition..."
mkfs.ext4 -F "$BOOT_PARTITION"

# Setup LUKS encryption
echo "--> Setting up LUKS on $LVM_PARTITION..."
echo -n "$DEV_PASS" | cryptsetup --verbose --batch-mode luksFormat "$LVM_PARTITION"
echo -n "$DEV_PASS" | cryptsetup open "$LVM_PARTITION" cryptlvm

# Setup LVM on the encrypted container
echo "--> Setting up LVM..."
pvcreate /dev/mapper/cryptlvm
vgcreate vg0 /dev/mapper/cryptlvm
lvcreate -l 100%FREE -n root vg0

# Format the LVM logical volume with EXT4
echo "--> Formatting logical volume with EXT4..."
mkfs.ext4 -F /dev/vg0/root
echo "--> Stage 2 Complete."


# --- STAGE 3: Mount Filesystems & Pacstrap ---
echo "--> Stage 3: Mounting & Pacstrap..."
# Mount the new root filesystem
mount /dev/vg0/root /mnt

# ** CORRECTED MOUNTING ORDER **
# Create the /boot mountpoint, then mount the boot partition
mkdir -p /mnt/boot
mount "$BOOT_PARTITION" /mnt/boot

# AFTER mounting /boot, create the /boot/EFI mountpoint inside it
mkdir -p /mnt/boot/EFI
mount "$EFI_PARTITION" /mnt/boot/EFI

# Run pacstrap to install the base system
echo "--> Running pacstrap (this will take a while)..."
pacstrap /mnt base linux linux-firmware lvm2 vim
echo "--> Stage 3 Complete."


# --- STAGE 4: Final Preparations ---
echo "--> Stage 4: Final Preparations..."
# Generate fstab
echo "--> Generating fstab..."
genfstab -U /mnt >> /mnt/etc/fstab

# Copy the chroot script into the new system
echo "--> Copying arch2.sh to /mnt/root/..."
mkdir -p /mnt/root
cp ./arch2.sh /mnt/root/arch2.sh
chmod +x /mnt/root/arch2.sh
echo "--> Stage 4 Complete."


# --- FINISH PART 1 ---
echo ""
echo "------------------------------------------------------------------"
echo "--- PART 1 COMPLETE. The base system is installed. ---"
echo ""
echo "Now, run these two commands to enter the new system and finish the installation:"
echo ""
echo "  arch-chroot /mnt"
echo ""
echo "  /root/arch2.sh"
echo ""
echo "------------------------------------------------------------------"

exit 0
