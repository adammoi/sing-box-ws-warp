apt install nginx -y

mkdir /etc/nginx/ws.d
touch /etc/nginx/ws.d/stream.conf

cat << EOF >> /etc/nginx/ws.d/stream.conf
stream {
    map $ssl_preread_server_name $singbox {
            sb.adam-sija.my.id trojan-websocket;
    }
    upstream trojan-websocket {
            server 127.0.0.1:52001;
    }
    server {
            listen 443      reuseport;
            listen [::]:443 reuseport;
            proxy_pass      $singbox;
            ssl_preread     on;
            proxy_protocol  on;
    }
}
EOF

echo 'include /etc/nginx/ws.d/*.conf;' | sudo tee -a /etc/nginx/nginx.conf
systemctl start nginx