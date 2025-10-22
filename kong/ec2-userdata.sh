#!/bin/bash
set -e

sudo apt-get update -y
sudo apt-get install -y curl apt-transport-https gnupg lsb-release git

# Add Kong repo
echo "deb [trusted=yes] https://download.konghq.com/gateway-3.x-ubuntu-focal/ default all" | sudo tee /etc/apt/sources.list.d/kong.list

sudo apt-get update -y
sudo apt-get install -y kong

# Deploy configuration
sudo mkdir -p /etc/kong
sudo git clone https://github.com/jijilki/kong-api-gw.git /tmp/kong-poc
sudo cp /tmp/kong-poc/kong/kong.conf /etc/kong/
sudo cp /tmp/kong-poc/kong/kong.yaml /etc/kong/

# Start Kong
sudo kong start -c /etc/kong/kong.conf
