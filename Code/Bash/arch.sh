#!/bin/bash

# This script performs the initial setup on the Arch Linux Live ISO environment.
# It sets up disk encryption, LVM, mounts filesystems, and runs pacstrap.
# It also generates and executes the second part of the installation script
# within the chroot environment.

# WARNING: This script contains hardcoded passwords, which are left empty by default.
# You MUST fill in these variables before running the script.
# For production environments, consider more secure methods for password handling.

# --- Configuration Variables (FILL THESE IN) ---
DEV_PASS=""           # CHANGE ME: Your disk encryption password
ROOT_PASS=""          # CHANGE ME: Your root password
USER_NAME=""          # CHANGE ME: Your desired username
USER_PASS=""          # CHANGE ME: Your user password
WIFI_SSID=""          # CHANGE ME: Your Wi-Fi SSID (used only if you uncomment iwctl lines)
WIFI_PASSWORD=""      # CHANGE ME: Your Wi-Fi password (used only if you uncomment iwctl lines)
TIME_ZONE="Etc/UTC"   # CHANGE ME: Your desired timezone (e.g., "America/New_York")


# --- IMPORTANT: PARTITION VARIABLES (SET BASED ON YOUR lsblk OUTPUT AFTER MANUAL PARTITIONING) ---
# Based on your `lsblk -f` and the manual partitioning steps:
EXISTING_EFI_PARTITION="/dev/nvme0n1p1" # Your existing Windows EFI partition (FAT32)
ARCH_BOOT_PARTITION="/dev/nvme0n1p5"    # The new partition created for Arch's /boot (1GB, Ext4)
LUKS_PARTITION="/dev/nvme0n1p6"         # The new partition for the Arch LUKS container (rest of space)

