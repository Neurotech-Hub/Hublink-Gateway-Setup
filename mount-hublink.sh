#!/bin/bash

# Source environment variables
if [ -f /opt/hublink/.env ]; then
    set -a
    source /opt/hublink/.env
    set +a
else
    logger "Error: /opt/hublink/.env not found, using default path"
    REMOVEABLE_STORAGE_PATH="/media/hublink-usb"
fi

# Get the device name from the environment
DEVNAME="${DEVNAME}"
MOUNT_POINT="${REMOVEABLE_STORAGE_PATH}"

# Ensure mount point exists
mkdir -p "$MOUNT_POINT"

# Mount the device
mount "$DEVNAME" "$MOUNT_POINT"

# Set appropriate permissions
chmod 755 "$MOUNT_POINT"

# Log the mount
logger "HubLink USB drive mounted at $MOUNT_POINT"

# Notify the Docker container if needed
docker kill --signal=SIGUSR1 hublink-gateway || true 