#!/bin/bash
set -e

# Install dependencies
sudo apt-get update -y
sudo apt-get install -y curl gnupg lsb-release git

# Add Kong GPG key and repo
curl -fsSL https://packages.konghq.com/public/gateway-312/gpg.875433A518B93006.key | gpg --dearmor | sudo tee /usr/share/keyrings/kong.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/kong.gpg] https://packages.konghq.com/public/gateway-312/deb/ubuntu $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/kong.list

# Install Kong
sudo apt-get update -y
sudo apt-get install -y kong-enterprise-edition

# Deploy configuration
sudo mkdir -p /etc/kong
sudo git clone https://github.com/jijilki/kong-api-gw.git /tmp/kong-api-gw
sudo cp /tmp/kong-api-gw/kong/kong.conf /etc/kong/
sudo cp /tmp/kong-api-gw/kong/kong.yaml /etc/kong/

# Start Kong
sudo kong start -c /etc/kong/kong.conf

##keypair  aws-keypair