#!/bin/bash

set -e  # Exit on error
log_file="install.log"

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root (use sudo)"
    exit 1
fi

echo "Starting HubLink Gateway installation..." | tee -a "$log_file"

# Stop any existing containers first
if command -v docker &> /dev/null && systemctl is-active --quiet docker; then
    echo "Stopping existing Docker containers..." | tee -a "$log_file"
    
    # First move out of /opt/hublink in case we're in it
    cd /

    if [ -f "/opt/hublink/docker-compose.yml" ]; then
        echo "Stopping via docker-compose..." | tee -a "$log_file"
        (cd /opt/hublink && docker-compose down) || echo "docker-compose down failed, continuing..." | tee -a "$log_file"
    fi
    
    echo "Checking for remaining hublink containers..." | tee -a "$log_file"
    docker ps -q --filter "name=hublink" | xargs -r docker stop || echo "No remaining containers to stop" | tee -a "$log_file"
fi

# Remove existing directory completely and recreate fresh
echo "Preparing installation directory..." | tee -a "$log_file"
cd /
rm -rf /opt/hublink
mkdir -p /opt/hublink
cd /opt/hublink || exit 1

# Clone the repository with more verbose output
echo "Downloading HubLink Gateway Setup..." | tee -a "$log_file"
cd /
rm -rf /opt/hublink
git clone https://github.com/Neurotech-Hub/Hublink-Gateway-Setup.git /opt/hublink 2>> "$log_file" || {
    echo "Git clone failed! See $log_file for details" | tee -a "$log_file"
    cat "$log_file"
    exit 1
}
cd /opt/hublink || exit 1
echo "Repository cloned successfully" | tee -a "$log_file"

# Create default .env file if it doesn't exist
if [ ! -f .env ]; then
    echo "Creating default environment configuration..." | tee -a "$log_file"
    echo "LOCAL_STORAGE_PATH=/opt/hublink" > .env
    echo "USER=$(logname)" >> .env
    echo "TZ=$(cat /etc/timezone)" >> .env
fi

# Install Docker if not present
if ! command -v docker &> /dev/null; then
    echo "Installing Docker..." | tee -a "$log_file"
    curl -sSL https://get.docker.com | sh >> "$log_file" 2>&1

    # Enable and start Docker service
    echo "Enabling Docker service..." | tee -a "$log_file"
    systemctl enable docker
    systemctl start docker
else
    echo "Docker already installed, skipping installation..." | tee -a "$log_file"
fi

# Add current user to docker group
echo "Adding user to docker group..." | tee -a "$log_file"
usermod -aG docker $SUDO_USER

# Install Docker Compose if not present
if ! command -v docker-compose &> /dev/null; then
    echo "Installing Docker Compose..." | tee -a "$log_file"
    
    # Install jq for JSON parsing
    echo "Installing jq..." | tee -a "$log_file"
    apt-get update && apt-get install -y jq >> "$log_file" 2>&1
    
    COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | jq -r .tag_name)
    curl -L "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
else
    echo "Docker Compose already installed, skipping installation..." | tee -a "$log_file"
fi

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