# HubLink Gateway Setup

## Quick Start

Download and run the setup script:
```bash
wget https://raw.githubusercontent.com/Neurotech-Hub/Hublink-Gateway-Setup/main/setup.sh
chmod +x setup.sh
sudo ./setup.sh
```

This script will:
1. Install Docker and required dependencies
2. Download the latest configuration files
3. Start the HubLink Gateway service

After installation completes:
1. Reboot your system:
```bash
sudo reboot
```
2. After reboot, the HubLink Gateway service will start automatically

## Configuration

### Environment Setup

Create a `.env` file in the same directory as docker-compose.yml:
```env
DATA_DIRECTORY=/path/to/your/data
GATEWAY_NAME=YOUR_GATEWAY_NAME
SECRET_URL=https://your.api.url
```

> **Note**: Keep the `.env` file secure and do not commit it to version control. All data will be stored in the directory specified by `DATA_DIRECTORY` and will persist across container restarts and updates.

## Running the Gateway

Start and monitor the gateway:
```bash
# Pull latest version
docker-compose pull

# Start the services
docker-compose up -d

# Stop the services
docker-compose down

# View logs
docker-compose logs -f
```

## Troubleshooting

### Common Commands

1. Check container status:
```bash
docker ps
```

2. View container health:
```bash
docker inspect --format='{{.State.Health.Status}}' hublink-gateway_hublink-gateway_1
```

3. View detailed logs:
```bash
docker-compose logs --tail=100
```