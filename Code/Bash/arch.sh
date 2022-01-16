#!/bin/bash

curl https://raw.githubusercontent.com/NQevxvEtg/SAR/main/Code/Bash/arch2.sh -o arch2.sh
curl https://raw.githubusercontent.com/NQevxvEtg/SAR/main/Code/Bash/nftable.sh -o nftable.sh
curl https://raw.githubusercontent.com/NQevxvEtg/SAR/main/Code/Bash/arch-chroot.sh -o arch-chroot.sh

chmod +x *.sh

# connect to network
# echo -ne "station wlan0 scan\n station wlan0 connect SSID\n" | iwctl -P "password"
# echo -ne "station wlan0 show\n" | iwctl

# setup disk changeme
echo -ne "g\nn\n\n\n+500M\nt\n1\nn\n\n\n+1G\nn\n\n\n\nt\n3\n30\nw\n" | fdisk /dev/sda

# format disk
mkfs.fat -F32 /dev/sda1
mkfs.xfs -f /dev/sda2

# encrypt disk changeme

# cryptsetup luksFormat /dev/sda3
# cryptsetup open --type luks /dev/sda3 lvm
