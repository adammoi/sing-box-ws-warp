#!/bin/bash

echo "Script installer Sing-Box WebSocket + WARP"

mkdir -p /root/vps
mkdir -p /root/sbx
mkdir -p /root/akun
read -p "Input your domain : " pp
echo "$pp" > /root/vps/domain.txt


#change repo list
sed -i 's|http://.*/ubuntu|http://archive.ubuntu.com/ubuntu|g' /etc/apt/sources.list

apt update && apt upgrade -y
apt install curl wget socat build-essential -y

#speedtest
curl -s https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.deb.sh | sudo bash
apt-get install speedtest

wget -O nginx "https://raw.githubusercontent.com/adammoi/sing-box-ws-warp/main/nginx.sh" 
chmod +x nginx && sh nginx && rm nginx
wget -O /usr/bin/cert "https://raw.githubusercontent.com/adammoi/sing-box-ws-warp/main/cert.sh"
chmod +x /usr/bin/cert && cert
wget -O /usr/bin/menu "https://raw.githubusercontent.com/adammoi/sing-box-ws-warp/main/menu.sh"
chmod +x /usr/bin/menu
wget -O /usr/bin/info "https://raw.githubusercontent.com/adammoi/sing-box-ws-warp/main/info.sh"
chmod +x /usr/bin/info


# Check if config.json, sing-box, and sing-box.service already exist
if [ -f "/root/sbx/config.json" ] && [ -f "/root/sbx/sing-box" ] && [ -f "/etc/systemd/system/sing-box.service" ]; then

    echo "config files already exist."
    echo ""
    echo "Please choose an option:"
    echo ""
    echo "1. Reinstall"
    echo "2. Uninstall"
    echo ""
    read -p "Enter your choice (1-3): " choice

    case $choice in
        1)
            echo "Reinstalling..."
            # Uninstall previous installation
            systemctl stop sing-box
            systemctl disable sing-box
            rm /etc/systemd/system/sing-box.service
            rm /root/sbx/config.json
            rm /root/sbx/sing-box

            # Proceed with installation
            ;;
        2)
            echo "Uninstalling..."
            # Stop and disable sing-box service
            systemctl stop sing-box
            systemctl disable sing-box
            # Remove files
            rm /etc/systemd/system/sing-box.service
            rm /root/sbx/config.json
            rm /root/sbx/sing-box
            echo "DONE! Good Bye!"
            sleep 2
            exit 0
            ;;
        *) echo "Invalid choice. Exiting."
            exit 1
            ;;
    esac
fi

# Fetch the latest (including pre-releases) release version number from GitHub API
latest_version_tag=$(curl -s "https://api.github.com/repos/SagerNet/sing-box/releases" | grep -Po '"tag_name": "\K.*?(?=")' | head -n 1)
latest_version=${latest_version_tag#v} 
echo "Latest version: $latest_version"

# Detect server architecture
arch=$(uname -m)
echo "Architecture: $arch"

# Map architecture names
case ${arch} in
    x86_64)
        arch="amd64"
        ;;
    aarch64)
        arch="arm64"
        ;;
    armv7l)
        arch="armv7"
        ;;
esac


# Prepare package names
package_name="sing-box-${latest_version}-linux-${arch}"

# Prepare download URL
url="https://github.com/SagerNet/sing-box/releases/download/${latest_version_tag}/${package_name}.tar.gz"

# Download the latest release package (.tar.gz) from GitHub
curl -sLo "/root/${package_name}.tar.gz" "$url"


# Extract the package and move the binary to /root
tar -xzf "/root/${package_name}.tar.gz" -C /root
mv "/root/${package_name}/sing-box" /root/sbx/

# Cleanup the package
rm -r "/root/${package_name}.tar.gz" "/root/${package_name}"

# Set the permissions
chmod root:root /root/sbx/sing-box
chmod +x /root/sbx/sing-box

# Generate necessary values
domain=$(cat /root/vps/domain.txt)
uuid=$(/root/sbx/sing-box generate uuid)
# Retrieve the server IP address
server_ip=$(curl -s https://api.ipify.org)

# Create config.json using jq
cat << EOF >> /root/sbx/config.json
{
  "log": {
    "level": "info",
    "output": "/root/sbx/sb.log",
    "timestamp": true
  },
  "inbounds": [
    {
      "type": "vmess",
      "tag": "vmess-in",
      "listen": "::",
      "listen_port": 5001,
      "sniff": true,
      "sniff_override_destination": true,
      "domain_strategy": "ipv4_only",
      "users": [
        {
          "name": "adam",
          "uuid": "$uuid",
          "alterId": 0
        }
      ],
      "tls": {
        "enabled": true,
        "server_name": "$domain",
        "alpn": [
          "http/1.1"
        ],
        "min_version": "1.2",
        "max_version": "1.3",
        "certificate_path": "/root/cert/$domain/fullchain.pem",
        "key_path": "/root/cert/$domain/privkey.pem"
      },
      "transport": {
        "type": "ws",
        "path": "/vmws",
        "max_early_data": 0,
        "early_data_header_name": "Sec-WebSocket-Protocol"
      }
    }
  ],
  "outbounds": [
    {
      "type": "direct",
      "tag": "direct"
    },
    {
      "type": "block",
      "tag": "block"
    }
  ]
}
EOF

# Create sing-box.service
cat > /etc/systemd/system/sing-box.service <<EOF
[Unit]
After=network.target nss-lookup.target

[Service]
User=root
WorkingDirectory=/root
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW
ExecStart=/root/sbx/sing-box run -c /root/sbx/config.json
ExecReload=/bin/kill -HUP \$MAINPID
Restart=on-failure
RestartSec=10
LimitNOFILE=infinity

[Install]
WantedBy=multi-user.target
EOF

# Check configuration and start the service
if /root/sbx/sing-box check -c /root/sbx/config.json; then
    echo "Configuration checked successfully. Starting sing-box service..."
    systemctl daemon-reload
    systemctl enable sing-box
    systemctl start sing-box

# Generate the link
vmlink=`cat << EOF
{
"v": "2",
"ps": "adam",
"add": "ISI_BUG",
"port": "443",
"id": "$uuid",
"aid": "0",
"net": "ws",
"path": "/vmws",
"type": "none",
"host": "$domain",
"tls": "tls"
}
EOF`

    link_vmess="vmess://$(echo $vmlink | base64 -w 0)"

    # Print the server details
    echo
    echo "Server IP       : $server_ip"
    echo "Listen Port     : 443"
    echo "Server Name     : $domain"
    echo "Path Vmess WS   : /vmws"
    echo ""
    echo "Here is the link for NekoBox or v2rayNG : "
    echo ""
    echo "Vmess : $link_vmess"
    echo ""


    touch /root/akun/vmess.txt
    echo $link_vmess > /root/akun/vmess.txt

else
    echo "Error in configuration. Aborting..."
fi
