#!/bin/bash

clear
domain=$(cat /root/vps/domain.txt)
apt install nginx -y

rm /etc/nginx/sites-enabled/default
rm /etc/nginx/sites-availabe/default

touch /etc/nginx/sites-enabled/utama
cat << EOF >> /etc/nginx/sites-enabled/utama
server {
        listen 81 default_server;
        listen [::]:81 default_server;

        root /var/www/html;

        # Add index.php to the list if you are using PHP
        index inde.php index.html index.htm index.nginx-debian.html;

        server_name _;

        location / {
                # First attempt to serve request as file, then
                # as directory, then fall back to displaying a 404.
                try_files $uri $uri/ =404;
        }
}
EOF

touch /etc/nginx/conf.d/ws.conf

cat << EOF >> /etc/nginx/conf.d/ws.conf
server {
    listen 443 ssl http2 reuseport;
    listen [::]:443 ssl http2 reuseport;
    listen 80 reuseport;
    listen [::]:80 reuseport
    server_name  $domain;
    index index.html;
    root /var/www/html;

    ssl_certificate /root/cert/$domain.crt;
    ssl_certificate_key /root/cert/$domain.key;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;

    set_real_ip_from 103.21.244.0/22;
    set_real_ip_from 103.22.200.0/22;
    set_real_ip_from 103.31.4.0/22;
    set_real_ip_from 104.16.0.0/12;
    set_real_ip_from 108.162.192.0/18;
    set_real_ip_from 131.0.72.0/22;
    set_real_ip_from 141.101.64.0/18;
    set_real_ip_from 162.158.0.0/15;
    set_real_ip_from 172.64.0.0/13;
    set_real_ip_from 173.245.48.0/20;
    set_real_ip_from 188.114.96.0/20;
    set_real_ip_from 190.93.240.0/20;
    set_real_ip_from 197.234.240.0/22;
    set_real_ip_from 198.41.128.0/17;
    set_real_ip_from 2400:cb00::/32;
    set_real_ip_from 2606:4700::/32;
    set_real_ip_from 2803:f800::/32;
    set_real_ip_from 2405:b500::/32;
    set_real_ip_from 2405:8100::/32;
    set_real_ip_from 2c0f:f248::/32;
    set_real_ip_from 2a06:98c0::/29;

    real_ip_header CF-Connecting-IP;    

    location /vmws {
        if ($http_upgrade != "websocket") {
            return 404;
        }
        proxy_pass http://127.0.0.1:5001
        proxy_redirect off;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_read_timeout 52w;
    }
    
    location /vlws {
        if ($http_upgrade != "websocket") {
            return 404;
        }
        proxy_pass http://127.0.0.1:5002
        proxy_redirect off;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_read_timeout 52w;
    }

    location /trws {
        if ($http_upgrade != "websocket") {
            return 404;
        }
        proxy_pass http://127.0.0.1:5003
        proxy_redirect off;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_read_timeout 52w;
    }

    #location /grpc/Tun { #Your server GRPC ServiceName
    #    if ($content_type !~ "application/grpc") {
    #        return 404;
    #    }
    #    client_max_body_size 0;
    #    client_body_timeout 60m;
    #    send_timeout 60m;
    #    lingering_close always;
    #   grpc_read_timeout 3m;
    #   grpc_send_timeout 2m;
    #   grpc_set_header Host $host;
    #   grpc_set_header X-Real-IP $remote_addr;
    #   grpc_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    #   grpc_pass grpc://127.0.0.1:5000
    #}     
}
EOF

systemctl start nginx