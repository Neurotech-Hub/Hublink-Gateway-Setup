#!/bin/bash

# docker-pull.sh
# Pull the latest images
docker-compose pull

# Recreate and restart the containers with the latest images
docker-compose up --force-recreate --detach

# Optional: Clean up unused images to free up space
docker image prune -f
