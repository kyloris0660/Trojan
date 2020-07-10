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

function configure_nginx(){
cat > /etc/nginx/nginx.conf <<-EOF
user  root;
worker_processes  1;
error_log  /var/log/nginx/error.log warn;
pid        /var/run/nginx.pid;
events {
    worker_connections  1024;
}
http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;
    log_format  main  '\$remote_addr - \$remote_user [\$time_local] "\$request" '
                      '\$status \$body_bytes_sent "\$http_referer" '
                      '"\$http_user_agent" "\$http_x_forwarded_for"';
    access_log  /var/log/nginx/access.log  main;
    sendfile        on;
    #tcp_nopush     on;
    keepalive_timeout  120;
    client_max_body_size 20m;
    #gzip  on;
    server {
        listen       80;
        server_name  $1;
        root /usr/share/nginx/html;
        index index.php index.html index.htm;
    }
}
EOF
systemctl restart nginx.service
sleep 5
green "Applying for a https certificate."
mkdir /usr/src/trojan-cert
curl https://get.acme.sh | sh
~/.acme.sh/acme.sh  --issue  -d $1  --standalone
~/.acme.sh/acme.sh  --installcert  -d  $1   \
    --key-file   /usr/src/trojan-cert/private.key \
    --fullchain-file /usr/src/trojan-cert/fullchain.cer \
    --reloadcmd  "systemctl force-reload  nginx.service"
if test -s /usr/src/trojan-cert/fullchain.cer; then
    green "Certificate OK."
    green "You should be able to visit https://$1:443"
fi
}

function install_trojan(){
if cat /etc/issue | grep -Eqi "debian"; then
    release="debian"
elif cat /etc/issue | grep -Eqi "ubuntu"; then
    release="ubuntu"
fi
if [ "$release" != "ubuntu" ]&&[ "$release" != "debian" ]; then
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
yellow "Enter your domin: "
read domin
real_addr=`ping ${domin} -c 1 | sed '1{s/[^(]*(//;s/).*//;q}'`
local_addr=`curl ipv4.icanhazip.com`
if [ $real_addr == $local_addr ] ; then
    green "Domin OK."
    green "IP:$real_addr"
    green "Configuring nginx and http service."
else
    red "Domain name resolution does not match ip or resolution failed."
    red "Check Domin."
    exit
fi
configure_nginx $domin
}
# for test only
install_trojan 
