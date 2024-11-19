# HubLink Gateway Setup

## Quick Start

1. Clone and prepare the repository:
```bash
git clone https://github.com/Neurotech-Hub/Hublink-Gateway-Setup hublink-gateway
cd hublink-gateway
```

2. Run installation scripts:
```bash
chmod +x install.sh setup-cron.sh
sudo ./install.sh
sudo ./setup-cron.sh
```

## Configuration

### Environment Setup

Create a `.env` file in the same directory as docker-compose.yml:
```env
DATA_DIRECTORY=/path/to/your/data
GATEWAY_NAME=YOUR_GATEWAY_NAME
SECRET_URL=https://your.api.url
```

> **Note**: Keep the `.env` file secure and do not commit it to version control. All data will be stored in the directory specified by `DATA_DIRECTORY` and will persist across container restarts and updates.

### Bluetooth Configuration (Optional)

Set up Bluetooth permissions:
```bash
# Add users to bluetooth group
sudo usermod -a -G bluetooth root
sudo usermod -a -G bluetooth $USER

# Verify bluetooth group members
getent group bluetooth

# Optional cleanup
sudo apt autoremove -y
sudo apt clean
```

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