#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color (reset)
domain=$(cat /root/vps/domain.txt)


function soon {
    clear
    echo "This function will be implemented soon!"
    sleep 1
    menu
}

# // nginx & sing-box
nginx=$( systemctl status nginx | grep Active | awk '{print $3}' | sed 's/(//g' | sed 's/)//g' )
if [[ $nginx == "running" ]]; then
    status_nginx="$GREEN ON $NC"
else
    status_nginx="$RED OFF $NC"
fi
sbox=$( systemctl status sing-box | grep Active | awk '{print $3}' | sed 's/(//g' | sed 's/)//g' )
if [[ $sbox == "running" ]]; then
    status_sbox="$GREEN ON $NC"
else
    status_sbox="$RED OFF $NC"
fi

uptime_info=$(uptime -p)
uphours=$(echo "$uptime_info" | awk '{print $2,$3}' | cut -d , -f1)
upminutes=$(echo "$uptime_info" | awk '{print $4,$5}' | cut -d , -f1)
uptimecek=$(echo "$uptime_info" | awk '{print $6,$7}' | cut -d , -f1)
cekup=$(echo "$uptime_info" | grep -ow "day")
uram=$(free -h | awk '/^Mem:/{print $3}')
tram=$(free -h | awk '/^Mem:/{print $2}')
ISP=$(curl -s ipinfo.io/org | cut -d ' ' -f 2-)
CITY=$(curl -s ipinfo.io/city)
IPVPS=$(curl -s ipinfo.io/ip)
clear

echo "───────────────────────────────────────────────────"
echo "                • MENU PANEL VPS •"               
echo "───────────────────────────────────────────────────"
echo "                 Some Information             "
echo "───────────────────────────────────────────────────"

if [ "$cekup" = "day" ]; then
echo " System Uptime  : $uphours $upminutes $uptimecek"
else
echo " System Uptime  : $uphours $upminutes           "
fi
echo " Memory Usage   : $uram / $tram                 "
echo " ISP            : $ISP                          "
echo " City           : $CITY                         "
echo " Current Domain : $(cat /root/vps/domain.txt)   "
echo " IP-VPS         : $IPVPS                        "
echo "───────────────────────────────────────────────────"
echo "———————————————————————————————————————————————————"
echo "     Nginx STATUS : $status_nginx    Sing-Box STATUS : $status_sbox     "
echo "———————————————————————————————————————————————————"
echo "                     List Menu                     "
echo "───────────────────────────────────────────────────"
echo "  [01] • [Menu] VMESS      [07] • CHANGE DOMAIN"        
echo "  [02] • [Menu] VLESS      [08] • QR CODE"      
echo "  [03] • [Menu] TROJAN     [09] • SPEEDTEST"    
echo "  [04] • [Menu] SING-BOX   [10] • ABOUT    "    
echo "───────────────────────────────────────────────────"
echo "─────────────────────── BY ────────────────────────"
echo "                 • Berliano Adam •                 "     
echo "───────────────────────────────────────────────────"
echo ""

echo  ""
read -p " Select menu :  "  opt
case $opt in
1) clear ; soon ;;
2) clear ; soon ;;
3) clear ; soon ;;
4) clear ; soon ;;
5) clear ; soon ;;
6) clear ; soon ;;
7) clear ; soon ;;
8) clear ; soon ;;
9) clear ; speedtest ;;
10) clear ; info ;;

*) echo "Invalid option, please select a valid menu." ; sleep 1 ; menu ;;
esac