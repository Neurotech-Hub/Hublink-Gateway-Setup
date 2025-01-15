#!/usr/bin/env python3

import os
import sys
import json
import logging
import subprocess
from pathlib import Path

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('/var/log/hublink-sync.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger('hublink-sync')

class DataSyncManager:
    def __init__(self):
        # Get paths from environment
        self.local_path = os.path.join(os.getenv('LOCAL_STORAGE_PATH', '/opt/hublink'), 'data')
        self.removable_path = os.path.join(os.getenv('REMOVEABLE_STORAGE_PATH', '/media/hublink-usb'), 'data')
        self.config_path = os.path.join(os.getenv('LOCAL_STORAGE_PATH', '/opt/hublink'), 'sync_config.json')
        
    def sync_data(self) -> bool:
        """Sync data to removable storage"""
        # Check if removable storage is available
        if not os.path.exists(os.path.dirname(self.removable_path)):
            logger.error(f"Removable storage not found at {self.removable_path}")
            return False

        try:
            # Create remote data directory if it doesn't exist
            os.makedirs(self.removable_path, exist_ok=True)
            
            # Perform sync using rsync
            cmd = [
                'rsync',
                '-av',
                '--delete',
                f"{self.local_path}/",
                f"{self.removable_path}/"
            ]
            subprocess.run(cmd, check=True)
            logger.info("Data sync completed successfully")
            return True
        except subprocess.CalledProcessError as e:
            logger.error(f"Sync failed: {e}")
            return False

def main():
    """Main entry point"""
    try:
        manager = DataSyncManager()
        success = manager.sync_data()
        sys.exit(0 if success else 1)
    except Exception as e:
        logger.error(f"Unexpected error: {e}")
        sys.exit(1)

if __name__ == '__main__':
    main() 