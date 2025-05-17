#!/bin/bash

# Variables
SERVER_IP="179.5.119.85"
PROJECT_NAME="fullstackapp"
USER_NAME="dimebag"
HOME_DIR="/home/$USER_NAME"
FRONTEND_DIR="$HOME_DIR/$PROJECT_NAME/frontend"
BACKEND_DIR="$HOME_DIR/$PROJECT_NAME/backend"

echo "🚀 Starting deployment process..."

# Kill any existing Node.js and Python processes
echo "Stopping existing processes..."
sudo systemctl stop fullstackapp-backend || true
sudo pkill -f "python3 app.py" || true

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
    sudo apt-get install -y python3 python3-pip python3-venv
fi

# Create project directories
echo "Creating project directories..."
sudo mkdir -p $FRONTEND_DIR
sudo mkdir -p $BACKEND_DIR
sudo chown -R $USER_NAME:$USER_NAME $HOME_DIR/$PROJECT_NAME

# Setup Python virtual environment
echo "Setting up Python virtual environment..."
cd $BACKEND_DIR
python3 -m venv venv
source venv/bin/activate

# Copy project files
echo "Copying project files..."
cp -r ~/fullstack_project/backend/* $BACKEND_DIR/
cp -r ~/fullstack_project/frontend/* $FRONTEND_DIR/

# Install dependencies and build frontend
echo "Building frontend..."
cd $FRONTEND_DIR
npm install
npm run build

# Install backend dependencies
echo "Setting up backend..."
cd $BACKEND_DIR
pip install -r requirements.txt

# Create systemd service
echo "Creating systemd service..."
sudo tee /etc/systemd/system/fullstackapp-backend.service << EOF
[Unit]
Description=Fullstack App Backend
After=network.target

[Service]
User=$USER_NAME
Group=$USER_NAME
WorkingDirectory=$BACKEND_DIR
Environment="PATH=$BACKEND_DIR/venv/bin"
ExecStart=$BACKEND_DIR/venv/bin/python3 app.py
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Configure Nginx
echo "Configuring Nginx..."
sudo tee /etc/nginx/sites-available/fullstackapp << EOF
server {
    listen 80;
    server_name $SERVER_IP;

    location / {
        root $FRONTEND_DIR/dist;
        try_files \$uri \$uri/ /index.html;
    }

    location /api {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

# Enable site and restart Nginx
sudo rm -f /etc/nginx/sites-enabled/default
sudo ln -sf /etc/nginx/sites-available/fullstackapp /etc/nginx/sites-enabled/

# Set correct permissions
sudo chown -R $USER_NAME:$USER_NAME $HOME_DIR/$PROJECT_NAME
sudo chmod -R 755 $HOME_DIR/$PROJECT_NAME

# Start services
echo "Starting services..."
sudo systemctl daemon-reload
sudo systemctl enable fullstackapp-backend
sudo systemctl restart fullstackapp-backend
sudo systemctl restart nginx

# Show status and logs
echo "🎉 Deployment completed! Your application should be running at http://$SERVER_IP"
echo "Checking service status..."
sudo systemctl status fullstackapp-backend
echo "Checking Nginx configuration..."
sudo nginx -t
echo "Recent logs:"
sudo journalctl -u fullstackapp-backend -n 50 --no-pager
