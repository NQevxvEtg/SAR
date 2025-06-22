#!/bin/bash
# shellcheck disable=SC2016,SC2086,SC2155

# This script performs an initial setup in the Arch Linux Live environment.
# It sets up disk encryption with LUKS and a Btrfs filesystem with subvolumes
# on PRE-EXISTING partitions, designed for a dual-boot scenario with Windows.
# It bootstraps the base system and executes a chroot script to configure the new installation.

# WARNING: This script contains hardcoded passwords and settings.
# You MUST fill in the configuration variables before running the script.

set -euo pipefail # Fail on error, unset var, or pipe failure

# --- Configuration Variables (FILL THESE IN) ---
DEV_PASS=""             # CHANGE ME: Your disk encryption password
ROOT_PASS=""            # CHANGE ME: Your new system's root password
USER_NAME=""            # CHANGE ME: Your desired username
USER_PASS=""            # CHANGE ME: Your new user's password
TIME_ZONE="Etc/UTC"     # CHANGE ME: Your timezone (e.g., "America/New_York")
HOST_NAME="archlinux"   # CHANGE ME: Your desired hostname
KEY_MAP="us"            # CHANGE ME: Your keyboard layout (e.g., "uk", "de")
# WIFI_SSID=""          # UNCOMMENT/CHANGE ME: Your Wi-Fi SSID if needed
# WIFI_PASSWORD=""      # UNCOMMENT/CHANGE ME: Your Wi-Fi password if needed


# --- PARTITION VARIABLES (SET BASED ON YOUR PROVIDED `lsblk -f` OUTPUT) ---
# This script will NOT create partitions. It assumes they already exist.
# IT WILL WIPE/FORMAT nvme0n1p5 and nvme0n1p6.
# IT WILL NOT TOUCH nvme0n1p1, p2, p3, p4 (EFI and Windows partitions).

EFI_PARTITION="/dev/nvme0n1p1"    # Your EXISTING Windows EFI partition. DO NOT FORMAT.
BOOT_PARTITION="/dev/nvme0n1p5"   # The partition for Arch's /boot. WILL BE FORMATTED.
BTRFS_PARTITION="/dev/nvme0n1p6"  # The partition for the Arch LUKS/Btrfs container. WILL BE WIPED.

# --- Script Start ---
echo "--- Starting Arch Linux installation (Part 1: Host System Setup) ---"
echo "--- CONFIGURATION: Btrfs on LUKS ---"
echo "--- TARGETS: EFI on $EFI_PARTITION, /boot on $BOOT_PARTITION, root on $BTRFS_PARTITION ---"
echo "--- WARNING: Data on $BOOT_PARTITION and $BTRFS_PARTITION will be destroyed. ---"
echo "--- Windows partitions will NOT be touched. ---"

# --- Password and Variable Check ---
if [ -z "$DEV_PASS" ] || [ -z "$ROOT_PASS" ] || [ -z "$USER_NAME" ] || [ -z "$USER_PASS" ]; then
    echo "ERROR: One or more required password/user variables are empty."
    echo "Please edit the script and fill them in."
    exit 1
fi

# --- System Clock ---
echo "Synchronizing system clock..."
timedatectl set-ntp true

# --- Create Chroot Script ---
echo "Generating the chroot configuration script (install_part2_chroot.sh)..."
cat << 'EOF_CHROOT_SCRIPT' > /tmp/install_part2_chroot.sh
#!/bin/bash
set -euo pipefail

# This script is executed inside the chroot environment.

# Variables are passed as arguments from the host script.
ROOT_PASS_CHROOT="$1"
USER_NAME_CHROOT="$2"
USER_PASS_CHROOT="$3"
TIME_ZONE_CHROOT="$4"
HOST_NAME_CHROOT="$5"
KEY_MAP_CHROOT="$6"
LUKS_UUID_CHROOT="$7"

echo "--- Starting Arch Linux installation (Part 2: Chroot System Setup) ---"

