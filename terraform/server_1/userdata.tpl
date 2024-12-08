#!/bin/bash
set -e

# Redirect output and errors to a log file
exec > /var/log/userdata.log 2>&1

echo "Starting user-data script execution..."

# Create the .ssh directory if it doesn't exist and set proper permissions
SSH_DIR="/home/ubuntu/.ssh"
mkdir -p $SSH_DIR
chmod 700 $SSH_DIR

# Generate the SSH key without a passphrase
SSH_KEY_PATH="$SSH_DIR/ansible"
if [ ! -f $SSH_KEY_PATH ]; then
  echo "Creating SSH key at $SSH_KEY_PATH..."
  ssh-keygen -t ed25519 -f $SSH_KEY_PATH -N ""
fi

# Set proper permissions for the SSH key
chmod 600 $SSH_KEY_PATH
chown -R ubuntu:ubuntu $SSH_DIR

echo "User-data script execution completed."
