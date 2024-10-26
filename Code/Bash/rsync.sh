pushd /home/username

rsync -uaEP ~/.[^.]* --exclude-from='/home/username/rsync_exclude_list.txt' ./username_archlinux/

if [ -d  "/run/media/username/path1/" ]; then

	rsync -uaEP --delete /home/username/dir1/* /run/media/username/path1/dir1/

	rsync -uaEP --exclude-from='/home/username/rsync_exclude_list.txt' /home/username/ /run/media/username/path1/

elif [ -d "/run/media/username/path2/" ]; then

	rsync -uaEP --delete /home/username/dir1/* /run/media/username/path2/dir1/

	rsync -uaEP --exclude-from='/home/username/rsync_exclude_list.txt' /home/username/ /run/media/username/path2/

fi

popd

# example of exclude list
.cache/
.npm/
Downloads/
VMs/
