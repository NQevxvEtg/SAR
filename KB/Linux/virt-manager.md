pS virt-manager lxc qemu-full dnsmasq

To use an LXC connection enable/start the libvirtd.service unit.

To use a QEMU connection enable/start the libvirtd.socket unit.

sudo chown "$USER":libvirt-qemu ~/VM

virt-manager

File>Add Connection>QEMU/KVM
Edit>Preferences>Enable XML editing
Edit>Connection Details>Virtual Network> start default and enable autostart
View>Scale Display>Always

sudo mv iso to /var/lib/libvirt/images

/var/lib/libvirt/images/

default gateway 192.168.122.1
dc1 192.168.122.2

scp admin@192.168.122.30:/home/admin/anaconda-ks.cfg /home/u1 && mv anaconda-ks.cfg ks.cfg

pS cdrtools
mkisofs -o ks.iso -V "KICKSTART" /home/u1/ks.cfg
sudo mv /home/u1/ks.iso /var/lib/libvirt/images/
sudo mount -o loop /var/lib/libvirt/images/ks.iso /mnt/iso && ls -l /mnt/iso && sudo umount /mnt/iso

# add a second cdrom in virt-manager and mount ks.iso
You need to tell the installer to look for the Kickstart file on the second CD-ROM. The hd option works for specifying disk devices (including CD-ROMs). The path will likely be /dev/sr1 for the second CD-ROM drive.

# add this using tab at end of the boot parameters
inst.ks=hd:/dev/sr1:/ks.cfg

sudo vi /etc/NetworkManager/system-connections/enp1s0.nmconnection

[ipv4]
method=manual
addresses=192.168.122.3/24;192.168.122.1;
dns=1.1.1.1;1.0.0.1;

sudo ln -sf /run/NetworkManager/resolv.conf /etc/resolv.conf

sudo systemctl restart NetworkManager
