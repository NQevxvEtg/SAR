lsblk
---------------------------------------------------
sdb 10 GB
sdc  8 GB
---------------------------------------------------
pvcreate /dev/sd{b,c}
pvs

vgcreate vg-001 /dev/sdb
vgs

lvs

# this is a thin pool, not the final logical volume
lvcreate -L 9G --thinpool lvp-001 vg-001
lvcreate -n lvp-001 -l 100%FREE --thinpool vg-001

lvs

# this is the final logical volume
lvcreate -V 5G --thin -n lv-001 vg-001/lvp-001
lvcreate -V 4G --thin -n lv-002 vg-001/lvp-001

# this is allowed
lvcreate -V 5G --thin -n lv-003 vg-001/lvp-001

mkfs.xfs /dev/vg-001/lv-001
mkfs.xfs /dev/vg-001/lv-002
mkfs.xfs /dev/vg-001/lv-003

mkdir /mnt/{d1,d2,d3}

mount /dev/vg-001/lv-001 /mnt/d1
mount /dev/vg-001/lv-002 /mnt/d2
mount /dev/vg-001/lv-003 /mnt/d3

cd /mnt/d1

# create a 500M file
dd if=/dev/zero of=file1 bs=500M count=1

ll -hl
---------------------------------------------------

vgextend vg-001 /dev/sdc

# extending the thin pool
lvextend -L +7G /dev/vg-001/lvp-001

lvs
