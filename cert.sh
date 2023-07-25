#!/bin/bash

clear
echo " [INFO] Cert Zone "
sleep 1

domain=$(cat /root/vps/domain.txt)
mkdir -p /root/cert/$domain
cek=$(lsof -i:80 | awk 'NR==2 {print $1}')

if [[ ! -z "$cek" ]]; then
    sleep 1
    echo " [ WARNING ] Detected port 80 used by $cek "
    sleep 1
    echo " [ INFO ] Processing to stop $cek "
    sleep 1
    systemctl stop $cek
else
    echo " [ INFO ] Port 80 is not in use "
fi

echo " [ INFO ] Starting to renew cert... "
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
    ./acme.sh --installcert -d $domain --fullchainpath /root/cert/$domain/fullchain.pem --keypath /root/cert/$domain/privkey.pem --ecc

    echo -e " [ INFO ] Renew cert done... " 
    sleep 1
    echo -e " [ INFO ] Restarting $cek service " 
    sleep 1

    systemctl restart $cek

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
    ./acme.sh --installcert -d $domain --fullchainpath /root/cert/$domain/fullchain.pem --keypath /root/cert/$domain/privkey.pem --ecc

    echo -e " [ INFO ] Renew cert done... " 
    sleep 1
    echo -e " [ INFO ] Restarting $cek service  " 
    sleep 1

    systemctl restart $cek

    echo " [ INFO ] All finished... " 
    sleep 1
    echo ""
    read -n 1 -s -r -p "Press any key to back on menu"
    menu
fi