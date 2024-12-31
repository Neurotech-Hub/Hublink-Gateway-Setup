# HubLink Gateway Setup

## Quick Start

1. Clone and prepare the repository:
```bash
git clone https://github.com/Neurotech-Hub/Hublink-Gateway-Setup hublink-gateway
cd hublink-gateway
```

2. Run installation scripts:
```bash
chmod +x install.sh setup-cron.sh git-pull.sh docker-pull.sh
sudo ./install.sh
sudo ./setup-cron.sh
```

3. Pull the latest version:
```bash
sudo ./git-pull.sh
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

Job for docker.service failed because the control process exited with error code.
See "systemctl status docker.service" and "journalctl -xeu docker.service" for details.

```

× docker.service - Docker Application Container Engine
     Loaded: loaded (/lib/systemd/system/docker.service; enabled; preset: enabled)
     Active: failed (Result: exit-code) since Tue 2024-12-31 13:48:34 CST; 5min ago
   Duration: 1min 10.774s
TriggeredBy: × docker.socket
       Docs: https://docs.docker.com
    Process: 113483 ExecStart=/usr/bin/dockerd -H fd:// --containerd=/run/containerd/containerd.sock (code=exited, status=1/>
   Main PID: 113483 (code=exited, status=1/FAILURE)
        CPU: 38ms

Dec 31 13:48:34 raspberrypi systemd[1]: docker.service: Scheduled restart job, restart counter is at 3.
Dec 31 13:48:34 raspberrypi systemd[1]: Stopped docker.service - Docker Application Container Engine.
Dec 31 13:48:34 raspberrypi systemd[1]: docker.service: Start request repeated too quickly.
Dec 31 13:48:34 raspberrypi systemd[1]: docker.service: Failed with result 'exit-code'.
Dec 31 13:48:34 raspberrypi systemd[1]: Failed to start docker.service - Docker Application Container Engine.