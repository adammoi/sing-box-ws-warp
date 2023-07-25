#!/bin/bash

clear
domain=$(cat /root/vps/domain.txt)
apt install nginx -y

touch /etc/nginx/conf.d/ws.conf

cat << EOF >> /etc/nginx/conf.d/ws.conf
server {
    listen 443 ssl http2 reuseport;
    listen [::]:443 ssl http2 reuseport;
    listen 80 reuseport;
    listen [::]:80 reuseport;
    server_name $domain;
    index index.html;
    root /var/www/html;

    ssl_certificate /root/cert/$domain/fullchain.pem;
    ssl_certificate_key /root/cert/$domain/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;

    location /vmws {
        if ($http_upgrade != "websocket") {
            return 404;
        }
        proxy_pass http://127.0.0.1:5001;
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
    #   grpc_pass grpc://127.0.0.1:5000;
    #}     
}
EOF

systemctl start nginx