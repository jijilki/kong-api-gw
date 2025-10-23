#!/bin/bash
set -e

# Install dependencies
sudo apt-get update -y
sudo apt-get install -y curl gnupg lsb-release git python3-pip python3-venv

# --------------------------
# Install Flask
# --------------------------
pip3 install --user flask

# --------------------------
# Set up Flask app
# --------------------------
FLASK_DIR=/home/ubuntu/flask-api
mkdir -p $FLASK_DIR
sudo chown -R ubuntu:ubuntu $FLASK_DIR
chmod -R 755 $FLASK_DIR

cat <<'EOF' > $FLASK_DIR/app.py
from flask import Flask, jsonify
app = Flask(__name__)

@app.route('/getHello')
def hello():
    return jsonify({"message": "Hello from Flask API behind Kong!"})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)
EOF

# --------------------------
# Start Flask in background
# --------------------------
nohup python3 $FLASK_DIR/app.py > $FLASK_DIR/app.log 2>&1 &


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

echo "Setup complete. Kong and Flask are running."

# --------------------------
# Setup CloudWatch Logging
# --------------------------
sudo apt-get install -y amazon-cloudwatch-agent

# Create CloudWatch Agent configuration
sudo tee /opt/aws/amazon-cloudwatch-agent/bin/config.json > /dev/null <<'CWEOF'
{
  "agent": {
    "metrics_collection_interval": 60,
    "logfile": "/opt/aws/amazon-cloudwatch-agent/logs/agent.log",
    "run_as_user": "root"
  },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/usr/local/kong/logs/access.log",
            "log_group_name": "kong-access-log",
            "log_stream_name": "{instance_id}"
          },
          {
            "file_path": "/usr/local/kong/logs/error.log",
            "log_group_name": "kong-error-log",
            "log_stream_name": "{instance_id}"
          },
          {
            "file_path": "/home/ubuntu/flask-api/app.log",
            "log_group_name": "flask-app-log",
            "log_stream_name": "{instance_id}"
          }
        ]
      }
    }
  }
}
CWEOF

# Start CloudWatch Agent
sudo systemctl enable amazon-cloudwatch-agent
sudo systemctl start amazon-cloudwatch-agent
