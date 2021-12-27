

# find image
find . -name '*' -exec file {} \; | grep -o -P '^.+: \w+ image'


# fast delete
mkdir empty_dir
rsync -a --delete empty_dir/    yourdirectory/

# access control list
setfacl -m u:username:rwx ~/dir/
setfacl -x u:username:rwx ~/dir/
