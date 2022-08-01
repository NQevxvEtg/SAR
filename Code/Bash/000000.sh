

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



