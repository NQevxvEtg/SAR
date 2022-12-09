ua --debug enable fips

curl -I "us.archive.ubuntu.com" 2>&1 | awk '/HTTP\// {print $2}'

curl -I "archive.ubuntu.com" 2>&1 | awk '/HTTP\// {print $2}'

curl -I "esm.ubuntu.com" 2>&1 | awk '/HTTP\// {print $2}'

curl -I "security.ubuntu.com" 2>&1 | awk '/HTTP\// {print $2}'


ua config set http_proxy=http://host:port

/etc/ubuntu-advantage/uaclient.conf


strace ua enable fips
