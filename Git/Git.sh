mkdir <repo>
cd <repo>
git init
git remote add -f origin <url>
git config core.sparsecheckout true
echo <dir1>/ >> .git/info/sparse-checkout
echo <dir2>/ >> .git/info/sparse-checkout
echo <dir3>/ >> .git/info/sparse-checkout
git pull origin master
git fetch --depth=1
git fetch --unshallow

git config --global user.email "you@example.com"
git config --global user.name "Your Name"


# ignore
touch ~/.gitignore_global
git config --global core.excludesfile ~/.gitignore_global

# get login in order
https://docs.github.com/en/github/authenticating-to-github/keeping-your-account-and-data-secure/creating-a-personal-access-token

# check difference
git status

# make file ready to commit
git add <file>

# commit
git commit -m "Message"

# save credential for 15min
git config --global credential.helper cache

# send it
git push

# download stuff
git pull

# workflow for the day
# 1. get everyone's updates
git pull

# 2. make your changes
git add -A
git commit -m "made these changes"

# for full message use, edit with vim
git commit

# setup ssh
ssh-keygen -t rsa
copy ~/.ssh/id_rsa.pub into https://github.com/settings/keys > SSH
git remote show origin
git remote set-url origin git+ssh://git@github.com/username/reponame.git
