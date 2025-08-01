#!/bin/bash

sudo yum update -y

# Install dependencies
sudo yum install postgresql17 git python3.11 -y

# Install Docker and Docker Compose
sudo yum install -y docker
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker ec2-user

sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Install crontab
sudo yum install cronie -y
sudo systemctl enable crond.service
sudo systemctl start crond.service

# Create a swap file and make it consistent across reboots
sudo fallocate -l 4G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