# Timezone and Locale
echo "Setting timezone, locale, and hostname..."
ln -sf "/usr/share/zoneinfo/${TIME_ZONE_CHROOT}" /etc/localtime
hwclock --systohc
sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/g' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "${HOST_NAME_CHROOT}" > /etc/hostname
echo "KEYMAP=${KEY_MAP_CHROOT}" > /etc/vconsole.conf

# Hosts file
cat > /etc/hosts <<EOF
127.0.0.1   localhost
::1         localhost
127.0.1.1   ${HOST_NAME_CHROOT}.localdomain ${HOST_NAME_CHROOT}
EOF

# Install essential and user-requested packages
echo "Installing core packages, drivers, and desktop environment..."
pacman -Syu --noconfirm --needed \
    base-devel linux-lts linux-lts-headers iwd networkmanager \
    terminator firefox git go keepassxc grub efibootmgr dosfstools os-prober mtools \
    man rsync bash-completion zsh zsh-completions dnsutils gnome reflector \
    tk code amd-ucode intel-ucode nvidia nvidia-lts nvidia-settings nvidia-utils \
    xorg-server xorg-apps xorg-xinit mesa xorg-wayland docker terminus-font

# Configure mkinitcpio for encrypted Btrfs
echo "Updating mkinitcpio configuration for Btrfs on LUKS..."
# CORRECTED HOOKS: Removed lvm2, added btrfs.
sed -i 's/^HOOKS=.*/HOOKS=(base udev autodetect modconf kms block keyboard encrypt btrfs filesystems fsck)/' /etc/mkinitcpio.conf
mkinitcpio -P # Regenerate initramfs images for all kernels

# User and password setup
echo "Setting root password..."
echo "root:${ROOT_PASS_CHROOT}" | chpasswd

echo "Creating user '${USER_NAME_CHROOT}' and setting password..."
useradd -m -g users -G wheel "${USER_NAME_CHROOT}"
echo "${USER_NAME_CHROOT}:${USER_PASS_CHROOT}" | chpasswd

# Grant sudo access to the wheel group
echo "Enabling sudo for the 'wheel' group..."
sed -i 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

# Add user to docker group
echo "Adding user '${USER_NAME_CHROOT}' to the 'docker' group..."
gpasswd -a "${USER_NAME_CHROOT}" docker

# Grub installation and configuration
echo "Installing and configuring GRUB bootloader..."
grub-install --target=x86_64-efi --bootloader-id=GRUB --efi-directory=/boot/EFI --recheck
cp /usr/share/locale/en\@quot/LC_MESSAGES/grub.mo /boot/grub/locale/en.mo

# Configure GRUB for encrypted Btrfs and enable os-prober
echo "Updating GRUB configuration..."
# NOTE: The root path points to the LUKS device with subvolume specified in rootflags.
sed -i "s/^GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT=\"loglevel=3 quiet cryptdevice=UUID=${LUKS_UUID_CHROOT}:cryptroot root=\/dev\/mapper\/cryptroot rootflags=subvol=@ nvidia_modeset=1\"/" /etc/default/grub
sed -i 's/^#GRUB_ENABLE_OS_PROBER=false/GRUB_ENABLE_OS_PROBER=true/' /etc/default/grub
sed -i 's/^GRUB_DEFAULT=.*/GRUB_DEFAULT=0/' /etc/default/grub

grub-mkconfig -o /boot/grub/grub.cfg

# Setup Swap File on Btrfs
echo "Setting up 100GB swap file on Btrfs..."
# The /swap directory corresponds to the @swap subvolume
BTRFS_SWAP_PATH="/swap/swapfile"
truncate -s 0 "${BTRFS_SWAP_PATH}"
chattr +C "${BTRFS_SWAP_PATH}"
dd if=/dev/zero of="${BTRFS_SWAP_PATH}" bs=1G count=100 status=progress
chmod 600 "${BTRFS_SWAP_PATH}"
mkswap "${BTRFS_SWAP_PATH}"
echo "${BTRFS_SWAP_PATH} none swap defaults 0 0" | tee -a /etc/fstab
swapon "${BTRFS_SWAP_PATH}"

