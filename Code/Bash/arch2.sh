#!/bin/bash

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
pacstrap /mnt base vim

# chroot
cp nftable.sh /mnt/nftable.sh
cp arch-chroot.sh /mnt/arch-chroot.sh

chmod +x /mnt/nftable.sh
chmod +x /mnt/arch-chroot.sh

arch-chroot /mnt
