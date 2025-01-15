#!/bin/bash

# Source environment variables
if [ -f /opt/hublink/.env ]; then
    set -a
    source /opt/hublink/.env
    set +a
else
    REMOVEABLE_STORAGE_PATH="/media/hublink-usb"
fi

# Log the unmount attempt
logger "HubLink USB drive removal detected"

# Force unmount if necessary (in case of busy device)
umount -f "${REMOVEABLE_STORAGE_PATH}" 2>/dev/null || true

# Clean up mount point
rm -rf "${REMOVEABLE_STORAGE_PATH}"/*
mkdir -p "${REMOVEABLE_STORAGE_PATH}"

logger "HubLink USB drive unmounted and cleaned up" 