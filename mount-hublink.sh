#!/bin/bash

# Enable command logging
set -x

# Get the device name from parameter
DEVNAME="$1"

if [ -z "$DEVNAME" ]; then
    logger "Error: No device name provided"
    exit 1
fi

# Source environment variables
if [ -f /opt/hublink/.env ]; then
    set -a
    source /opt/hublink/.env
    set +a
else
    logger "Warning: /opt/hublink/.env not found, using default paths"
    REMOVEABLE_STORAGE_PATH="/media/hublink-usb"
fi

# Log the mount attempt
logger "HubLink USB drive detected at $DEVNAME"

# Ensure mount point exists and is empty
mkdir -p "${REMOVEABLE_STORAGE_PATH}"
rm -rf "${REMOVEABLE_STORAGE_PATH:?}"/*

# Get detailed device information
logger "Device details:"
blkid "$DEVNAME" | logger
lsblk -f "$DEVNAME" | logger

# Ensure FAT32 support is installed
apt-get install -y dosfstools

# Set mount options specifically for FAT32
MOUNT_OPTS="rw,sync,user,uid=$(id -u $SUDO_USER),gid=$(id -g $SUDO_USER),umask=000"

logger "Attempting mount with options: $MOUNT_OPTS"

# Try mounting with vfat filesystem type
mount -t vfat -o "$MOUNT_OPTS" "$DEVNAME" "${REMOVEABLE_STORAGE_PATH}"
MOUNT_STATUS=$?

if [ $MOUNT_STATUS -eq 0 ]; then
    logger "HubLink USB drive mounted successfully at ${REMOVEABLE_STORAGE_PATH}"
    # Create data directory if it doesn't exist
    mkdir -p "${REMOVEABLE_STORAGE_PATH}/data"
    chmod 777 "${REMOVEABLE_STORAGE_PATH}/data"
else
    logger "Error: Failed to mount HubLink USB drive (exit code: $MOUNT_STATUS)"
    logger "Mount error details:"
    dmesg | tail -n 10 | logger
    mount | logger
    exit 1
fi

# Verify mount
if mountpoint -q "${REMOVEABLE_STORAGE_PATH}"; then
    logger "Mount point verified at ${REMOVEABLE_STORAGE_PATH}"
else
    logger "Error: Mount point verification failed"
    exit 1
fi

# Notify the Docker container if needed
docker kill --signal=SIGUSR1 hublink-gateway || true 