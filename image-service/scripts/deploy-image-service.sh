#!/bin/bash
set -euo pipefail

# Deploy helper for image-service (example). Run as root.

SERVICE_ROOT=/var/www/html/image-service
STORAGE_PATH=/var/www/html/storage/images
RCLONE_CONF_SRC=~/.config/rclone/rclone.conf
RCLONE_CONF_DST=/etc/rclone/rclone.conf

echo "1) Install node deps"
cd "$SERVICE_ROOT"
if [ -f package.json ]; then
  npm ci --production
fi

echo "2) Ensure storage and temp dirs"
mkdir -p "$STORAGE_PATH"
mkdir -p "$SERVICE_ROOT/storage/temp"
mkdir -p "$SERVICE_ROOT/logs"

echo "3) Copy rclone config to /etc/rclone/rclone.conf (ensure this file exists)"
if [ -f "$RCLONE_CONF_SRC" ]; then
  sudo mkdir -p /etc/rclone
  sudo cp "$RCLONE_CONF_SRC" "$RCLONE_CONF_DST"
  sudo chown root:www-data "$RCLONE_CONF_DST"
  sudo chmod 640 "$RCLONE_CONF_DST"
  echo "Copied rclone config"
else
  echo "Warning: source rclone config not found: $RCLONE_CONF_SRC"
  echo "Please run 'rclone config' as the user that created the remote and then run this script again."
fi

echo "4) Ensure /etc/fuse.conf contains user_allow_other"
if ! grep -q "user_allow_other" /etc/fuse.conf 2>/dev/null; then
  echo "user_allow_other" | sudo tee -a /etc/fuse.conf
  echo "Added user_allow_other to /etc/fuse.conf"
fi

echo "5) Set ownership to www-data"
chown -R www-data:www-data "$STORAGE_PATH" "$SERVICE_ROOT"

echo "6) Install systemd unit files (system)"
sudo mkdir -p /etc/systemd/system
sudo cp "$SERVICE_ROOT/systemd/rclone-onedrive.service" /etc/systemd/system/
sudo cp "$SERVICE_ROOT/systemd/image-service.service" /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable rclone-onedrive.service image-service.service
sudo systemctl start rclone-onedrive.service image-service.service

echo "Deployment complete. Check status with: sudo systemctl status image-service.service" 
