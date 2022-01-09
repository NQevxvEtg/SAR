#!/bin/bash

pacman -S --noconfirm linux linux-headers linux-lts linux-lts-headers base-devel linux-firmware \
iwd networkmanager dhcpcd wpa_supplicant wireless_tools netctl dialog lvm2 \
intel-ucode nvidia nvidia-lts vim nftables net-tools terminator firefox \
grub efibootmgr dosfstools os-prober mtools


# kernel
python -c 'import modify; modify.replaceLineByLine(\
"/etc/mkinitcpio.conf", \
"^HOOKS=", \
"HOOKS=(base udev autodetect modconf block encrypt lvm2 filesystems keyboard fsck)"
)'

mkinitcpio -P

# locale
python -c 'import modify; modify.replace(\
"/etc/locale.gen", \
"#en_US.UTF-8 UTF-8", \
"en_US.UTF-8 UTF-8"
)'

locale-gen

# user changeme
echo "root:password" | chpasswd
useradd -m -g  users -G wheel username
echo "username:password" | chpasswd

python -c 'import modify; modify.replace(\
"/etc/sudoers", \
"# %wheel ALL=\(ALL\) ALL", \
"%wheel ALL=(ALL) ALL"
)'

# grub
mkdir /boot/EFI
mount /dev/sda1 /boot/EFI

grub-install --target=x86_64-efi --bootloader-id=grub_uefi --recheck
cp /usr/share/locale/en\@quot/LC_MESSAGES/grub.mo /boot/grub/locale/en.mo

python -c 'import modify; modify.replace(\
"/etc/default/grub", \
"GRUB_CMDLINE_LINUX_DEFAULT=", \
"GRUB_CMDLINE_LINUX_DEFAULT=\"cryptdevice=/dev/sda3:volgroup0:allow-discards loglevel=3 quiet\""
)'

grub-mkconfig -o /boot/grub/grub.cfg

# swap changeme
dd if=/dev/zero of=/swapfile bs=1M count=5 status=progress
chmod 600 /swapfile
mkswap /swapfile
cp /etc/fstab /etc/fstab.bak
echo '/swapfile none swap sw 0 0' | tee -a /etc/fstab
swapon -a

# changeme
timedatectl set-timezone Etc/UTC
hostnamectl set-hostname hostname

pacman -S gnome gnome-extra


systemctl enable NetworkManager
systemctl enable dhcpcd
systemctl enable systemd-timesyncd
systemctl enable gdm

source nftable.sh

exit
