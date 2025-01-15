#!/bin/bash

# Enable command logging
set -x

# Ensure we're running as root
if [ "$(id -u)" != "0" ]; then
    echo "This script must be run as root" >&2
    exit 1
fi

# Log all commands to syslog
exec 1> >(logger -s -t $(basename $0)) 2>&1

# Log script execution context
logger "Script running as user: $(whoami)"
logger "Script effective user ID: $(id -u)"
logger "Script effective group ID: $(id -g)"

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

# Check current mounts
logger "Current mounts:"
mount | grep "${REMOVEABLE_STORAGE_PATH}" || true

# Ensure parent directories exist and have correct permissions
logger "Setting up mount path permissions..."
logger "Current /media permissions: $(ls -ld /media)"
chmod 755 /media
logger "Updated /media permissions: $(ls -ld /media)"

# Function to debug mount point usage
debug_mount_point() {
    local target="$1"
    logger "Debugging mount point usage for $target:"
    lsof "$target" 2>&1 | logger
    fuser -v "$target" 2>&1 | logger
    ps aux | grep "$target" | grep -v grep | logger
}

# Function to handle unmounting
unmount_target() {
    local target="$1"
    local max_retries=3
    local retry=0
    
    # Debug initial state
    debug_mount_point "$target"
    
    # First, try to stop Docker container if it's using the mount
    if docker ps | grep -q hublink-gateway; then
        logger "Stopping hublink-gateway Docker container"
        docker stop hublink-gateway || true
        sleep 2
    fi
    
    while mountpoint -q "$target" && [ $retry -lt $max_retries ]; do
        logger "Attempt $((retry + 1)) to unmount $target"
        
        # First try a normal unmount
        if umount "$target" 2>/dev/null; then
            logger "Successfully unmounted $target"
            return 0
        fi
        
        # If that fails, try force unmount
        if umount -f "$target" 2>/dev/null; then
            logger "Successfully force unmounted $target"
            return 0
        fi
        
        # If still mounted, try to find and kill processes more aggressively
        logger "Checking for processes using $target"
        debug_mount_point "$target"
        
        # Kill all processes using the mount point
        fuser -km "$target" 2>/dev/null || true
        sleep 2
        
        # Last resort: lazy unmount
        if umount -l "$target" 2>/dev/null; then
            logger "Successfully lazy unmounted $target"
            sleep 2
            return 0
        fi
        
        retry=$((retry + 1))
        sleep 1
    done
    
    if mountpoint -q "$target"; then
        logger "Failed to unmount $target after $max_retries attempts"
        # Final debug information
        debug_mount_point "$target"
        return 1
    fi
    return 0
}

# Clean up existing mount point
if [ -d "${REMOVEABLE_STORAGE_PATH}" ]; then
    logger "Attempting to unmount and clean up existing mount point"
    unmount_target "${REMOVEABLE_STORAGE_PATH}"
    
    # Only try to remove if unmount was successful
    if ! mountpoint -q "${REMOVEABLE_STORAGE_PATH}"; then
        rm -rf "${REMOVEABLE_STORAGE_PATH}"
    else
        logger "Error: Mount point still busy after unmount attempts"
        exit 1
    fi
fi

# Create fresh mount point with proper permissions
logger "Creating new mount point"
mkdir -p "${REMOVEABLE_STORAGE_PATH}"
chmod 777 "${REMOVEABLE_STORAGE_PATH}"
chown hublink:hublink "${REMOVEABLE_STORAGE_PATH}"
logger "Mount point created with permissions: $(ls -ld ${REMOVEABLE_STORAGE_PATH})"

# Get detailed device information
logger "Device details:"
blkid "$DEVNAME"
lsblk -f "$DEVNAME"

# Check if device exists
if [ ! -b "$DEVNAME" ]; then
    logger "Error: Device $DEVNAME does not exist"
    exit 1
fi

# Check and fix filesystem if needed
logger "Checking filesystem..."
fsck.vfat -a "$DEVNAME" 2>&1 | logger

# Get current user (ensure we use hublink user)
CURRENT_USER="hublink"
if ! id -u "$CURRENT_USER" >/dev/null 2>&1; then
    logger "Error: hublink user does not exist"
    exit 1
fi

CURRENT_UID=$(id -u "$CURRENT_USER")
CURRENT_GID=$(id -g "$CURRENT_USER")

logger "Using user $CURRENT_USER (UID:$CURRENT_UID GID:$CURRENT_GID) for mount"

# Set mount options specifically for FAT32
MOUNT_OPTS="rw,uid=$CURRENT_UID,gid=$CURRENT_GID,umask=000,dmask=000,fmask=000"

logger "Attempting mount with command: /bin/mount -t vfat -o $MOUNT_OPTS $DEVNAME ${REMOVEABLE_STORAGE_PATH}"

# Try mounting with vfat filesystem type
/bin/mount -v -t vfat -o "$MOUNT_OPTS" "$DEVNAME" "${REMOVEABLE_STORAGE_PATH}" 2>&1 | logger
MOUNT_STATUS=${PIPESTATUS[0]}

if [ $MOUNT_STATUS -eq 0 ]; then
    logger "HubLink USB drive mounted successfully at ${REMOVEABLE_STORAGE_PATH}"
    # Create data directory if it doesn't exist
    mkdir -p "${REMOVEABLE_STORAGE_PATH}/data"
    chmod 777 "${REMOVEABLE_STORAGE_PATH}/data"
    chown "$CURRENT_USER:$CURRENT_USER" "${REMOVEABLE_STORAGE_PATH}/data"
    ls -la "${REMOVEABLE_STORAGE_PATH}" | logger
else
    logger "Error: Failed to mount HubLink USB drive (exit code: $MOUNT_STATUS)"
    logger "Mount error details:"
    dmesg | tail -n 10 | logger
    logger "Current mounts:"
    mount | logger
    logger "Directory permissions:"
    ls -ld "${REMOVEABLE_STORAGE_PATH}" | logger
    ls -ld /media | logger
    exit 1
fi

# Verify mount
if mountpoint -q "${REMOVEABLE_STORAGE_PATH}"; then
    logger "Mount point verified at ${REMOVEABLE_STORAGE_PATH}"
    logger "Mount details: $(mount | grep ${REMOVEABLE_STORAGE_PATH})"
else
    logger "Error: Mount point verification failed"
    exit 1
fi

logger "Mount process completed successfully"

# Notify the Docker container if needed
docker kill --signal=SIGUSR1 hublink-gateway || true 