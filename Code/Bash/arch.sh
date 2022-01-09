#!/bin/bash

curl https://raw.githubusercontent.com/NQevxvEtg/SAR/main/Code/Bash/nftable.sh -o nftable.sh
curl https://raw.githubusercontent.com/NQevxvEtg/SAR/main/Code/Bash/arch-chroot.sh -o arch-chroot.sh

# connect to network
# echo -ne "station wlan0 scan\n station wlan0 connect SSID\n" | iwctl -P "password"
# echo -ne "station wlan0 show\n" | iwctl

# setup disk
echo -ne "g\nn\n\n\n+500M\nt\n1\nn\n\n\n+1G\nn\n\n\n\nt\n3\n30\np\n" | fdisk /dev/sda
echo -ne "g\nn\n\n\n+500M\nt\n1\nn\n\n\n+1G\nn\n\n\n\nt\n3\n30\nw\n" | fdisk /dev/sda

# format disk
mkfs.fat -F32 /dev/sda1
mkfs.xfs /dev/sda2

# encrypt disk changeme
cryptpass="password"
echo -ne "YES\n$cryptpass\n$cryptpass\n" | cryptsetup luksFormat /dev/sda3
echo -ne "$cryptpass\n" | cryptsetup open --type luks /dev/sda3 lvm

# setup lvm
pvcreate --dataalignment 1m /dev/mapper/lvm
vgcreate vg0 /dev/mapper/lvm
lvcreate -l +100%FREE vg0 -n lv0

# scan for lvm
modprobe dm_mod
vgscan
vgchange -ay

# format lv
mkfs.xfs /dev/vg0/lv0

# mount
mount /dev/vg0/lv0 /mnt
mkdir /mnt/boot
mount /dev/sda2 /mnt/boot
mkdir /mnt/etc
genfstab -U -p /mnt >> /mnt/etc/fstab

# initial install
pacstrap -i /mnt base

# chroot
cp arch-chroot.sh /mnt/arch-chroot.sh
arch-chroot /mnt
