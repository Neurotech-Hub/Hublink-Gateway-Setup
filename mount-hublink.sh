#!/bin/bash

# Enable command logging
set -x

# Ensure we're running as root
if [ "$(id -u)" != "0" ]; then
    echo "This script must be run as root" >&2
    exit 1
fi

# Get the device name from parameter
DEVNAME="/dev/$1"

if [ -z "$1" ]; then
    echo "Error: No device name provided"
    exit 1
fi

# Source environment variables
if [ -f /opt/hublink/.env ]; then
    source /opt/hublink/.env
else
    REMOVEABLE_STORAGE_PATH="/media/hublink-usb"
fi

# Ensure mount point exists with correct permissions
mkdir -p "${REMOVEABLE_STORAGE_PATH}"
chown hublink:hublink "${REMOVEABLE_STORAGE_PATH}"
chmod 777 "${REMOVEABLE_STORAGE_PATH}"

# Use systemd-mount for reliable mounting
systemd-mount --no-block --automount=no \
    --owner=hublink --group=hublink \
    --options="rw,uid=1000,gid=1000,umask=000,dmask=000,fmask=000" \
    "$DEVNAME" "${REMOVEABLE_STORAGE_PATH}"

# Wait for mount to complete
sleep 2

# Verify mount
if mountpoint -q "${REMOVEABLE_STORAGE_PATH}"; then
    echo "Mount successful"
    # Create data directory if it doesn't exist
    mkdir -p "${REMOVEABLE_STORAGE_PATH}/data"
    chown hublink:hublink "${REMOVEABLE_STORAGE_PATH}/data"
    chmod 777 "${REMOVEABLE_STORAGE_PATH}/data"
    exit 0
else
    echo "Mount failed"
    exit 1
fi 