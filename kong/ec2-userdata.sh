#!/bin/bash
set -e

# Install dependencies
sudo apt-get update -y
sudo apt-get install -y curl gnupg lsb-release git python3-pip python3-venv unzip

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
# Install CloudWatch Agent
# --------------------------
cd /tmp
curl -O https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
sudo dpkg -i amazon-cloudwatch-agent.deb || sudo apt-get install -f -y

# Create CloudWatch agent config
sudo tee /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json > /dev/null <<EOF
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/home/ubuntu/flask-api/app.log",
            "log_group_name": "FlaskAPI-Logs",
            "log_stream_name": "{instance_id}-flask",
            "timestamp_format": "%Y-%m-%d %H:%M:%S"
          },
          {
            "file_path": "/usr/local/kong/logs/access.log",
            "log_group_name": "KongAPI-Logs",
            "log_stream_name": "{instance_id}-kong-access",
            "timestamp_format": "%Y-%m-%d %H:%M:%S"
          },
          {
            "file_path": "/usr/local/kong/logs/error.log",
            "log_group_name": "KongAPI-Logs",
            "log_stream_name": "{instance_id}-kong-error",
            "timestamp_format": "%Y-%m-%d %H:%M:%S"
          }
        ]
      }
    }
  }
}
EOF

# Start CloudWatch Agent
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config -m ec2 \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json \
  -s

echo "Setup complete. Flask, Kong, and CloudWatch Agent are running."


# --------------------------
# Download Spring Boot JAR and Dockerfile from S3
# --------------------------
SPRING_DIR=/home/ubuntu/spring-api
mkdir -p $SPRING_DIR
sudo chown -R ubuntu:ubuntu $SPRING_DIR
chmod -R 755 $SPRING_DIR

# Replace with your actual S3 paths
aws s3 cp s3://your-bucket-name/spring-app/todo.jar $SPRING_DIR/todo.jar
aws s3 cp s3://your-bucket-name/spring-app/Dockerfile $SPRING_DIR/Dockerfile

# --------------------------
# Install Docker
# --------------------------
sudo apt-get install -y docker.io
sudo systemctl start docker
sudo systemctl enable docker

# --------------------------
# Build and run Docker container
# --------------------------
cd $SPRING_DIR
sudo docker build -t spring-api .
sudo docker run -d -p 9090:8080 --name spring-api spring-api

# --------------------------
# Register Spring API with Kong
# --------------------------
curl -i -X POST http://localhost:8001/services/ \
  --data name=spring-api \
  --data url=http://localhost:9090

curl -i -X POST http://localhost:8001/services/spring-api/routes \
  --data paths[]=/spring

echo "Spring Boot API deployed and registered with Kong."

#todo logs for spring app.
