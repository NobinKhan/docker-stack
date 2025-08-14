#!/bin/bash

# ==============================================================================
# User Setup Script for Ubuntu 24 & Rocky Linux 9
#
# This script interactively helps you:
# 1. Change the system's hostname.
# 2. Change the root user's password.
# 3. Create a new user with passwordless sudo privileges and set up
#    SSH key-based authentication.
#
# USAGE:
#   Save the script, make it executable (chmod +x setup_script.sh),
#   and run it with root privileges:
#   sudo ./setup_script.sh
#
# ==============================================================================

# --- Script-wide settings ---
# Exit immediately if a command exits with a non-zero status.
set -e

# --- Global Variables ---
# We declare 'new_username' here so it can be accessed in the final message.
new_username=""

# --- Sanity Checks ---

# Check if the script is being run as root.
if [ "$(id -u)" -ne 0 ]; then
   echo "❌ This script must be run as root. Please use 'sudo'." >&2
   exit 1
fi

# Check if the shell is bash to avoid compatibility issues.
if [ -z "$BASH_VERSION" ]; then
    echo "❌ This script requires bash. Please run it with 'bash' or './script_name.sh'." >&2
    exit 1
fi

# --- Main Functions ---

# Function to change the system hostname
change_hostname() {
    echo "================================================="
    echo "🖥️  Step 1: Change Hostname"
    echo "================================================="
    read -p "Do you want to change the system hostname? [y/N]: " choice
    case "$choice" in
      y|Y )
        read -p "Enter the new hostname: " new_hostname
        if [ -z "$new_hostname" ]; then
            echo "❌ Hostname cannot be empty. Skipping."
            return
        fi
        echo "Setting hostname to '$new_hostname'..."
        hostnamectl set-hostname "$new_hostname"
        echo "✅ Hostname changed successfully. Current hostname: $(hostname)"
        ;;
      * )
        echo "Skipping hostname change."
        ;;
    esac
    echo
}

# Function to change the root password
change_root_password() {
    echo "================================================="
    echo "🔑 Step 2: Change Root Password"
    echo "================================================="
    read -p "Do you want to change the root password? [y/N]: " choice
    case "$choice" in
      y|Y )
        echo "You will now be prompted to set a new password for the 'root' user."
        # Ensure we are in an interactive terminal before running passwd
        if [ -t 0 ]; then
            passwd root
            echo "✅ Root password has been updated successfully."
        else
            echo "❌ Cannot change password in a non-interactive shell. Skipping."
        fi
        ;;
      * )
        echo "Skipping root password change."
        ;;
    esac
    echo
}

# Function to create a new sudo user with SSH key
create_sudo_user() {
    echo "================================================="
    echo "👤 Step 3: Create New Sudo User"
    echo "================================================="
    read -p "Do you want to create a new sudo user? [y/N]: " choice
    case "$choice" in
      y|Y )
        # Get username from user input
        read -p "Enter the username for the new user: " username
        if [ -z "$username" ]; then
            echo "❌ Username cannot be empty. Aborting user creation." >&2
            return
        fi
        # Set the global variable for the final message
        new_username=$username

        # Check if user already exists
        if id "$username" &>/dev/null; then
            echo "⚠️ User '$username' already exists. Skipping user creation."
        else
            echo "Creating user '$username'..."
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
            echo "❌ SSH public key cannot be empty. Aborting SSH setup." >&2
            return
        fi

        local user_home="/home/$username"
        local ssh_dir="$user_home/.ssh"
        local authorized_keys_file="$ssh_dir/authorized_keys"

        echo "Configuring SSH directory and authorized_keys file..."
        mkdir -p "$ssh_dir"
        echo "$ssh_public_key" > "$authorized_keys_file"

        # Set correct permissions and ownership
        chmod 700 "$ssh_dir"
        chmod 600 "$authorized_keys_file"
        chown -R "$username:$username" "$ssh_dir"

        echo "✅ SSH key added for '$username'."

        echo "-------------------------------------------------"
        echo "🛡️ Granting passwordless sudo access..."
        echo "-------------------------------------------------"

        local sudoers_file="/etc/sudoers.d/$username"
        echo "$username ALL=(ALL) NOPASSWD: ALL" > "$sudoers_file"
        chmod 0440 "$sudoers_file"

        echo "✅ User '$username' has been granted passwordless sudo access."
        ;;
      * )
        echo "Skipping user creation."
        ;;
    esac
    echo
}

# --- Script Execution ---

main() {
    change_hostname
    change_root_password
    create_sudo_user

    echo "================================================="
    echo "🎉 All selected tasks completed! 🎉"
    echo "================================================="
    if [ -n "$new_username" ]; then
        echo "You can now log in as '$new_username' using your SSH key."
    fi
}

# Run the main function
main
