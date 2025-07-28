# HubLink Gateway - macOS Development Setup

This guide outlines how to set up the HubLink Gateway for development on macOS.

## Prerequisites

1. **Docker Desktop** - Download and install from [docker.com](https://www.docker.com/products/docker-desktop/)
2. **Git** - Should be pre-installed on macOS, or install via Homebrew: `brew install git`

## Setup Steps

### 1. Create Directory and Clone Repository

```bash
# Create the installation directory
sudo mkdir -p /opt/hublink

# Change ownership to current user (macOS uses 'staff' group)
sudo chown $(whoami):staff /opt/hublink

# Verify ownership
ls -la /opt/hublink

# Move into the directory
cd /opt/hublink

# Clone the repository
git clone https://github.com/Neurotech-Hub/Hublink-Gateway-Setup.git .
```

### 2. Create Environment Configuration

Create a `.env` file in the project directory:

```bash
cat > .env << EOL
LOCAL_STORAGE_PATH=/opt/hublink
USER=$(whoami)
TZ=America/Chicago
EOL
```

### 3. Create Required Directories

```bash
# Create local storage directory
mkdir -p /opt/hublink/data
```

### 4. Pull and Start Services

**Modify the `docker-compose.yml` file to use the `:dev` container.**

```bash
# Pull the latest images
docker-compose pull

# Start the services
docker-compose up -d
```

### 5. Verify Installation

Check that the containers are running:

```bash
docker-compose ps
```

View logs:

```bash
docker-compose logs -f
```

## Development Workflow

### Stopping Services

```bash
docker-compose down
```
### Restarting Services

```bash
docker-compose restart
```

### Viewing Logs

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f hublink-gateway
```

### Accessing Container Shell

```bash
docker-compose exec hublink-gateway bash
```

## Configuration

### Environment Variables

The following environment variables are available in the container:

- `LOCAL_STORAGE_PATH` - Path to local storage (default: `/opt/hublink`)
- `MEDIA_STORAGE_PATH` - Path to removable storage (default: `/media/$(whoami)/HUBLINK`)
- `ENVIRONMENT` - Set to `prod` for production mode
- `TZ` - Timezone (auto-detected from system)

### Volume Mounts

- Local storage: `${LOCAL_STORAGE_PATH}:/opt/hublink`
- Media storage: `/media:/media:rshared` (for USB drives)
- Device access: `/dev:/dev:ro` (for hardware access)
- Bluetooth: `/var/run/bluetooth:/var/run/bluetooth`

## Troubleshooting

### Permission Issues

If you encounter permission issues with directories:

```bash
sudo chown -R $(whoami):$(whoami) /opt/hublink
```

### Port Conflicts

The application runs on port 5000 by default. If you have conflicts:

1. Check what's using port 5000:
   ```bash
   lsof -i :5000
   ```

2. Modify the port in `docker-compose.yml` if needed.

### Docker Desktop Issues

If Docker Desktop isn't running:

1. Open Docker Desktop application
2. Wait for it to start completely
3. Try the commands again

### Container Not Starting

Check the logs for errors:

```bash
docker-compose logs hublink-gateway
```

Common issues:
- Missing environment variables
- Permission issues with mounted volumes
- Port conflicts

## Notes

- This setup is for development only
- The container runs in privileged mode for hardware access
- USB drives should be mounted at `/media/$(whoami)/HUBLINK` to be accessible
- Logs are limited to 10MB per file with 3 file rotation
- The container includes Bluetooth and device access capabilities 
