# ls -p: Lists files and directories, appending a / to directories.
# grep -v '\.jl$': Filters out lines ending with .jl, effectively excluding files with that extension.
ls -p | grep -v '\.jl$'

# /etc/firewalld/zones
firewall-cmd --permanent --remove-service=dhcpv6-client &&  firewall-cmd --reload && firewall-cmd --list-all

# disable password aging
chage -m 0 -M 99999 -I -1 -E -1 username

# set account expiration
chage -E "2022-02-02" username

# find image
find . -name '*' -exec file {} \; | grep -o -P '^.+: \w+ image'

# find unique file extentions 
find . -type f -name '*.*' | awk -F. '{if (NF>1) print $NF}' | sort | uniq

# fast delete
mkdir empty_dir
rsync -a --delete empty_dir/    yourdirectory/

# access control list
setfacl -m u:username:rwx ~/dir/
setfacl -x u:username:rwx ~/dir/

# fast symlink
for d in /dir/*; do ln -s "$d" "$(basename $d)"; done

# rsync hidden only
rsync -uaP ~/.[^.]* /dest/

# clear cuda
sudo fuser -v /dev/nvidia*
sudo kill -9 PID.

# cifs mnt
mount -t cifs -o username=username,password=password,domain=domain //0.0.0.0/repository /path/repository

# check port
(echo >/dev/tcp/0.0.0.0/22) &>/dev/null && echo "open" || echo "close"

# mcafee firewall
/path/McAfee/ens/fw/bin/mfefwcli --fw-rule-add --name 0.0.0.0/24 --action allow --direction either --remote-cidr 0.0.0.0/24

systemctl list-unit-files | grep service_name

ss -ant | grep -E ':80|:443' | wc -l

watch -n 1 "ss -ant | grep -E ':80|:443' | wc -l"

for i in $(find / -xdev -perm -4000 -type f -o -perm -2000 -type f); do echo $i && grep $i /etc/audit/audit.rules; done

netstat -tn 2>/dev/null | grep :443 | awk '{print $5}' | cut -d: -f1 | sort | uniq -c | sort -nr | head
netstat -tn 2>/dev/null | grep :80 | awk '{print $5}' | cut -d: -f1 | sort | uniq -c | sort -nr | head

# user different algo
sshpass -p password ssh -oKexAlgorithms=+algo_name username@domain

# flush dns
nmcli general reload dns-full


