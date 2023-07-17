#!/bin/bash

echo "Script installer Sing-Box WebSocket + WARP"

apt update && apt upgrade -y

wget -O nginx "https://raw.githubusercontent.com/adammoi/sing-box-ws-warp/main/nginx.sh" 
chmod +x nginx
wget -O ssl "https://raw.githubusercontent.com/adammoi/sing-box-ws-warp/main/ssl.sh"
chmod +x ssl
wget -O first.py "https://raw.githubusercontent.com/adammoi/sing-box-ws-warp/main/tele_bot/first.py"
python3 first.py

# Check if jq is installed, and install it if not
if ! command -v jq &> /dev/null; then
    echo "jq is not installed. Installing..."
    if [ -n "$(command -v apt)" ]; then
        apt update
        apt install -y jq
    elif [ -n "$(command -v yum)" ]; then
        yum install -y epel-release
        yum install -y jq
    elif [ -n "$(command -v dnf)" ]; then
        dnf install -y jq
    else
        echo "Cannot install jq. Please install jq manually and rerun the script."
        exit 1
    fi
fi

# Check if config.json, sing-box, and sing-box.service already exist
if [ -f "/root/config.json" ] && [ -f "/root/sing-box" ] && [ -f "/etc/systemd/system/sing-box.service" ]; then

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
            rm /root/config.json
            rm /root/sing-box

            # Proceed with installation
            ;;
        2)
            echo "Uninstalling..."
            # Stop and disable sing-box service
            systemctl stop sing-box
            systemctl disable sing-box

            # Remove files
            rm /etc/systemd/system/sing-box.service
            rm /root/config.json
            rm /root/sing-box
	    echo "DONE!"
            exit 0
            ;;
        *)
            echo "Invalid choice. Exiting."
            exit 1
            ;;
    esac
fi

# Fetch the latest (including pre-releases) release version number from GitHub API
latest_version=$(curl -s "https://api.github.com/repos/SagerNet/sing-box/releases" | grep -P -m1 -o "(v[0-9]{1,}\.[0-9]{1,}\.[0-9]{1,}(-beta.[0-9]{1,})?)" | tr -d 'v')
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
url="https://github.com/SagerNet/sing-box/releases/download/v${latest_version}/${package_name}.tar.gz"

# Download the latest release package (.tar.gz) from GitHub
curl -sLo "/root/${package_name}.tar.gz" "$url"


# Extract the package and move the binary to /root
tar -xzf "/root/${package_name}.tar.gz" -C /root
mv "/root/${package_name}/sing-box" /root/

# Cleanup the package
rm -r "/root/${package_name}.tar.gz" "/root/${package_name}"

# Set the permissions
chmod root:root /root/sing-box
chmod +x /root/sing-box


# Generate key pair

# Generate necessary values
uuid=$(/root/sing-box generate uuid)

# Ask for server name (sni)
read -p "Enter server name/SNI (default: sb.adam-sija.my.id): " server_name
server_name=${server_name:-sb.adam-sija.my.id}

# Retrieve the server IP address
server_ip=$(curl -s https://api.ipify.org)

# Create config.json using jq
jq -n --arg server_name "$server_name" --arg uuid "$uuid" '{
  "log": {
    "level": "info",
    "timestamp": true
  },
  "inbounds": [
    {
      "type": "trojan",
      "tag": "trojan-in",
      "listen": "::",
      "listen_port": 52001,
      "sniff": true,
      "sniff_override_destination": true,
      "domain_strategy": "ipv4_only",
      "users": [
        {
          "uuid": $uuid,
          "alterid": 0
        }
      ],
      "tls": {
        "enabled": true,
        "server_name": $server_name,
        "alpn": [
          "http/1.1"
        ],
        "min_version": "1.2",
        "max_version": "1.3",
        "certificate_path": "/root/cert/cert.pem",
        "key_path": "/root/cert/key.pem"
      },
      "transport": {
        "type": "ws",
        "path": "/trojan",
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
}' > /root/config.json

# Create sing-box.service
cat > /etc/systemd/system/sing-box.service <<EOF
[Unit]
After=network.target nss-lookup.target

[Service]
User=root
WorkingDirectory=/root
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW
ExecStart=/root/sing-box run -c /root/config.json
ExecReload=/bin/kill -HUP \$MAINPID
Restart=on-failure
RestartSec=10
LimitNOFILE=infinity

[Install]
WantedBy=multi-user.target
EOF

# Check configuration and start the service
if /root/sing-box check -c /root/config.json; then
    echo "Configuration checked successfully. Starting sing-box service..."
    systemctl daemon-reload
    systemctl enable sing-box
    systemctl start sing-box
    systemctl restart sing-box

# Generate the link

    server_link="trojan://$uuid@$server_ip:443/?sni=$server_name&type=ws&host=$server_name&path=%2Ftrojan"

    # Print the server details
    echo
    echo "Server IP: $server_ip"
    echo "Listen Port: 443"
    echo "Server Name: $server_name"
    echo "UUID: $uuid"
    echo ""
    echo ""
    echo "Here is the link for NekoBox and v2rayNG :"
    echo ""
    echo "$server_link"

    touch /root/akun.txt
    echo $server_link > /root/akun.txt

else
    echo "Error in configuration. Aborting."
fi
