#!/bin/bash

# Enable command logging
set -x

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root (use sudo)"
    exit 1
fi

echo "Starting USB setup..."

# Ensure required packages are installed
apt-get update
apt-get install -y udev util-linux

# Disable desktop automount
echo "Disabling desktop automount..."
if [ -n "$SUDO_USER" ]; then
    # Disable automount in PCManFM
    su - $SUDO_USER -c 'mkdir -p ~/.config/pcmanfm/LXDE-pi'
    su - $SUDO_USER -c 'cat > ~/.config/pcmanfm/LXDE-pi/pcmanfm.conf << EOL
[volume]
mount_on_startup=0
mount_removable=0
autorun=0
EOL'

    # Disable udisks2 automount
    mkdir -p /etc/udisks2
    cat > /etc/udisks2/mount_options.conf << EOL
[defaults]
automount=false
automount-open=false
EOL
fi

# Copy udev rule
echo "Installing udev rule..."
cp 99-hublink-usb.rules /etc/udev/rules.d/
chmod 644 /etc/udev/rules.d/99-hublink-usb.rules

# Verify udev rule installation
if [ ! -f /etc/udev/rules.d/99-hublink-usb.rules ]; then
    echo "Error: Failed to install udev rule"
    exit 1
fi
echo "Udev rule installed successfully"

# Copy and setup mount scripts
echo "Installing mount scripts..."
cp mount-hublink.sh /usr/local/bin/
cp unmount-hublink.sh /usr/local/bin/
chmod +x /usr/local/bin/mount-hublink.sh
chmod +x /usr/local/bin/unmount-hublink.sh

# Verify script installation
if [ ! -x /usr/local/bin/mount-hublink.sh ] || [ ! -x /usr/local/bin/unmount-hublink.sh ]; then
    echo "Error: Failed to install mount scripts"
    exit 1
fi
echo "Mount scripts installed successfully"

# Reload udev rules
echo "Reloading udev rules..."
udevadm control --reload-rules
udevadm trigger

# Test udev rule recognition
echo "Testing udev rule..."
udevadm test /sys/class/block/* 2>&1 | grep -i "hublink"

# Show current USB devices
echo "Current USB devices:"
lsblk -f
echo "Current block devices with labels:"
blkid

echo "USB automount setup complete"
echo "To test: Insert a USB drive labeled 'HUBLINK'"
echo "Then check: journalctl -f | grep 'HubLink USB'" 