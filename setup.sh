#!/bin/bash

set -e  # Exit on error
log_file="install.log"

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root (use sudo)"
    exit 1
fi

echo "Starting HubLink Gateway installation..." | tee -a "$log_file"

# Create and move to installation directory
mkdir -p /opt/hublink
cd /opt/hublink

# Clone the repository if not already present
if [ ! -d ".git" ]; then
    echo "Downloading HubLink Gateway Setup..." | tee -a "$log_file"
    git clone https://github.com/Neurotech-Hub/Hublink-Gateway-Setup.git .
fi

# Create default .env file if it doesn't exist
if [ ! -f .env ]; then
    echo "Creating default environment configuration..." | tee -a "$log_file"
    echo "LOCAL_STORAGE_PATH=/opt/hublink" > .env
    echo "USER=$(logname)" >> .env
fi

# Install Docker
echo "Installing Docker..." | tee -a "$log_file"
curl -sSL https://get.docker.com | sh >> "$log_file" 2>&1

# Add current user to docker group
echo "Adding user to docker group..." | tee -a "$log_file"
usermod -aG docker $SUDO_USER

# Enable and start Docker service
echo "Enabling Docker service..." | tee -a "$log_file"
systemctl enable docker
systemctl start docker

# Install Docker Compose
echo "Installing Docker Compose..." | tee -a "$log_file"
COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | jq -r .tag_name)
curl -L "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Verify installations
echo "Verifying installations..." | tee -a "$log_file"
docker --version | tee -a "$log_file"
docker-compose --version | tee -a "$log_file"

# Configure Docker daemon
echo "Configuring Docker daemon..." | tee -a "$log_file"
mkdir -p /etc/docker
cat > /etc/docker/daemon.json <<EOL
{
  "default-runtime": "runc"
}
EOL

# Restart Docker service to apply changes
systemctl restart docker

# Start the services
echo "Starting HubLink Gateway..." | tee -a "$log_file"
docker-compose pull
docker-compose up -d

echo "Installation complete! Please log out and back in for group changes to take effect." | tee -a "$log_file"
echo "Your data will be available at /media/$USER/HUBLINK when a USB drive labeled 'HUBLINK' is connected." 