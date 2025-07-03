#!/bin/bash

# This script is designed to be run on a fresh Ubuntu 24.04 server.
# It will:
# 1. Create a new user with sudo privileges.
# 2. Set up SSH key-based authentication for the new user.
# 3. Disable root login over SSH.
# 4. Disable password authentication.

# --- Configuration ---

# Prompt for the username.
read -p "Enter the username for the new sudo user: " NEW_USER

# Prompt for the public SSH key.
read -p "Paste the public SSH key for the new user: " SSH_PUBLIC_KEY

# --- Script ---

# Exit immediately if a command exits with a non-zero status.
set -e

# Create the new user.
adduser --disabled-password --gecos "" "$NEW_USER"

# Add the new user to the sudo group.
usermod -aG sudo "$NEW_USER"

# Create the .ssh directory for the new user.
mkdir -p "/home/$NEW_USER/.ssh"

# Add the public key to the authorized_keys file.
echo "$SSH_PUBLIC_KEY" > "/home/$NEW_USER/.ssh/authorized_keys"

# Set the correct permissions for the .ssh directory and authorized_keys file.
chmod 700 "/home/$NEW_USER/.ssh"
chmod 600 "/home/$NEW_USER/.ssh/authorized_keys"

# Set the ownership of the .ssh directory and authorized_keys file to the new user.
chown -R "$NEW_USER:$NEW_USER" "/home/$NEW_USER/.ssh"

# Disable root login and password authentication in the SSH server configuration.
sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config

# Restart the SSH service for the changes to take effect.
systemctl restart sshd

echo "Server setup complete."
echo "You can now log in as '$NEW_USER' using your SSH key."
