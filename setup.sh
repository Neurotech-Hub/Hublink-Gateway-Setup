#!/bin/bash

# setup.sh
set -e  # Exit on error
log_file="setup.log"

echo "Starting HubLink Gateway Setup..." | tee -a "$log_file"

# Check if script is run as root
if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root (use sudo)" | tee -a "$log_file"
    exit 1
fi

# Install Docker and dependencies
echo "Installing Docker and dependencies..." | tee -a "$log_file"
curl -sSL https://get.docker.com | sh >> "$log_file" 2>&1

# Add current user to docker group
usermod -aG docker $SUDO_USER

# Install Docker Compose
echo "Installing Docker Compose..." | tee -a "$log_file"
COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep -m 1 "tag_name" | cut -d '"' -f 4)
curl -L "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Configure Docker for privileged mode
echo "Configuring Docker..." | tee -a "$log_file"
mkdir -p /etc/docker
cat > /etc/docker/daemon.json <<EOL
{
  "default-runtime": "runc"
}
EOL

# Start Docker services
systemctl enable docker
systemctl start docker

# Download docker-compose.yml
echo "Downloading configuration files..." | tee -a "$log_file"
curl -sSL https://raw.githubusercontent.com/Neurotech-Hub/Hublink-Gateway-Setup/main/docker-compose.yml -o docker-compose.yml

# Create data directory
DATA_DIR="/data/hublink"
mkdir -p $DATA_DIR
echo "Created data directory at $DATA_DIR" | tee -a "$log_file"

# Start the services
echo "Starting HubLink Gateway..." | tee -a "$log_file"
DATA_DIRECTORY=$DATA_DIR docker-compose up -d

echo -e "\n✅ Setup complete! HubLink Gateway is now running."
echo "You can view the logs with: docker-compose logs -f"

# Prompt for reboot
echo -e "\n⚠️  A system reboot is required for all changes to take effect."
read -p "Would you like to reboot now? [y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Rebooting system..."
    reboot
else
    echo "Please remember to reboot your system manually to complete the setup."
fi 