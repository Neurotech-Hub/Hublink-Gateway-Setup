#!/bin/bash

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root (use sudo)"
    exit 1
fi

# Copy udev rule
cp 99-hublink-usb.rules /etc/udev/rules.d/
chmod 644 /etc/udev/rules.d/99-hublink-usb.rules

# Copy and setup mount scripts
cp mount-hublink.sh /usr/local/bin/
cp unmount-hublink.sh /usr/local/bin/
chmod +x /usr/local/bin/mount-hublink.sh
chmod +x /usr/local/bin/unmount-hublink.sh

# Reload udev rules
udevadm control --reload-rules
udevadm trigger

echo "USB automount setup complete" 