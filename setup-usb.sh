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

# Aggressively disable all automounting
echo "Disabling all automounting services..."

# Only try to remove udisks2 if it exists
if dpkg -l | grep -q udisks2; then
    echo "Removing udisks2..."
    systemctl stop udisks2.service || true
    systemctl disable udisks2.service || true
    apt-get remove -y udisks2
else
    echo "udisks2 not installed, skipping removal"
fi

# Disable automount for all users
mkdir -p /etc/pcmanfm/LXDE-pi/
cat > /etc/pcmanfm/LXDE-pi/pcmanfm.conf << EOL
[config]
autorun=0

[volume]
mount_on_startup=0
mount_removable=0
autorun=0
EOL

# Also set for current user
if [ -n "$SUDO_USER" ]; then
    su - $SUDO_USER -c 'mkdir -p ~/.config/pcmanfm/LXDE-pi'
    cp /etc/pcmanfm/LXDE-pi/pcmanfm.conf /home/$SUDO_USER/.config/pcmanfm/LXDE-pi/
    chown $SUDO_USER:$SUDO_USER /home/$SUDO_USER/.config/pcmanfm/LXDE-pi/pcmanfm.conf
fi

# Disable udev rules for automounting
rm -f /etc/udev/rules.d/*automount.rules
rm -f /lib/udev/rules.d/*automount.rules

# Copy our udev rule
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
echo "NOTE: A system reboot may be required for all changes to take effect" 