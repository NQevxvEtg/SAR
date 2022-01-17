

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
