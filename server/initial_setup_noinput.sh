#!/bin/bash

# Usage: sudo ./complete_setup.sh username

if [ "$EUID" -ne 0 ]; then
    echo "Run as root"
    exit 1
fi

USERNAME="$1"

if [ -z "$USERNAME" ]; then
    echo "Usage: $0 <username>"
    exit 1
fi

echo ">>> Creating user: $USERNAME"

# Create user with no password
useradd -m -s /bin/bash "$USERNAME"

# Disable password login
passwd -l "$USERNAME"

# Add to sudo group
usermod -aG sudo "$USERNAME"

# Copy SSH keys from root
mkdir -p /home/$USERNAME/.ssh
cp -r /root/.ssh/authorized_keys /home/$USERNAME/.ssh/

# Fix permissions
chown -R $USERNAME:$USERNAME /home/$USERNAME/.ssh
chmod 700 /home/$USERNAME/.ssh
chmod 600 /home/$USERNAME/.ssh/authorized_keys

# Enable passwordless sudo
echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/$USERNAME
chmod 440 /etc/sudoers.d/$USERNAME

echo ">>> User setup completed."
echo ">>> Installing Docker..."

# Install Docker
curl -fsSL https://get.docker.com | sh

# Add user to docker group
usermod -aG docker "$USERNAME"

echo ">>> Docker installed."
echo ">>> User '$USERNAME' added to docker group."
echo ">>> Setup complete!"
