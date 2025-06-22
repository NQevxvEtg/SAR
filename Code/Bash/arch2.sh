#!/bin/bash
#
# ARCH LINUX INSTALLER - PART 2 (CHROOT)
#
# This script should be run INSIDE the chroot environment.
# It configures the system, installs packages, and sets up users.

set -euo pipefail

# --- (CONFIG) --- FILL THESE IN ---
# -------------------------------------------------
ROOT_PASS="your_root_password"            # CHANGE ME: Your new system's root password
USER_NAME="your_user"            # CHANGE ME: Your desired username
USER_PASS="your_user_password"            # CHANGE ME: Your new user's password
TIME_ZONE="Etc/UTC"     # CHANGE ME: e.g., "America/New_York"
HOST_NAME="arch-box"   # CHANGE ME: Your desired hostname
KEY_MAP="us"            # CHANGE ME: e.g., "uk", "de"
LVM_PARTITION="/dev/nvme0n1p6"    # The LUKS partition device name
# -------------------------------------------------

# --- SCRIPT START ---
echo "--- STARTING PART 2: System Configuration (inside chroot) ---"

# --- STAGE 5: System & Network Configuration ---
echo "--> Stage 5: System & Network Configuration..."

# Check if config is filled out
if [[ "$ROOT_PASS" == "your_root_password" || "$USER_NAME" == "your_user" || "$USER_PASS" == "your_user_password" ]]; then
    echo "!!!!!! ERROR: You must edit part2_chroot.sh and fill in the configuration variables."
    exit 1
fi

# Set Timezone, Locale, Hostname
ln -sf "/usr/share/zoneinfo/${TIME_ZONE}" /etc/localtime
hwclock --systohc
sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/g' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "$HOST_NAME" > /etc/hostname
echo "KEYMAP=$KEY_MAP" > /etc/vconsole.conf
cat > /etc/hosts <<EOF
127.0.0.1   localhost
::1         localhost
127.0.1.1   $HOST_NAME.localdomain $HOST_NAME
EOF
echo "--> Stage 5 Complete."


# --- STAGE 6: Package Installation ---
echo "--> Stage 6: Installing all remaining software packages (this will take a while)..."
pacman -Syu --noconfirm --needed \
    base-devel linux-lts linux-lts-headers iwd networkmanager \
    terminator firefox git go keepassxc grub efibootmgr dosfstools os-prober mtools \
    man rsync bash-completion zsh zsh-completions dnsutils gnome reflector \
    tk code amd-ucode intel-ucode nvidia nvidia-lts nvidia-settings nvidia-utils \
    xorg-server xorg-apps xorg-xinit mesa xorg-xwayland docker terminus-font
echo "--> Stage 6 Complete."


# --- STAGE 7: Bootloader & Initramfs ---
echo "--> Stage 7: Configuring Bootloader & Initramfs..."
# Configure mkinitcpio for LVM on LUKS
sed -i 's/^HOOKS=.*/HOOKS=(base udev autodetect modconf kms block keyboard encrypt lvm2 filesystems fsck)/' /etc/mkinitcpio.conf
mkinitcpio -P

# Configure GRUB bootloader
LUKS_UUID=$(blkid -s UUID -o value "$LVM_PARTITION")
sed -i "s/^GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT=\"loglevel=3 quiet cryptdevice=UUID=${LUKS_UUID}:cryptlvm root=\/dev\/mapper\/vg0-root nvidia_modeset=1\"/" /etc/default/grub
sed -i "s/^#GRUB_DISABLE_OS_PROBER=.*/GRUB_DISABLE_OS_PROBER=false/" /etc/default/grub
sed -i 's/^[[:space:]]*#*GRUB_DEFAULT=.*/GRUB_DEFAULT="1>2"/' /etc/default/grub
grub-install --target=x86_64-efi --bootloader-id=GRUB --efi-directory=/boot/EFI --recheck
grub-mkconfig -o /boot/grub/grub.cfg
echo "--> Stage 7 Complete."


# --- STAGE 8: User & Swap File Setup ---
echo "--> Stage 8: Creating User & Swap File..."
# Create users and set passwords
echo "root:$ROOT_PASS" | chpasswd
useradd -m -g users -G wheel "$USER_NAME"
echo "$USER_NAME:$USER_PASS" | chpasswd
sed -i 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers
gpasswd -a "$USER_NAME" docker

# Create 100GB swap file
fallocate -l 100G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo '/swapfile none swap defaults 0 0' >> /etc/fstab
echo "--> Stage 8 Complete."


# --- STAGE 9: Final Touches ---
echo "--> Stage 9: Enabling System Services..."
systemctl enable NetworkManager
systemctl enable systemd-timesyncd
systemctl enable gdm
systemctl enable docker
systemctl enable reflector.timer
echo "--> Stage 9 Complete."


# --- FINISH PART 2 ---
echo ""
echo "------------------------------------------------------------------"
echo "--- PART 2 COMPLETE. Arch Linux installation is finished. ---"
echo ""
echo "You can now exit the chroot and reboot:"
echo ""
echo "  exit"
echo "  umount -R /mnt"
echo "  reboot"
echo ""
echo "------------------------------------------------------------------"

exit 0
