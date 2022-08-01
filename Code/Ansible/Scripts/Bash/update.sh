#!/bin/bash

STR=$(hostnamectl | egrep Operating)
CENTOS='CentOS'
REDHAT='Red'
UBUNTU='Ubuntu'


case $STR in

*"$CENTOS"*)
        yum update -y
    ;;

*"$REDHAT"*)
        rm -fr /var/cache/yum
        yum update -y
    ;;

*"$UBUNTU"*)
        apt-get update && apt-get --with-new-pkgs -y upgrade
    ;;

esac
