#!/bin/bash
echo "Starting user data script execution..."
sudo apt-get update -y
sudo apt-get full-upgrade -y
sudo apt-get autoremove -y

sudo apt-get install -y nginx docker.io
sudo systemctl start nginx
sudo systemctl enable nginx

sudo systemctl start docker
sudo systemctl enable docker
