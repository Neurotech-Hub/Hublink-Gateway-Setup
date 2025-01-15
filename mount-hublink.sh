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

# Get filesystem type
FS_TYPE=$(lsblk -no FSTYPE "$DEVNAME")
logger "Detected filesystem type: $FS_TYPE"

# Install filesystem support if needed
if [ "$FS_TYPE" = "vfat" ]; then
    apt-get install -y dosfstools
elif [ "$FS_TYPE" = "exfat" ]; then
    apt-get install -y exfat-fuse exfat-utils
elif [ "$FS_TYPE" = "ntfs" ]; then
    apt-get install -y ntfs-3g
fi

# Set mount options based on filesystem
MOUNT_OPTS="rw,sync,user"
if [ "$FS_TYPE" = "vfat" ] || [ "$FS_TYPE" = "exfat" ]; then
    MOUNT_OPTS="$MOUNT_OPTS,umask=000,dmask=000,fmask=000"
elif [ "$FS_TYPE" = "ntfs" ]; then
    MOUNT_OPTS="$MOUNT_OPTS,umask=000,dmask=000,fmask=000,uid=$(id -u $SUDO_USER),gid=$(id -g $SUDO_USER)"
fi

logger "Attempting mount with options: $MOUNT_OPTS"

# Try mounting with explicit filesystem type and options
mount -t "$FS_TYPE" -o "$MOUNT_OPTS" "$DEVNAME" "${REMOVEABLE_STORAGE_PATH}"
MOUNT_STATUS=$?

if [ $MOUNT_STATUS -eq 0 ]; then
    logger "HubLink USB drive mounted successfully at ${REMOVEABLE_STORAGE_PATH}"
    # Set permissions
    chmod -R 777 "${REMOVEABLE_STORAGE_PATH}"
    chown -R $SUDO_USER:$SUDO_USER "${REMOVEABLE_STORAGE_PATH}"
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

# Create data directory if it doesn't exist
mkdir -p "${REMOVEABLE_STORAGE_PATH}/data"
chmod 777 "${REMOVEABLE_STORAGE_PATH}/data"

# Notify the Docker container if needed
docker kill --signal=SIGUSR1 hublink-gateway || true 