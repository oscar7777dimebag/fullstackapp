#!/bin/bash

# Variables
SERVER_IP="179.5.119.85"
PROJECT_NAME="fullstack_project"
FRONTEND_DIR="/var/www/html/$PROJECT_NAME"
BACKEND_DIR="/opt/$PROJECT_NAME"

echo "🚀 Starting deployment process..."

# Kill any existing Node.js and Python processes
echo "Stopping existing processes..."
pkill -f node || true
pkill -f python || true

# Install required packages if not present
echo "Checking and installing dependencies..."
if ! command -v nginx &> /dev/null; then
    sudo apt-get update
    sudo apt-get install -y nginx
fi

if ! command -v node &> /dev/null; then
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    sudo apt-get install -y nodejs
fi

if ! command -v python3 &> /dev/null; then
    sudo apt-get install -y python3 python3-pip
fi

# Create directories if they don't exist
sudo mkdir -p $FRONTEND_DIR
sudo mkdir -p $BACKEND_DIR

# Copy frontend files
echo "Building and deploying frontend..."
cd frontend
npm install
npm run build
sudo cp -r dist/* $FRONTEND_DIR/

# Copy backend files
echo "Deploying backend..."
cd ../backend
pip3 install -r requirements.txt
sudo cp -r * $BACKEND_DIR/

# Create systemd service for backend
echo "Setting up backend service..."
sudo tee /etc/systemd/system/fullstack-backend.service << EOF
[Unit]
Description=Fullstack Project Backend
After=network.target

[Service]
User=www-data
WorkingDirectory=$BACKEND_DIR
ExecStart=/usr/bin/python3 app.py
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Configure Nginx
echo "Configuring Nginx..."
sudo tee /etc/nginx/sites-available/$PROJECT_NAME << EOF
server {
    listen 80;
    server_name $SERVER_IP;

    location / {
        root $FRONTEND_DIR;
        try_files \$uri \$uri/ /index.html;
    }

    location /api {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}
EOF

# Enable the site and remove default if exists
sudo rm -f /etc/nginx/sites-enabled/default
sudo ln -sf /etc/nginx/sites-available/$PROJECT_NAME /etc/nginx/sites-enabled/

# Start services
echo "Starting services..."
sudo systemctl daemon-reload
sudo systemctl enable fullstack-backend
sudo systemctl restart fullstack-backend
sudo systemctl restart nginx

echo "🎉 Deployment completed! Your application should be running at http://$SERVER_IP"
echo "Check status with: sudo systemctl status fullstack-backend"
echo "Check nginx logs with: sudo tail -f /var/log/nginx/error.log"