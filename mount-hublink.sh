#!/bin/bash

# Enable command logging
set -x

# Get the device name from parameter
DEVNAME="$1"

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

# Ensure mount point exists
mkdir -p "${REMOVEABLE_STORAGE_PATH}"

# Get filesystem type
FS_TYPE=$(lsblk -no FSTYPE "$DEVNAME")
logger "Filesystem type: $FS_TYPE"

# First try: attempt mount without specifying filesystem type
logger "Attempting auto mount..."
mount -o rw,sync "$DEVNAME" "${REMOVEABLE_STORAGE_PATH}"
MOUNT_STATUS=$?

if [ $MOUNT_STATUS -ne 0 ]; then
    # If auto mount fails, try with explicit filesystem type
    logger "Auto mount failed, trying with explicit filesystem type..."
    
    # Install filesystem support if needed
    if [ "$FS_TYPE" = "vfat" ]; then
        apt-get install -y dosfstools
    elif [ "$FS_TYPE" = "exfat" ]; then
        apt-get install -y exfat-fuse exfat-utils
    elif [ "$FS_TYPE" = "ntfs" ]; then
        apt-get install -y ntfs-3g
    fi
    
    # Set mount options based on filesystem
    MOUNT_OPTS="rw,sync"
    if [ "$FS_TYPE" = "vfat" ] || [ "$FS_TYPE" = "exfat" ]; then
        MOUNT_OPTS="$MOUNT_OPTS,umask=000"
    fi
    
    # Try mounting with explicit filesystem type
    mount -t "$FS_TYPE" -o "$MOUNT_OPTS" "$DEVNAME" "${REMOVEABLE_STORAGE_PATH}"
    MOUNT_STATUS=$?
fi

if [ $MOUNT_STATUS -eq 0 ]; then
    logger "HubLink USB drive mounted successfully at ${REMOVEABLE_STORAGE_PATH}"
    # Set permissions
    chmod 755 "${REMOVEABLE_STORAGE_PATH}"
else
    logger "Error: Failed to mount HubLink USB drive (exit code: $MOUNT_STATUS)"
    logger "Filesystem details:"
    blkid "$DEVNAME"
    lsblk -f "$DEVNAME"
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