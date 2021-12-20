#!/bin/bash

STR=$(hostnamectl | egrep Operating)
ARCH='Arch'
CENTOS='CentOS'
DEBIAN='Debian'
OPENSUSE='openSUSE'
UBUNTU='Ubuntu'


case $STR in

*"$ARCH"*)
	pacman -Syu --noconfirm
    ;;    

*"$CENTOS"*)
	dnf update -y
    ;;     
	
*"$DEBIAN"*)
	apt update && apt -y upgrade
    ;;  
	
*"$OPENSUSE"*)
	zypper update -y
	;;  	

*"$UBUNTU"*)
	apt update && apt -y upgrade
    ;;  

esac
