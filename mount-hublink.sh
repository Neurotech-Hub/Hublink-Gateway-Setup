#!/bin/bash

# Enable command logging
set -x

# Log all commands to syslog
exec 1> >(logger -s -t $(basename $0)) 2>&1

# Get the device name from parameter
DEVNAME="/dev/$1"

if [ -z "$1" ]; then
    logger "Error: No device name provided"
    exit 1
fi

logger "Starting mount process for device: $DEVNAME"

# Wait for device to be fully ready
sleep 2

# Source environment variables
if [ -f /opt/hublink/.env ]; then
    logger "Loading environment from /opt/hublink/.env"
    set -a
    source /opt/hublink/.env
    set +a
else
    logger "Warning: /opt/hublink/.env not found, using default paths"
    REMOVEABLE_STORAGE_PATH="/media/hublink-usb"
fi

logger "Using mount point: ${REMOVEABLE_STORAGE_PATH}"

# Ensure mount point exists and is empty
mkdir -p "${REMOVEABLE_STORAGE_PATH}"
rm -rf "${REMOVEABLE_STORAGE_PATH:?}"/*

# Get detailed device information
logger "Device details:"
blkid "$DEVNAME"
lsblk -f "$DEVNAME"

# Check if device exists
if [ ! -b "$DEVNAME" ]; then
    logger "Error: Device $DEVNAME does not exist"
    exit 1
fi

# Ensure FAT32 support is installed
logger "Installing FAT32 support"
apt-get install -y dosfstools

# Set mount options specifically for FAT32
MOUNT_OPTS="defaults,rw,users,umask=000"

logger "Attempting mount with command: mount -t vfat -o $MOUNT_OPTS $DEVNAME ${REMOVEABLE_STORAGE_PATH}"

# Try mounting with vfat filesystem type
mount -t vfat -o "$MOUNT_OPTS" "$DEVNAME" "${REMOVEABLE_STORAGE_PATH}"
MOUNT_STATUS=$?

if [ $MOUNT_STATUS -eq 0 ]; then
    logger "HubLink USB drive mounted successfully at ${REMOVEABLE_STORAGE_PATH}"
    # Create data directory if it doesn't exist
    mkdir -p "${REMOVEABLE_STORAGE_PATH}/data"
    chmod 777 "${REMOVEABLE_STORAGE_PATH}/data"
    chown -R pi:pi "${REMOVEABLE_STORAGE_PATH}/data"
    ls -la "${REMOVEABLE_STORAGE_PATH}" | logger
else
    logger "Error: Failed to mount HubLink USB drive (exit code: $MOUNT_STATUS)"
    logger "Mount error details:"
    dmesg | tail -n 10
    mount
    exit 1
fi

# Verify mount
if mountpoint -q "${REMOVEABLE_STORAGE_PATH}"; then
    logger "Mount point verified at ${REMOVEABLE_STORAGE_PATH}"
else
    logger "Error: Mount point verification failed"
    exit 1
fi

logger "Mount process completed successfully"

# Notify the Docker container if needed
docker kill --signal=SIGUSR1 hublink-gateway || true 