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
cat > /etc/docker/daemon.json <<EOL
{
  "default-runtime": "runc",
  "runtimes": {
    "runc": {
      "args": ["--privileged"]
    }
  }
}
EOL

# Restart Docker service to apply changes
systemctl restart docker

echo "Docker has been configured to run in privileged mode by default." | tee -a "$log_file"
echo "Installation complete! Please log out and back in for group changes to take effect." | tee -a "$log_file"