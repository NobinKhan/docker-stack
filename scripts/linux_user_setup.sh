#!/bin/bash

# ==============================================================================
# User Setup Script for Ubuntu 24 & Rocky Linux 9
#
# This script performs two main tasks:
# 1. Changes the root user's password.
# 2. Creates a new user with passwordless sudo privileges and sets up
#    SSH key-based authentication for them.
#
# USAGE:
#   Run this script with root privileges:
#   sudo ./setup_script.sh
#
# ==============================================================================

# --- Script-wide settings ---
set -e # Exit immediately if a command exits with a non-zero status.
set -o pipefail # Causes a pipeline to return the exit status of the last command
                # that exited with a non-zero status.

# --- Sanity Checks ---

# Check if the script is being run as root.
if [ "$(id -u)" -ne 0 ]; then
   echo "❌ This script must be run as root. Please use 'sudo'." >&2
   exit 1
fi

# --- Main Functions ---

# Function to change the root password
change_root_password() {
    echo "================================================="
    echo "🔑 Step 1: Change Root Password"
    echo "================================================="
    echo "You will now be prompted to set a new password for the 'root' user."
    passwd root
    echo "✅ Root password has been updated successfully."
    echo
}

# Function to create a new sudo user with SSH key
create_sudo_user() {
    echo "================================================="
    echo "👤 Step 2: Create New Sudo User"
    echo "================================================="

    # Get username from user input
    read -p "Enter the username for the new user: " username
    if [ -z "$username" ]; then
        echo "❌ Username cannot be empty. Aborting." >&2
        exit 1
    fi

    # Check if user already exists
    if id "$username" &>/dev/null; then
        echo "⚠️ User '$username' already exists. Skipping user creation."
    else
        echo "Creating user '$username'..."
        # Create user with a home directory (-m) and set bash as the default shell (-s)
        useradd -m -s /bin/bash "$username"
        echo "✅ User '$username' created."
    fi

    echo "You will now be prompted to set a password for '$username'."
    passwd "$username"

    echo "-------------------------------------------------"
    echo "🔐 Setting up SSH access for '$username'..."
    echo "-------------------------------------------------"

    # Get public SSH key from user input
    read -p "Paste the public SSH key for '$username': " ssh_public_key
    if [ -z "$ssh_public_key" ]; then
        echo "❌ SSH public key cannot be empty. Aborting." >&2
        exit 1
    fi

    local user_home="/home/$username"
    local ssh_dir="$user_home/.ssh"
    local authorized_keys_file="$ssh_dir/authorized_keys"

    echo "Configuring SSH directory and authorized_keys file..."
    mkdir -p "$ssh_dir"

    # Add the key to the authorized_keys file
    echo "$ssh_public_key" > "$authorized_keys_file"

    # Set correct permissions and ownership to ensure SSH works correctly
    chmod 700 "$ssh_dir"
    chmod 600 "$authorized_keys_file"
    chown -R "$username:$username" "$ssh_dir"

    echo "✅ SSH key added for '$username'."

    echo "-------------------------------------------------"
    echo "🛡️ Granting passwordless sudo access..."
    echo "-------------------------------------------------"

    local sudoers_file="/etc/sudoers.d/$username"
    echo "$username ALL=(ALL) NOPASSWD: ALL" > "$sudoers_file"

    # Set correct permissions for the sudoers file
    chmod 0440 "$sudoers_file"

    echo "✅ User '$username' has been granted passwordless sudo access."
    echo
}

# --- Script Execution ---

main() {
    change_root_password
    create_sudo_user
    echo "================================================="
    echo "🎉 All tasks completed successfully! 🎉"
    echo "================================================="
    echo "You can now log in as '$username' using your SSH key."
}

# Run the main function
main
