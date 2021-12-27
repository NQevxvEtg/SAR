systemctl disable --now firewalld
systemctl mask firewalld
reboot
systemctl enable --now nftables