#!/bin/bash

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root (use sudo)"
    exit 1
fi

# Install git if not present
if ! command -v git &> /dev/null; then
    apt-get update
    apt-get install -y git
fi

# Create and move to installation directory
mkdir -p /opt/hublink
cd /opt/hublink

# Clone the repository
echo "Downloading HubLink Gateway Setup..."
git clone https://github.com/Neurotech-Hub/Hublink-Gateway-Setup.git .

# Make install script executable
chmod +x install.sh

# Run the installation
echo "Starting installation..."
./install.sh 