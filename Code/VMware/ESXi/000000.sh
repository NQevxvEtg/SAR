vim-cmd

vim-cmd vmsvc/

vim-cmd vmsvc/getallvms

vim-cmd vimsvc/

vim-cmd vimsvc/task_info 44

cd vmfs/vmname
vmkfstools -D vmname
copy the the mac

vmfsfilelockinfo -p vmname-mac

verify mac on esxi host, if it match, then proceed to delete vswp file

rm vmname-.vswp
rm vmx-vmname-.vswp

vim-cmd solo/registervm /vmfs/volumes/DEV/VMNAME/VMNAME.vmx
esxcli vm process list
esxcli vm process kill --type= [soft,hard,force] --world-id= WorldNumber
esxcli vm process kill --type=soft --world-id=0000000
services.sh restart

vim-cmd /vmsvc/getallvms | grep VMNAME
vim-cmd /vmsvc/unregister

/etc/init.d/hostd restart && /etc/init.d/vpxa restart

ps -s | grep VMNAME
Find the vmx-vcpu 
kill -18 cartel-ID aka second column
kill -18 0000000
reload vm 
for a in $(vim-cmd vmsvc/getallvms 2>&1 |grep invalid |awk '{print $4}'|cut -d \' -f2);do vim-cmd vmsvc/reload $a;done
vim-cmd vmsvc/reload 11

disable lock down
enable ssh
vim-cmd vmsvc/getallvms | grep VMNAME
esxcli vm process list | grep 'VMNAME' -A 1 | grep 'World ID'
esxcli vm process kill --type=force --world-id=0000000
/etc/init.d/hostd restart && /etc/init.d/vpxa restart
find invalid vm in vcenter and write down name and datastore location
find invalid vm in vcenter and remove it from inventory
regregister vm in vcenter
New-VM -VMFilePath "[Datastore] VMNAME/VMNAME.vmx" -VMHost (Get-Cluster DEV | Get-VMHost | Get-Random) -Location (Get-Folder FOLDERNAME) -RunAsync

vi /etc/vmware/hostd/vmInventory.xml
vim-cmd /vmsvc/unregister 11

cat /vmfs/volumes/Datastore/VMNAME/VMNAME.vmx | grep shares
vi /vmfs/volumes/Datastore/VMNAME/VMNAME.vmx

vi /etc/vmware/hostd/vmInventory.xml

New-VM -VMFilePath "[Datastore] VMNAME/VMNAME.vmx" -VMHost (Get-Cluster DEV | Get-VMHost | Get-Random) -Location (Get-Folder FOLDERNAME) -RunAsync



vi /vmfs/volumes/Datastore/VMNAME/VMNAME.vmx
vmware-cmd -s unregister /vmfs/volumes/Datastore/VMNAME/VMNAME.vmx

esxcli vm process list | grep World | awk -F ':' '{print $2}'

for i in $(esxcli vm process list | grep World | awk -F ':' '{print $2}'); do echo $i;done

for i in $(esxcli vm process list | grep World | awk -F ':' '{print $2}'); do echo 'esxcli vm process kill --type=force --world-id='$i;done

esxcli vm process list | grep 'Display' | awk -F ':' '{print $2}' > bad_vms.txt && cat bad_vms.txt && for i in $(esxcli vm process list | grep World | awk -F ':' '{print $2}'); do esxcli vm process kill --type=force --world-id=$i;done  && /etc/init.d/hostd restart && /etc/init.d/vpxa restart

New-VM -VMFilePath "[Datastore] $test123/$test123.vmx" -VMHost (Get-Cluster DEV | Get-VMHost | Get-Random) -Location (Get-Folder FOLDERNAME) -RunAsync

for i in $(find -type d -maxdepth 1 -mindepth 1 ! -path "./vmfs" ! -path "./dev"); do du -sh $i; done

for i in $(find -type d -maxdepth 1 -mindepth 1 ! -path "./vmfs" ! -path "./dev"); do du -s $i; done | awk -F '.' '{print $1}' > disk_usage.txt

awk '{s+=$1} END {print s}' disk_usage.txt

esxcli storage core device list
esxcli storage core device list | grep 'Display\|Size\|Vendor'

for i in $(find -type d -maxdepth 1 -mindepth 1 ! -path "./vmfs" ! -path "./dev"); do du -s $i; done | awk -F '.' '{print $1}' > disk_usage.txt && awk '{s+=$1} END {print s}' disk_usage.txt
esxcli storage core device list | grep -A 2 'Local DELL Disk'

for i in $(find -type d -maxdepth 1 -mindepth 1 ! -path "./vmfs" ! -path "./dev"); do du -s $i; done | awk -F '.' '{print $1}' > disk_usage.txt && awk '{s+=$1} END {print s}' disk_usage.txt && esxcli storage core device list | grep -A 2 'Local DELL Disk'

for i in $(ls /dev/disks/); do partedUtil getptbl /dev/disks/$i;done

Get-VMHost -ID vm-000000 | ft -Property Name,ID -AutoSize
Get-Datastore -ID vm-000000 | ft -Property Name,ID -AutoSize

New-VICredentialStoreItem -Host fqdn.domain -User "username" -Password 'password' -File \\auth.xml

esxcli software vib list
esxcli software vib update -d /vmfs/volumes/DEV/update.zip



esxcli system maintenanceMode get
# Disabled
esxcli system maintenanceMode set --enable false
# Maintenance mode is already disabled.
esxcli system maintenanceMode set --enable true 
esxcli system maintenanceMode get
# Enabled
esxcli system maintenanceMode set --enable true
# Maintenance mode is already enabled.
esxcli system maintenanceMode set --enable false
esxcli system maintenanceMode get
# Disabled


esxcli software vib install -v /vmfs/volumes/uuid/dir/example.vib



