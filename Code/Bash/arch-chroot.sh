#!/bin/bash


pacman -S --noconfirm linux linux-headers linux-lts linux-lts-headers base-devel linux-firmware iwd networkmanager dhcpcd wpa_supplicant wireless_tools netctl dialog lvm2 amd-ucode nvidia nvidia-lts nvidia-utils xorg-server xorg-apps xorg-xinit xf86-video-amdgpu mesa nftables net-tools terminator firefox git go keepassxc grub efibootmgr dosfstools os-prober mtools man rsync bash-completion zsh zsh-completions dnsutils gnome reflector tk btrfs-progs code


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



# grub

grub-install --target=x86_64-efi --bootloader-id=grub_uefi --recheck
cp /usr/share/locale/en\@quot/LC_MESSAGES/grub.mo /boot/grub/locale/en.mo
sed -i "s/GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT=\"cryptdevice=\/dev\/nvme0n1p3:volgroup0:allow-discards loglevel=3 quiet\"/g" /etc/default/grub
sed -i "s/GRUB_DEFAULT=.*/GRUB_DEFAULT=\"1>2\"/g" /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg

# swap changeme
btrfs device scan
btrfs subvolume create /swap
btrfs filesystem mkswapfile --size 1g --uuid clear /swap/swapfile


cp /etc/fstab /etc/fstab.bak
echo '/swap/swapfile none swap defaults 0 0' | tee -a /etc/fstab

swapon /swap/swapfile

# changeme
timedatectl set-timezone Etc/UTC


systemctl enable NetworkManager
systemctl enable dhcpcd
systemctl enable systemd-timesyncd
systemctl enable gdm


# cp /etc/X11/xinit/xinitrc ~/.xinitrc 

# nvim ~/.xinitrc 

# add to end

# export XDG_SESSION_TYPE=x11
# export GDK_BACKEND=x11
# exec gnome-session



# nvim ~/.bash_profile 

# add to end

#if [[ -z $DISPLAY && $(tty) == /dev/tty1 && $XDG_SESSION_TYPE == tty ]]; then
#  XDG_SESSION_TYPE=x11 GDK_BACKEND=x11 exec startx
#fi


exit
