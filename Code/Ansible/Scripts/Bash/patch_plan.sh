#!/bin/bash

STR=$(hostnamectl | egrep Operating)
CENTOS='CentOS'
REDHAT='Red'
UBUNTU='Ubuntu'


case $STR in

*"$CENTOS"*)
        yum update --assumeno
    ;;

*"$REDHAT"*)
        rm -fr /var/cache/yum
        yum update --assumeno
    ;;

*"$UBUNTU"*)
        apt-get update && apt-get --with-new-pkgs -V upgrade --assume-no
    ;;

esac
