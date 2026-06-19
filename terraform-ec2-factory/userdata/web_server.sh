#!/bin/bash
echo "Starting user data script execution..."
apt-get update -y
apt-get full-upgrade -y
apt-get autoremove -y

apt-get install -y nginx docker.io
systemctl start nginx
systemctl enable nginx

systemctl start docker
systemctl enable docker

