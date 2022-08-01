

# find image
find . -name '*' -exec file {} \; | grep -o -P '^.+: \w+ image'


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




