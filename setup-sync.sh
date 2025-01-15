#!/bin/bash

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root (use sudo)"
    exit 1
fi

# Install required packages
apt-get update
apt-get install -y python3 rsync

# Make sync manager executable
chmod +x /opt/hublink/sync_manager.py

# Create cron job for sync (runs every 5 minutes)
cat > /etc/cron.d/hublink-sync << EOL
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
*/5 * * * * root cd /opt/hublink && ./sync_manager.py
EOL

# Set proper permissions
chmod 644 /etc/cron.d/hublink-sync

echo "Sync manager setup complete. Check /var/log/hublink-sync.log for sync status." 