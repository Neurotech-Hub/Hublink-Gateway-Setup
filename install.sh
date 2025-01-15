#!/bin/bash

# install.sh
set -e  # Exit on error
log_file="docker_install.log"

echo "Starting Docker installation..." | tee -a "$log_file"

# Check if script is run as root
if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root (use sudo)" | tee -a "$log_file"
    exit 1
fi

# Setup hublink directory
echo "Setting up HubLink directory..." | tee -a "$log_file"
CURRENT_DIR=$(pwd)
if [ "$CURRENT_DIR" != "/opt/hublink" ]; then
    mkdir -p /opt/hublink
    cp -r . /opt/hublink/
fi
cd /opt/hublink

# Source environment variables
if [ -f .env ]; then
    echo "Loading environment variables..." | tee -a "$log_file"
    set -a
    source .env
    set +a
else
    echo "Error: .env file not found!" | tee -a "$log_file"
    exit 1
fi

# Clean up any existing configurations
echo "Cleaning up existing configurations..." | tee -a "$log_file"
# Remove existing cron jobs
rm -f /etc/cron.d/hublink*
# Stop and disable any existing services
systemctl stop hublink* 2>/dev/null || true
systemctl disable hublink* 2>/dev/null || true
# Remove any existing service files
rm -f /etc/systemd/system/hublink*
systemctl daemon-reload

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

# Install jq for JSON parsing
echo "Installing jq..." | tee -a "$log_file"
apt install jq -y >> "$log_file" 2>&1

# Install Docker Compose
echo "Installing Docker Compose..." | tee -a "$log_file"
COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | jq -r .tag_name)
curl -L "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Verify installations
echo "Verifying installations..." | tee -a "$log_file"
docker --version | tee -a "$log_file"
docker-compose --version | tee -a "$log_file"

# Add warning about privileged mode
echo -e "\n⚠️  WARNING: System will be configured to run Docker in privileged mode by default" | tee -a "$log_file"
echo "This gives containers full access to host devices and kernel capabilities." | tee -a "$log_file"

# Create docker daemon configuration for privileged mode
echo "Configuring Docker daemon for privileged mode..." | tee -a "$log_file"
mkdir -p /etc/docker
cat > /etc/docker/daemon.json <<EOL
{
  "default-runtime": "runc"
}
EOL

# Restart Docker service to apply changes
systemctl stop docker
systemctl stop containerd
sleep 2
systemctl start containerd
systemctl start docker

# Create required directories
echo "Creating required directories..." | tee -a "$log_file"
mkdir -p "${LOCAL_STORAGE_PATH}/data"
mkdir -p "${REMOVEABLE_STORAGE_PATH}"
chmod 755 "${LOCAL_STORAGE_PATH}/data"
chmod 755 "${REMOVEABLE_STORAGE_PATH}"
echo "Created storage directories" | tee -a "$log_file"

# Setup USB automounting
echo "Setting up USB automounting..." | tee -a "$log_file"
bash setup-usb.sh >> "$log_file" 2>&1

# Setup data sync
echo "Setting up data sync..." | tee -a "$log_file"
bash setup-sync.sh >> "$log_file" 2>&1

# Start the services
echo "Starting HubLink Gateway..." | tee -a "$log_file"
docker-compose up -d

echo "Docker has been configured. Verifying service status..." | tee -a "$log_file"
systemctl status docker --no-pager | tee -a "$log_file"
echo "Installation complete! Please log out and back in for group changes to take effect." | tee -a "$log_file"