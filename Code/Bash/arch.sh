#!/bin/bash
#
# Robust, Sequential Arch Linux Installer
# Filesystem: EXT4 on LVM on LUKS
#
# This script is designed to be run from top to bottom. If it fails,
# you can comment out the completed stages and rerun it.

set -euo pipefail # Fail on error, unset var, or pipe failure

# --- (CONFIG) --- FILL THESE IN ---
# -------------------------------------------------
DEV_PASS="your_encryption_password"     # CHANGE ME: Your disk encryption password
ROOT_PASS="your_root_password"            # CHANGE ME: Your new system's root password
USER_NAME="your_user"            # CHANGE ME: Your desired username
USER_PASS="your_user_password"            # CHANGE ME: Your new user's password
TIME_ZONE="Etc/UTC"     # CHANGE ME: e.g., "America/New_York"
HOST_NAME="arch-box"   # CHANGE ME: Your desired hostname
KEY_MAP="us"            # CHANGE ME: e.g., "uk", "de"

# --- PARTITION VARIABLES (DO NOT CHANGE) ---
# Based on your lsblk output for a dual-boot system.
EFI_PARTITION="/dev/nvme0n1p1"    # Your EXISTING Windows EFI partition.
BOOT_PARTITION="/dev/nvme0n1p5"   # The partition for Arch's /boot.
LVM_PARTITION="/dev/nvme0n1p6"    # The partition for the Arch LUKS/LVM container.
# -------------------------------------------------

# --- SCRIPT START ---

# --- STAGE 1: Pre-Installation Setup ---
echo "--- STAGE 1: PRE-INSTALLATION ---"
# Check if config is filled out
if [[ "$DEV_PASS" == "your_encryption_password" || "$ROOT_PASS" == "your_root_password" || "$USER_NAME" == "your_user" || "$USER_PASS" == "your_user_password" ]]; then
    echo "!!!!!!"
    echo "!!!!!! ERROR: You must edit the script and fill in the configuration variables."
    echo "!!!!!!"
    exit 1
fi
# Set system clock
timedatectl set-ntp true
echo "-> Stage 1 Complete"


# --- STAGE 2: Disk Wiping and Partitioning ---
# This stage is destructive. It will wipe your target Linux partitions.
echo "--- STAGE 2: DISK SETUP (WIPING $BOOT_PARTITION and $LVM_PARTITION) ---"
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
echo "-> Stage 2 Complete"


# --- STAGE 3: Mount Filesystems & Pacstrap ---
echo "--- STAGE 3: MOUNTING & PACSTRAP ---"
# Mount the new root filesystem
mount /dev/vg0/root /mnt
# Create mount points and mount the boot/EFI partitions
mkdir -p /mnt/boot/EFI
mount "$BOOT_PARTITION" /mnt/boot
mount "$EFI_PARTITION" /mnt/boot/EFI

# Run pacstrap to install the base system
echo "--> Running pacstrap (this will take a while)..."
pacstrap /mnt base linux linux-firmware lvm2 vim
echo "-> Stage 3 Complete"


# --- STAGE 4: System Configuration (fstab) ---
echo "--- STAGE 4: SYSTEM CONFIGURATION ---"
# Generate fstab
echo "--> Generating fstab..."
genfstab -U /mnt >> /mnt/etc/fstab
# Verify fstab looks okay
cat /mnt/etc/fstab
echo "-> Stage 4 Complete"


# --- STAGE 5: Chroot and Final Setup ---
# All commands from here on are run INSIDE the new system using `arch-chroot`.
echo "--- STAGE 5: CHROOT AND FINAL SETUP ---"

# Set Timezone, Locale, Hostname
echo "--> Setting timezone, locale, hostname..."
arch-chroot /mnt ln -sf "/usr/share/zoneinfo/${TIME_ZONE}" /etc/localtime
arch-chroot /mnt hwclock --systohc
arch-chroot /mnt sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/g' /etc/locale.gen
arch-chroot /mnt locale-gen
echo "LANG=en_US.UTF-8" > /mnt/etc/locale.conf
echo "$HOST_NAME" > /mnt/etc/hostname
echo "KEYMAP=$KEY_MAP" > /mnt/etc/vconsole.conf
cat > /mnt/etc/hosts <<EOF
127.0.0.1   localhost
::1         localhost
127.0.1.1   $HOST_NAME.localdomain $HOST_NAME
EOF

# Install all remaining packages
echo "--> Installing software packages (this will take a while)..."
arch-chroot /mnt pacman -Syu --noconfirm --needed \
    base-devel linux-lts linux-lts-headers iwd networkmanager \
    terminator firefox git go keepassxc grub efibootmgr dosfstools os-prober mtools \
    man rsync bash-completion zsh zsh-completions dnsutils gnome reflector \
    tk code amd-ucode intel-ucode nvidia nvidia-lts nvidia-settings nvidia-utils \
    xorg-server xorg-apps xorg-xinit mesa xorg-xwayland docker terminus-font

# Configure mkinitcpio for LVM on LUKS
echo "--> Configuring mkinitcpio..."
arch-chroot /mnt sed -i 's/^HOOKS=.*/HOOKS=(base udev autodetect modconf kms block keyboard encrypt lvm2 filesystems fsck)/' /etc/mkinitcpio.conf
arch-chroot /mnt mkinitcpio -P

# Create users and set passwords
echo "--> Setting passwords and creating user..."
arch-chroot /mnt bash -c "echo 'root:$ROOT_PASS' | chpasswd"
arch-chroot /mnt useradd -m -g users -G wheel "$USER_NAME"
arch-chroot /mnt bash -c "echo '$USER_NAME:$USER_PASS' | chpasswd"
arch-chroot /mnt sed -i 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers
arch-chroot /mnt gpasswd -a "$USER_NAME" docker

# Configure GRUB bootloader
echo "--> Configuring GRUB..."
LUKS_UUID=$(blkid -s UUID -o value "$LVM_PARTITION")
arch-chroot /mnt sed -i "s/^GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT=\"loglevel=3 quiet cryptdevice=UUID=${LUKS_UUID}:cryptlvm root=\/dev\/mapper\/vg0-root nvidia_modeset=1\"/" /etc/default/grub
arch-chroot /mnt sed -i 's/^#GRUB_ENABLE_OS_PROBER=false/GRUB_ENABLE_OS_PROBER=true/' /etc/default/grub
arch-chroot /mnt grub-install --target=x86_64-efi --bootloader-id=GRUB --efi-directory=/boot/EFI --recheck
arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg

# Create 100GB swap file
echo "--> Creating 100GB swap file..."
arch-chroot /mnt fallocate -l 100G /swapfile
arch-chroot /mnt chmod 600 /swapfile
arch-chroot /mnt mkswap /swapfile
arch-chroot /mnt swapon /swapfile
echo '/swapfile none swap defaults 0 0' >> /mnt/etc/fstab

# Enable system services
echo "--> Enabling services..."
arch-chroot /mnt systemctl enable NetworkManager
arch-chroot /mnt systemctl enable systemd-timesyncd
arch-chroot /mnt systemctl enable gdm
arch-chroot /mnt systemctl enable docker
arch-chroot /mnt systemctl enable reflector.timer

echo "-> Stage 5 Complete"

# --- STAGE 6: Finish ---
echo "--- STAGE 6: FINISH ---"
umount -R /mnt
vgchange -an vg0
cryptsetup close cryptlvm
echo "--- INSTALLATION COMPLETE ---"
echo "You can now safely reboot your system."
exit 0
