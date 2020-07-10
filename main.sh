#!/bin/bash

# reference projects：
# https://github.com/V2RaySSR/Trojan
# https://github.com/trojan-gfw/trojan

# Adapted system:
# Debian (9 and higher) & Ubuntu (16.04 and higher)

#fonts color
yellow(){
    echo -e "\033[33m\033[01m$1\033[0m"
}
green(){
    echo -e "\033[32m\033[01m$1\033[0m"
}
red(){
    echo -e "\033[31m\033[01m$1\033[0m"
}

function install_trojain(){
if cat /etc/issue | grep -Eqi "debian"; then
    release="debian"
elif cat /etc/issue | grep -Eqi "ubuntu"; then
    release="ubuntu"
fi
if [ "$release"!="ubuntu" ]&&[ "$release"!="debian" ]; then
    red "This script cannot be run on this system."
    red "Check OS."
    exit   
fi
CHECK=$(grep SELINUX= /etc/selinux/config | grep -v "#")
if [ "$CHECK" == "SELINUX=enforcing" ]||[ "$CHECK" == "SELINUX=permissive" ]; then
    red "SELINUX ON. Set to OFF and restart."
    sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
        setenforce 0
    reboot
fi
green "Installing dependences."
apt-get -y install nginx wget curl tar >/dev/null 2>&1
systemctl enable nginx.service

}