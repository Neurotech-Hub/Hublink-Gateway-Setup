# HubLink Gateway Setup

## Quick Start

For initial installation, download and run the setup script with a single command:
```bash
curl -sSL https://raw.githubusercontent.com/Neurotech-Hub/Hublink-Gateway-Setup/main/setup.sh | sudo bash
```

This script will:
1. Create the installation directory at `/opt/hublink`
2. Clone the latest configuration files
3. Install Docker and required dependencies
4. Configure USB automounting for data transfer
5. Start the HubLink Gateway service

> **Important**: Use this command for initial installation only. For updates, see the [Updating the Gateway](#updating-the-gateway) section below.

## Configuration

### Environment Variables

The system uses two main storage locations, configured in `/opt/hublink/.env`:
```env
LOCAL_STORAGE_PATH=/opt/hublink          # Base directory for installation and data
REMOVEABLE_STORAGE_PATH=/media/hublink-usb  # USB drive mount point
```

> **Note**: The `.env` file will be created during installation. All data will be stored in `${LOCAL_STORAGE_PATH}/data` and will persist across container restarts and updates.

### Data Sync Configuration

The system can be configured to automatically sync data to USB storage. Create a `sync_config.json` file in the `LOCAL_STORAGE_PATH` directory with the following structure:

```json
{
    "delete_scans": true,
    "delete_scans_days_old": 90,
    "delete_scans_percent_remaining": 10
}
```

Configuration options:
- `delete_scans`: Enable/disable scan deletion (boolean)
- `delete_scans_days_old`: Delete scans older than this many days (integer)
- `delete_scans_percent_remaining`: Minimum storage percentage to maintain (integer)

> **Note**: If no configuration file is present, the system will perform a basic sync without any data management.

### USB Drive Setup

The system is configured to automatically mount USB drives labeled "HUBLINK". To prepare a USB drive:
1. Format the drive with a compatible filesystem (e.g., ext4, FAT32)
2. Label the drive as "HUBLINK"
3. Insert the drive - it will automatically mount to the path specified in `REMOVEABLE_STORAGE_PATH`

Data will be synced to a `data` subdirectory on the USB drive.

## Maintenance

### Updating the Gateway

To update your installation, use the following procedure:
```bash
cd /opt/hublink
sudo git pull  # Update configuration files
docker-compose pull  # Update containers
docker-compose up -d  # Restart with new versions
```

> **Note**: Never run the initial installation command again on an existing installation as it may overwrite your configurations. Always use the update procedure above.

The system also includes Watchtower for automatic container updates.

### Common Commands

1. View gateway status:
```bash
docker ps
docker-compose logs -f
```

2. View sync logs:
```bash
tail -f /var/log/hublink-sync.log
```

3. Restart services:
```bash
cd /opt/hublink
docker-compose restart
```

## Troubleshooting

### Common Issues

1. USB drive not mounting:
   - Check drive label is "HUBLINK"
   - View system logs: `journalctl -f`
   - Check mount status: `df -h`

2. Data not being synced:
   - Check USB drive is mounted: `ls ${REMOVEABLE_STORAGE_PATH}`
   - View sync logs: `tail -f /var/log/hublink-sync.log`
   - Verify data exists: `ls ${LOCAL_STORAGE_PATH}/data`

### Support

For additional support or to report issues, please visit:
https://github.com/Neurotech-Hub/Hublink-Gateway-Setup/issues

## Monitoring and Logs

### USB Drive Operations
To monitor USB drive operations in real-time:
```bash
# View system logs (includes mount/unmount events)
journalctl -f | grep "HubLink USB"

# View udev events
udevadm monitor --environment

# Check current mounts
mount | grep hublink
```

### Data Sync Status
To monitor data synchronization:
```bash
# View sync logs
tail -f /var/log/hublink-sync.log

# Check data directories
ls -l ${LOCAL_STORAGE_PATH}/data
ls -l ${REMOVEABLE_STORAGE_PATH}/data
```

### System Status
Monitor the complete system:
```bash
# View all system logs
journalctl -f

# Check Docker container status
docker ps
docker-compose logs -f

# Check mount points and disk usage
df -h
```