#!/bin/bash

# Create and set permissions for mount points
mkdir -p /media/hublink-usb
chown hublink:hublink /media/hublink-usb
chmod 777 /media/hublink-usb

# Create data directory
mkdir -p /media/hublink-usb/data
chown hublink:hublink /media/hublink-usb/data
chmod 777 /media/hublink-usb/data

# Execute the main container command
exec "$@" 