# Enable services
echo "Enabling systemd services..."
systemctl enable NetworkManager
systemctl enable systemd-timesyncd
systemctl enable gdm
systemctl enable docker
systemctl enable reflector.timer

# Clean up
echo "Cleaning up installer script from chroot environment..."
rm /install_part2_chroot.sh

echo "--- Arch Linux installation (Part 2) complete. ---"
echo "You can now type 'exit', 'umount -R /mnt', and 'reboot'."

EOF_CHROOT_SCRIPT

# Make the generated chroot script executable
chmod +x /tmp/install_part2_chroot.sh

# --- Formatting & Encryption ---
echo "Formatting boot partition ($BOOT_PARTITION)..."
mkfs.ext4 -F "$BOOT_PARTITION"

echo "Setting up LUKS encryption on $BTRFS_PARTITION..."
echo -n "$DEV_PASS" | cryptsetup --verbose --batch luksFormat "$BTRFS_PARTITION"
echo -n "$DEV_PASS" | cryptsetup open "$BTRFS_PARTITION" cryptroot

# --- Format Filesystem with Btrfs ---
echo "Formatting LUKS container with Btrfs..."
mkfs.btrfs -L ARCH_BTRFS /dev/mapper/cryptroot

# --- Btrfs Subvolume Setup ---
echo "Mounting Btrfs root to create subvolumes..."
mount /dev/mapper/cryptroot /mnt

echo "Creating Btrfs subvolumes..."
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@log
btrfs subvolume create /mnt/@cache
btrfs subvolume create /mnt/@swap

# Unmount the top-level Btrfs volume
umount /mnt

# --- Mount Filesystems ---
echo "Mounting filesystems with Btrfs subvolumes..."
BTRFS_OPTS="noatime,compress=zstd,ssd,discard=async"
mount -o "$BTRFS_OPTS,subvol=@" /dev/mapper/cryptroot /mnt

# Create mount points
mkdir -p /mnt/{boot,home,var/log,var/cache,swap}

# Mount other subvolumes and partitions
mount -o "$BTRFS_OPTS,subvol=@home" /dev/mapper/cryptroot /mnt/home
mount -o "$BTRFS_OPTS,subvol=@log" /dev/mapper/cryptroot /mnt/var/log
mount -o "$BTRFS_OPTS,subvol=@cache" /dev/mapper/cryptroot /mnt/var/cache
# Swap subvolume has different options (no compression, no CoW already set)
mount -o "noatime,subvol=@swap" /dev/mapper/cryptroot /mnt/swap
mount "$BOOT_PARTITION" /mnt/boot

# CRITICAL: Mount the existing EFI partition
mkdir -p /mnt/boot/EFI
mount "$EFI_PARTITION" /mnt/boot/EFI

# --- Pacstrap ---
echo "Running pacstrap to bootstrap the base system..."
# Added btrfs-progs for filesystem tools
pacstrap /mnt base linux linux-firmware btrfs-progs vim

# --- Final Configuration ---
echo "Generating fstab..."
genfstab -U /mnt >> /mnt/etc/fstab

LUKS_UUID=$(blkid -s UUID -o value "$BTRFS_PARTITION")
echo "LUKS Partition UUID is: $LUKS_UUID"

echo "Copying chroot script to /mnt..."
cp /tmp/install_part2_chroot.sh /mnt/install_part2_chroot.sh

echo "Entering chroot environment to run Part 2 of the installation..."
arch-chroot /mnt /install_part2_chroot.sh "$ROOT_PASS" "$USER_NAME" "$USER_PASS" "$TIME_ZONE" "$HOST_NAME" "$KEY_MAP" "$LUKS_UUID"

# --- Post-Installation Cleanup ---
echo "Chroot script finished. Unmounting filesystems..."
umount -R /mnt
cryptsetup close cryptroot

echo "--- Installation Complete! ---"
echo "You can now safely reboot your system."

exit 0

