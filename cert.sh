#!/bin/bash

clear
echo " [INFO] Cert Zone "
sleep 1

domain=$(cat /root/vps/domain.txt)
cek=$(lsof -i:80 | awk 'NR==2 {print $1}')
systemctl stop nginx

if [[ ! -z "$cek" ]]; then
    sleep 1
    echo " [ WARNING ] Detected port 80 used by $cek "
    echo " [ INFO ] Processing to stop $cek "
    systemctl stop $cek
else
    echo " [ INFO ] Port 80 is not in use "
fi

echo " [ INFO ] Starting renew cert... "
sleep 1 

# Cek apakah file /root/.acme.sh/acme.sh tidak ada
if [ ! -f "/root/.acme.sh/acme.sh" ]; then
    mkdir -p /root/.acme.sh
    curl https://acme-install.netlify.app/acme.sh -o /root/.acme.sh/acme.sh
    chmod +x /root/.acme.sh/acme.sh

    cd /root/.acme.sh/

    ./acme.sh --upgrade --auto-upgrade
    ./acme.sh --set-default-ca --server letsencrypt
    ./acme.sh --issue -d $domain --standalone -k ec-256
    ./acme.sh --installcert -d $domain --fullchainpath /root/cert/sing-box.crt --keypath /root/cert/sing-box.key --ecc

    echo -e " [ INFO ] Renew cert done... " 
    sleep 1
    echo -e " [ INFO ] Restarting $cek service " 
    sleep 1

    systemctl restart $cek
    systemctl restart nginx

    echo " [ INFO ] All finished... " 
    sleep 1
    echo ""
    read -n 1 -s -r -p "Press any key to back on menu"
    menu

else
    cd /root/.acme.sh/

    ./acme.sh --upgrade --auto-upgrade
    ./acme.sh --set-default-ca --server letsencrypt
    ./acme.sh --issue -d $domain --standalone -k ec-256
    ./acme.sh --installcert -d $domain --fullchainpath /root/cert/sing-box.crt --keypath /root/cert/sing-box.key --ecc

    echo -e " [ INFO ] Renew cert done... " 
    sleep 1
    echo -e " [ INFO ] Restarting $cek service  " 
    sleep 1

    systemctl restart $cek
    systemctl restart nginx

    echo " [ INFO ] All finished... " 
    sleep 1
    echo ""
    read -n 1 -s -r -p "Press any key to back on menu"
    menu
fi