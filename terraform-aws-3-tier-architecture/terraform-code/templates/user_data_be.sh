#!/bin/bash
sudo yum update -y
sudo amazon-linux-extras enable docker
sudo yum install -y docker git
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker ec2-user
newgrp docker

# Install Docker Compose
sudo mkdir -p /usr/libexec/docker/cli-plugins
sudo curl -SL "https://github.com/docker/compose/releases/latest/download/docker-compose-linux-$(uname -m)" \
  -o /usr/libexec/docker/cli-plugins/docker-compose
sudo chmod +x /usr/libexec/docker/cli-plugins/docker-compose

# Clone code
git clone https://github.com/TranChucThien/terraform-aws-3-tier-architecture.git
cd terraform-aws-3-tier-architecture/application/backend

# Use sed to replace the MongoDB host in the docker-compose.yml file
sudo sed -i "s|MONGO_HOST:.*|MONGO_HOST: ${db_private_ip}|g" docker-compose.yml

sudo docker compose up -d