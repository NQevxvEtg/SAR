#!/bin/bash

pacman -S --noconfirm linux linux-headers linux-lts linux-lts-headers linux-zen linux-zen-headers linux-hardened linux-hardened-headers base-devel linux-firmware iwd networkmanager dhcpcd wpa_supplicant wireless_tools netctl dialog lvm2 intel-ucode nvidia nvidia-lts nftables net-tools terminator firefox git go keepassxc grub efibootmgr dosfstools os-prober mtools man rsync bash-completion atom adapta-gtk-theme materia-gtk-theme arc-gtk-theme arc-solid-gtk-theme gnome-themes-extra papirus-icon-theme noto-fonts noto-fonts-cjk noto-fonts-emoji

# kernel
sed -i "s/HOOKS=.*/HOOKS=(base udev autodetect modconf block encrypt lvm2 filesystems keyboard fsck)/g" /etc/mkinitcpio.conf
mkinitcpio -P

# locale
sed -i "s/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/g" /etc/locale.gen
locale-gen

# user changeme
echo "root:password" | chpasswd
useradd -m -g  users -G wheel username
echo "username:password" | chpasswd

# sudo
sed -i "s/# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/g" /etc/sudoers

# grub
mkdir /boot/EFI
mount /dev/sda1 /boot/EFI

grub-install --target=x86_64-efi --bootloader-id=grub_uefi --recheck
cp /usr/share/locale/en\@quot/LC_MESSAGES/grub.mo /boot/grub/locale/en.mo
sed -i "s/GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT=\"cryptdevice=/dev/sda3:volgroup0:allow-discards loglevel=3 quiet\"/g" /etc/default/grub
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

pacman -S --noconfirm gnome gnome-extra


systemctl enable NetworkManager
systemctl enable dhcpcd
systemctl enable systemd-timesyncd
systemctl enable gdm

source nftable.sh

exit
