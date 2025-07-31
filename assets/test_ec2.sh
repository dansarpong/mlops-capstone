#!/bin/bash

sudo yum update -y

# Install PostgreSQL 17
sudo yum install postgresql17 git -y

# Install Docker
sudo yum install -y docker
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker ec2-user

# Download and install Docker Compose V2 manually
DOCKER_COMPOSE_VERSION="v2.29.7"
DOCKER_CONFIG=/usr/local/lib/docker
sudo mkdir -p $${DOCKER_CONFIG}/cli-plugins
sudo curl -SL "https://github.com/docker/compose/releases/download/$${DOCKER_COMPOSE_VERSION}/docker-compose-linux-x86_64" \
    -o $${DOCKER_CONFIG}/cli-plugins/docker-compose
sudo chmod +x $${DOCKER_CONFIG}/cli-plugins/docker-compose
sudo ln -sf $${DOCKER_CONFIG}/cli-plugins/docker-compose /usr/local/bin/docker-compose

# Install crontab
sudo yum install cronie -y
sudo systemctl enable crond.service
sudo systemctl start crond.service
