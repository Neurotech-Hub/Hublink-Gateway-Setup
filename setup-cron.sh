#!/bin/bash

# setup-cron.sh
set -e  # Exit on error
log_file="cron_setup.log"

echo "Setting up cron job for hublink-gateway..." | tee -a "$log_file"

# Check if script is run as root
if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root (use sudo)" | tee -a "$log_file"
    exit 1
fi

# Get the actual user (not root)
ACTUAL_USER=$SUDO_USER
if [ -z "$ACTUAL_USER" ]; then
    echo "Could not determine the actual user" | tee -a "$log_file"
    exit 1
fi

# Create the cron job
CRON_CMD="0 * * * * docker restart hublink-gateway-hublink-gateway-1"

# Check if cron job already exists
if sudo -u $ACTUAL_USER crontab -l 2>/dev/null | grep -q "docker restart hublink-gateway-hublink-gateway-1"; then
    echo "Cron job already exists. Skipping..." | tee -a "$log_file"
else
    # Add new cron job
    (sudo -u $ACTUAL_USER crontab -l 2>/dev/null; echo "$CRON_CMD") | sudo -u $ACTUAL_USER crontab -
    echo "Cron job added successfully" | tee -a "$log_file"
fi

# Verify the cron job
echo "Current cron jobs:" | tee -a "$log_file"
sudo -u $ACTUAL_USER crontab -l | tee -a "$log_file"

echo "Cron setup complete!" | tee -a "$log_file" 

# echo "Enabling at boot..." | tee -a "$log_file"
# docker update --restart unless-stopped hublink-gateway-hublink-gateway-1
