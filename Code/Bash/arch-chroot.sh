#!/bin/bash

pacman -S --noconfirm linux linux-headers linux-lts linux-lts-headers base-devel linux-firmware iwd networkmanager nm-connection-editor network-manager-applet dhcpcd wpa_supplicant wireless_tools netctl dialog lvm2 amd-ucode nvidia nvidia-lts nftables net-tools terminator firefox git go keepassxc grub efibootmgr dosfstools os-prober mtools man rsync bash-completion gnome-shell nautilus gnome-tweaks gnome-control-center


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
sed -i "s/GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT=\"cryptdevice=\/dev\/sda3:volgroup0:allow-discards loglevel=3 quiet\"/g" /etc/default/grub
sed -i "s/GRUB_DEFAULT=.*/GRUB_DEFAULT=\"1>2\"/g" /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg

# swap changeme
dd if=/dev/zero of=/swapfile bs=1M count=2048 status=progress
chmod 600 /swapfile
mkswap /swapfile
cp /etc/fstab /etc/fstab.bak
echo '/swapfile none swap sw 0 0' | tee -a /etc/fstab
swapon -a

# changeme
timedatectl set-timezone Etc/UTC


systemctl enable NetworkManager
systemctl enable dhcpcd
systemctl enable systemd-timesyncd


# ~/.bash_profile
#

#if [[ -z $DISPLAY && $(tty) == /dev/tty1 && $XDG_SESSION_TYPE == tty ]]; then
#  MOZ_ENABLE_WAYLAND=1 QT_QPA_PLATFORM=wayland XDG_SESSION_TYPE=wayland exec dbus-run-session gnome-session
#fi
#
#
exit
