#!/bin/bash
set -e
DOMAIN="${domain}"
NAME="${name}"

yum update -y
amazon-linux-extras install -y docker
service docker start
usermod -a -G docker ec2-user

yum install -y nginx
systemctl enable nginx
systemctl start nginx

# simple container app
cat > /home/ec2-user/DockerApp.js <<'NODE'
const http = require('http');
const port = 8080;
http.createServer((req,res)=>{res.writeHead(200,{'Content-Type':'text/plain'});res.end('Namaste from Container');}).listen(port);
NODE

cat > /home/ec2-user/Dockerfile <<'DOCK'
FROM node:18-alpine
WORKDIR /app
COPY DockerApp.js .
EXPOSE 8080
CMD ["node","DockerApp.js"]
DOCK

cd /home/ec2-user
docker build -t namaste:1 .
docker run -d --name namaste -p 8080:8080 namaste:1

# Nginx config (two server blocks)
cat > /etc/nginx/conf.d/${NAME}.conf <<NGINX
server {
    listen 80;
    server_name ${NAME}.${DOMAIN};

    location / {
        return 200 'Hello from Instance';
        add_header Content-Type text/plain;
    }
}

server {
    listen 80;
    server_name ${NAME}-docker.${DOMAIN};

    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}
NGINX

systemctl restart nginx
