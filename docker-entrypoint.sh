#!/bin/bash

# Create and set permissions for mount points
mkdir -p /media/hublink-usb
chown 1000:1000 /media/hublink-usb
chmod 777 /media/hublink-usb

# Execute the main container command
exec "$@" 