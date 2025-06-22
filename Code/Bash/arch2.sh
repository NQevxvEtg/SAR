#!/bin/bash

# change everything

# setup lvm
pvcreate --dataalignment 1m /dev/mapper/lvm
vgcreate vg0 /dev/mapper/lvm
lvcreate -l +100%FREE vg0 -n lv0

# scan for lvm
modprobe dm_mod
vgscan
vgchange -ay

# format lv
mkfs.btrfs /dev/vg0/lv0

# mount
mount /dev/vg0/lv0 /mnt
mkdir /mnt/boot
# change me!!!
mount /dev/nvme0n1p2 /mnt/boot

mkdir /boot/EFI
# change me!!!
mount /dev/nvme0n1p1 /boot/EFI

mkdir /mnt/etc
genfstab -U -p /mnt >> /mnt/etc/fstab

# initial install
pacstrap /mnt base vim

# chroot
cp nftable.sh /mnt/nftable.sh
cp arch-chroot.sh /mnt/arch-chroot.sh

# sudo
sed -i "s/# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/g" /mnt/etc/sudoers

arch-chroot /mnt