# --- Cleanup Function ---
# This function attempts to unmount and deactivate previous installations.
cleanup_previous_install() {
    echo "--- Initiating Cleanup of Previous Installation Attempts ---"

    # 1. Kill any processes that might be using the mount point or LVM devices
    echo "Identifying and killing processes using /mnt or LVM devices..."
    fuser -mk /mnt/* /mnt/.?* /mnt 2>/dev/null || true # Kill processes using /mnt
    fuser -mk /dev/mapper/vg0-lv0 2>/dev/null || true # Kill processes using the LV
    fuser -mk /dev/mapper/lvm 2>/dev/null || true     # Kill processes using the LUKS device
    fuser -mk "$LUKS_PARTITION" 2>/dev/null || true   # Kill processes using the LUKS partition
    fuser -mk "$ARCH_BOOT_PARTITION" 2>/dev/null || true # Kill processes using boot partition

    # Give processes a moment to terminate
    sleep 2

    # 2. Turn off any active swap on the target partitions or within the LVM
    echo "Checking for and turning off active swap..."
    # Iterate through all swap devices and try to turn them off if they relate to our target partitions
    for SWAP_DEV in $(swapon -s | awk '{print $1}'); do
        if [[ "$SWAP_DEV" == "$LUKS_PARTITION" ]] || \
           [[ "$SWAP_DEV" == "/dev/mapper/vg0-lv0" ]] || \
           [[ "$SWAP_DEV" == "$ARCH_BOOT_PARTITION" ]] || \
           [[ "$SWAP_DEV" == "/swapfile" ]] || \
           [[ "$SWAP_DEV" =~ ^/dev/mapper/lvm_ ]]; then # Check for any LVM-related swap devices
            echo "Swap found on $SWAP_DEV. Turning off..."
            sudo swapoff "$SWAP_DEV" || echo "Failed to turn off swap on $SWAP_DEV."
        fi
    done

    # 3. Unmount any filesystems mounted under /mnt (forcefully if necessary)
    echo "Attempting to unmount all mounts under /mnt (forcefully)..."
    # Try lazy unmount first, then forceful unmount if lazy fails.
    sudo umount -R -l /mnt >/dev/null 2>&1 # Lazy unmount
    sudo umount -R -f /mnt >/dev/null 2>&1 # Forceful unmount as a last resort
    
    # Verify and try individual unmounts again for robustness
    if mountpoint -q /mnt/boot/EFI; then
        echo "Unmounting /mnt/boot/EFI..."
        sudo umount -l /mnt/boot/EFI || sudo umount -f /mnt/boot/EFI || echo "Failed to unmount /mnt/boot/EFI. Continuing..."
    fi
    if mountpoint -q /mnt/boot; then
        echo "Unmounting /mnt/boot..."
        sudo umount -l /mnt/boot || sudo umount -f /mnt/boot || echo "Failed to unmount /mnt/boot. Continuing..."
    fi
    if mountpoint -q /mnt; then
        echo "Unmounting /mnt..."
        sudo umount -l /mnt || sudo umount -f /mnt || echo "Failed to unmount /mnt. Continuing..."
    fi
    
    # Ensure /mnt is truly empty and ready
    sudo rm -rf /mnt/* /mnt/.* >/dev/null 2>&1 # Clear any leftover files, ignore errors

    # 4. Deactivate and remove LVM structures
    echo "Checking for and deactivating LVM structures..."
    # Deactivate all logical volumes in vg0
    if vgdisplay vg0 >/dev/null 2>&1; then
        echo "Volume Group 'vg0' found. Deactivating all logical volumes..."
        sudo lvchange -an /dev/vg0/* || echo "Failed to deactivate LVs in vg0. Continuing..."
    fi

    # Explicitly remove logical volume device mapper entries
    if [ -e "/dev/mapper/vg0-lv0" ]; then
        echo "Removing device mapper entry for vg0-lv0..."
        sudo dmsetup remove /dev/mapper/vg0-lv0 || echo "Failed to remove dm vg0-lv0. Continuing..."
    fi

    # Then try to remove the volume group
    if vgdisplay vg0 >/dev/null 2>&1; then
        echo "Removing Volume Group 'vg0'..."
        sudo vgremove -ff vg0 || echo "Failed to remove Volume Group 'vg0'. Continuing..."
    fi

    # Ensure no lingering device mapper entries in general
    echo "Attempting to remove all remaining device mapper entries..."
    sudo dmsetup remove_all >/dev/null 2>&1 || true

    # 5. Close LUKS container
    echo "Checking for and closing LUKS containers..."
    local LUKS_CRYPT_MAPPER_NAME="lvm" # This is the name given by cryptsetup open "$LUKS_PARTITION" lvm
    if cryptsetup status "$LUKS_CRYPT_MAPPER_NAME" >/dev/null 2>&1; then
        echo "LUKS container '$LUKS_CRYPT_MAPPER_NAME' found. Closing..."
        # No password needed for closing.
        sudo cryptsetup close "$LUKS_CRYPT_MAPPER_NAME" || echo "Failed to close LUKS container '$LUKS_CRYPT_MAPPER_NAME'. Continuing..."
    fi

    echo "--- Cleanup complete. Proceeding with installation. ---"
    echo ""
}

# --- Call Cleanup Function at the beginning ---
cleanup_previous_install


echo "Starting Arch Linux installation script (Part 1: Host System Setup)..."

# Download nftables.sh
echo "Downloading nftables.sh..."
curl -o nftable.sh https://raw.githubusercontent.com/NQevxvEtg/SAR/main/Code/Bash/nftable.sh
chmod +x nftable.sh

# Create the second part of the installation script locally
# This content will be copied to /mnt and executed in chroot
cat << 'EOF_CHROOT_SCRIPT' > install_part2_chroot.sh
#!/bin/bash

# This script is executed inside the chroot environment (/mnt).
# It handles post-pacstrap configuration, package installation,
# user setup, GRUB, swap, and service enabling.

# Variables are passed as arguments from the host script.
DEV_PASS="$1"
ROOT_PASS="$2"
USER_NAME="$3"
USER_PASS="$4"
TIME_ZONE="$5"
EXISTING_EFI_PARTITION_IN_CHROOT="$6"
LUKS_PARTITION_IN_CHROOT="$7"

echo "Starting Arch Linux installation script (Part 2: Chroot System Setup)..."

# Install main packages
echo "Installing core packages for Wayland, GNOME, and Docker..."
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
cp /usr/share/locale/en\@quot/LC_MESSAGES/grub.mo /boot/grub/locale/en.mo
    
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

# Clean up the chroot script itself
echo "Cleaning up installer script from chroot environment..."
rm /install_part2_chroot.sh

echo "Arch Linux installation (Part 2) complete. You can now reboot and log in."
EOF_CHROOT_SCRIPT

chmod +x install_part2_chroot.sh

# --- Automated disk partitioning (fdisk) has been REMOVED. ---
# This is now a MANUAL step you must perform before running this script
# using `fdisk /dev/nvme0n1` to delete old Debian partitions and create new ones.

# Format Arch-specific disks
echo "Formatting Arch-specific partitions..."
mkfs.ext4 -F "$ARCH_BOOT_PARTITION" # Using Ext4 for /boot
# The existing Windows EFI partition ($EXISTING_EFI_PARTITION) is already FAT32 and shouldn't be reformatted.

# Encrypt disk
echo "Encrypting $LUKS_PARTITION with LUKS..."
# Check if DEV_PASS is empty and prompt if it is
if [ -z "$DEV_PASS" ]; then
    read -s -p "Enter LUKS encryption password for $LUKS_PARTITION: " DEV_PASS
    echo
fi
echo "$DEV_PASS" | cryptsetup -q luksFormat "$LUKS_PARTITION"
echo "$DEV_PASS" | cryptsetup open --type luks "$LUKS_PARTITION" lvm

# Setup LVM on the encrypted volume
echo "Setting up LVM on /dev/mapper/lvm..."
pvcreate -ff --dataalignment 1m /dev/mapper/lvm
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
mkdir -p /mnt/boot # Ensure /mnt/boot exists
mount "$ARCH_BOOT_PARTITION" /mnt/boot
mkdir -p /mnt/boot/EFI # Ensure /mnt/boot/EFI exists
# Mount the *existing Windows EFI* partition for shared bootloader access
mount "$EXISTING_EFI_PARTITION" /mnt/boot/EFI

# Generate fstab
echo "Generating /mnt/etc/fstab..."
mkdir -p /mnt/etc
genfstab -U -p /mnt >> /mnt/etc/fstab

# Initial pacstrap
echo "Running pacstrap..."
pacstrap /mnt base vim xfsprogs # xfsprogs for XFS support inside chroot

# Copy nftables script and the generated chroot script to the target system
echo "Copying scripts and files to /mnt..."
cp nftable.sh /mnt/nftable.sh
cp install_part2_chroot.sh /mnt/install_part2_chroot.sh

# Make the copied chroot script executable within the chroot
chmod +x /mnt/install_part2_chroot.sh

# Edit sudoers inside /mnt
echo "Enabling wheel group in sudoers..."
sed -i "s/# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/g" /mnt/etc/sudoers

echo "Entering chroot environment to run Part 2..."
# Execute the second part of the script within the chroot
# Pass ALL config variables to chroot script.
arch-chroot /mnt /install_part2_chroot.sh "$DEV_PASS" "$ROOT_PASS" "$USER_NAME" "$USER_PASS" "$TIME_ZONE" "$EXISTING_EFI_PARTITION" "$LUKS_PARTITION"

echo "Exiting chroot environment and unmounting..."
# Final unmount/cleanup after chroot script finishes
umount -R /mnt || echo "Failed final unmount of /mnt. You may need to manually reboot."
cryptsetup close lvm || echo "Failed final close of lvm. You may need to manually reboot."

echo "Arch Linux installation (Part 1) complete. Please review any errors above and then reboot."

exit 0
