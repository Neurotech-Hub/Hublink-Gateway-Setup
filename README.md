# HubLink Gateway Setup

## Quick Start

CanaKit RPi's come with pre-installed software, otherwise use the [Raspberry Pi Imager](https://www.raspberrypi.com/software/) to load the OS onto a 32GB micro SD card.

The name of the RPi should be `hublink` with a documented password.

For installation, download and run the setup script with a single command:
```bash
curl -sSL https://raw.githubusercontent.com/Neurotech-Hub/Hublink-Gateway-Setup/main/setup.sh | sudo bash
```

This script will:
1. Create the installation directory at `/opt/hublink`
2. Clone the latest configuration files
3. Install Docker and required dependencies
4. Configure the system for USB data storage
5. Start the HubLink Gateway service

### Using Raspberry Pi Connect (Beta)

New Raspberry Pi's (v5) may have [Raspberry Pi Connect](https://www.raspberrypi.com/software/connect/) installed. If not, [Use the Instal Instructions](https://www.raspberrypi.com/documentation/services/connect.html).

Use the `hi@hublink.cloud` email to register the new device with format `Hublink-RPi-5-XXX`.

### Registering the MAC Address

Use the command `ifconfig` to gain the eth0 and wlan0 mac addresses. Enter these into the `Box > Hublink > HublinkGateways.xlxs` spreadsheet.

Use those data to [Add a New Device](https://wustl.service-now.com/sp?id=sc_cat_item&table=sc_cat_item&sys_id=2a8f28881b91e91070f1fc451a4bcb0e) to the WashU network.

Every gateway should be labeled with its name and the MAC address/s.

## Configuration

### Environment Variables

The setup script automatically creates `/opt/hublink/.env` with appropriate values:
```env
LOCAL_STORAGE_PATH=/opt/hublink     # Base directory for installation
USER=$(logname)                     # Current user's username for USB mounting
TZ=$(cat /etc/timezone)            # System timezone
ENVIRONMENT=prod                    # Production environment setting
```

These variables configure important system paths:
- `LOCAL_STORAGE_PATH`: Base directory containing application files and database
- Database: `${LOCAL_STORAGE_PATH}/hublink.db`
- Scans: `${LOCAL_STORAGE_PATH}/scans`
- USB Drive: `/media/${USER}/HUBLINK`
  - Data: `/media/${USER}/HUBLINK/data`
  - Config: `/media/${USER}/HUBLINK/hublink.json`

> Note: You should not need to modify these values manually as they are set automatically during installation.

### USB Drive Setup

You may use the [Hublink-CardFormatter Tool](https://github.com/Neurotech-Hub/Hublink-CardFormatter) to accomplish the steps below.

The system is configured to automatically use USB drives labeled "HUBLINK":
1. Format the drive with a compatible filesystem (e.g., ext4, FAT32)
2. Label the drive as "HUBLINK"
3. Create a `hublink.json` file in the root of the drive with the appropriate configuration:
```json  
{
  "secret_url": "https://hublink.cloud/<secret_url>",
  "gateway_name": "Gateway1"
}
```
4. Insert the drive - all data will be directly stored at `/media/$USER/HUBLINK`

When the USB drive is mounted:
- Application data is stored in `/media/$USER/HUBLINK/data`
- Configuration file is stored at `/media/$USER/HUBLINK/hublink.json`
- The database and scans remain on the local system at `/opt/hublink`

## Maintenance

### Updating the Gateway

To update your installation:
```bash
cd /opt/hublink
sudo git pull  # Update configuration files
docker-compose pull  # Update containers
docker-compose up -d  # Restart with new versions
```

To force update and overwrite any local changes:
```bash
cd /opt/hublink
sudo git fetch origin
sudo git reset --hard origin/main  # This will overwrite all local changes
docker-compose pull  # Update containers
docker-compose up -d  # Restart with new versions
```

The system includes Watchtower for automatic container updates.

### Common Commands

1. View gateway status:
```bash
docker ps
docker-compose logs -f
```

2. Check USB drive status:
```bash
ls /media/$USER/HUBLINK  # View contents of USB drive
df -h  # Check mount status
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

2. Data access issues:
   - Check USB drive is mounted: `ls /media/$USER/HUBLINK`
   - Verify permissions: `ls -l /media/$USER/HUBLINK`
   - Check docker logs: `docker-compose logs -f`

### Support

For additional support or to report issues, please visit:
https://github.com/Neurotech-Hub/Hublink-Gateway-Setup/issues