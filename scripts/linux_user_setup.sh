#!/bin/bash

# ==============================================================================
# User Setup Script for Ubuntu 24 & Rocky Linux 9
#
# This script interactively helps you:
# 1. Change the system's hostname to a Fully Qualified Domain Name (FQDN).
# 2. Change the root user's password.
# 3. Create a new user with passwordless sudo privileges and set up
#    SSH key-based authentication.
# 4. Install k3s as a server or agent with proper firewall and OS configs.
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

# --- Helper Functions ---

# Function to validate a Linux username
is_valid_username() {
    local username=$1
    if [[ "$username" =~ ^[a-z_][a-z0-9_-]*[$]?$ ]] && [ ${#username} -le 32 ]; then
        return 0
    else
        return 1
    fi
}

# Function to validate a hostname/FQDN
is_valid_hostname() {
    local hostname=$1
    if [[ "$hostname" =~ ^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$ ]]; then
        return 0
    else
        return 1
    fi
}

# --- Main Functions ---

# Function to change the system hostname
change_hostname() {
    echo "================================================="
    echo "🖥️  Step 1: Change Hostname"
    echo "================================================="
    read -p "Do you want to change the system hostname? [y/N]: " choice
    case "$choice" in
      y|Y )
        read -p "Enter the new Fully Qualified Domain Name (e.g., server-01.barrzen.com): " fqdn
        if ! is_valid_hostname "$fqdn"; then
            echo "❌ Invalid FQDN format. Skipping." >&2
            return
        fi

        local short_hostname
        short_hostname=$(echo "$fqdn" | cut -d. -f1)
        
        if [ "$(hostname)" == "$short_hostname" ] && [ "$(hostname -f)" == "$fqdn" ]; then
            echo "✅ Hostname is already set to '$fqdn'. No changes needed."
            return
        fi

        echo "Setting hostname to '$short_hostname'..."
        if hostnamectl set-hostname "$short_hostname"; then
            echo "✅ Hostname changed successfully. Current hostname: $(hostname)"
        else
            echo "❌ Failed to set hostname." >&2
            return
        fi

        echo "Updating /etc/hosts for fail-safe resolution..."
        
        local ip_address
        ip_address=$(ip -4 route get 8.8.8.8 | awk '{print $7; exit}' 2>/dev/null)
        if [ -z "$ip_address" ]; then
            echo "⚠️ Could not automatically determine the primary IP address. Using 127.0.1.1 for local resolution."
            ip_address="127.0.1.1"
        fi

        # Remove old entries for this IP to avoid conflicts, preserving the line with localhost
        sed -i.bak -E "/^${ip_address}\s/!b; /localhost/b; d" /etc/hosts
        
        # Add the new canonical entry
        echo "$ip_address $fqdn $short_hostname" >> /etc/hosts
        
        echo "✅ /etc/hosts updated."
        echo "Verification:"
        echo "  hostname: $(hostname)"
        echo "  hostname -f: $(hostname -f)"
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
        if [ -t 0 ]; then
            passwd root
            echo "✅ Root password has been updated successfully."
        else
            echo "❌ Cannot change password in a non-interactive shell. Skipping." >&2
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
        read -p "Enter the username for the new user: " username
        if ! is_valid_username "$username"; then
            echo "❌ Invalid username format. Aborting user creation." >&2
            return
        fi

        if id "$username" &>/dev/null; then
            echo "⚠️ User '$username' already exists. Skipping user creation."
        else
            echo "Creating user '$username'..."
            if useradd -m -s /bin/bash "$username"; then
                echo "✅ User '$username' created."
            else
                echo "❌ Failed to create user '$username'." >&2
                return
            fi
        fi

        echo "You will now be prompted to set a password for '$username'."
        if [ -t 0 ]; then
            passwd "$username"
        else
            echo "❌ Cannot change password in a non-interactive shell. Skipping password setup." >&2
        fi

        echo "-------------------------------------------------"
        echo "🔐 Setting up SSH access for '$username'..."
        echo "-------------------------------------------------"

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

        chmod 700 "$ssh_dir"
        chmod 600 "$authorized_keys_file"
        chown -R "$username:$username" "$ssh_dir"

        echo "✅ SSH key added for '$username'."

        echo "-------------------------------------------------"
        echo "🛡️ Granting passwordless sudo access..."
        echo "-------------------------------------------------"
        echo "⚠️  WARNING: This will grant user '$username' the ability to run any command as root without a password."
        read -p "Are you sure you want to proceed? [y/N]: " sudo_choice
        if [[ "$sudo_choice" != "y" && "$sudo_choice" != "Y" ]]; then
            echo "Skipping sudo access grant."
            echo "$username" # Return username for the final message
            return
        fi

        local sudoers_file="/etc/sudoers.d/$username"
        echo "$username ALL=(ALL) NOPASSWD: ALL" > "$sudoers_file"
        chmod 0440 "$sudoers_file"

        echo "✅ User '$username' has been granted passwordless sudo access."
        echo "$username" # Return username for the final message
        ;;
      * )
        echo "Skipping user creation."
        ;;
    esac
    echo
}

# Function to install k3s
install_k3s() {
    echo "================================================="
    echo "🚀 Step 4: Install k3s"
    echo "================================================="
    read -p "Do you want to install k3s? [y/N]: " choice
    case "$choice" in
      y|Y )
        # --- 1. Handle Swap ---
        echo "-------------------------------------------------"
        echo "🔧 Checking for and disabling swap..."
        echo "-------------------------------------------------"
        if [ "$(swapon --show | wc -l)" -gt 0 ]; then
            echo "Swap is active. Disabling for Kubernetes compatibility..."
            swapoff -a
            # Disable permanently in fstab
            sed -i.bak '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
            echo "✅ Swap disabled and /etc/fstab updated."
        else
            echo "✅ Swap is already disabled."
        fi
        echo

        # --- 2. Detect OS and Firewall ---
        source /etc/os-release
        local os_id=$ID
        local firewall_tool="none"

        if command -v firewall-cmd &> /dev/null && systemctl is-active --quiet firewalld; then
            firewall_tool="firewalld"
        elif command -v ufw &> /dev/null && ufw status | grep -q 'Status: active'; then
            firewall_tool="ufw"
        fi

        # --- 3. Choose Server or Agent ---
        local k3s_type="server"
        read -p "Install k3s as (1) Server or (2) Agent? [1]: " type_choice
        if [[ "$type_choice" == "2" ]]; then
            k3s_type="agent"
        fi

        # --- 4. Open Firewall Ports ---
        echo "-------------------------------------------------"
        echo "🔥 Configuring firewall ($firewall_tool)..."
        echo "-------------------------------------------------"
        if [ "$firewall_tool" == "none" ]; then
            echo "⚠️ No active firewall (firewalld or ufw) detected. Skipping port configuration."
            echo "Please ensure the required ports are open manually if a firewall is enabled later."
        else
            local ports_tcp
            local ports_udp
            if [ "$k3s_type" == "server" ]; then
                echo "Opening ports for k3s server..."
                ports_tcp="6443 2379 2380 10250" # k3s API, etcd, kubelet
                ports_udp="8472 51820 4789" # Flannel (vxlan), Wireguard, Cilium
            else
                echo "Opening ports for k3s agent..."
                ports_tcp="10250" # kubelet
                ports_udp="8472 51820 4789" # Flannel (vxlan), Wireguard, Cilium
            fi

            for port in $ports_tcp; do
                if [ "$firewall_tool" == "firewalld" ]; then
                    firewall-cmd --permanent --add-port=${port}/tcp > /dev/null
                elif [ "$firewall_tool" == "ufw" ]; then
                    ufw allow ${port}/tcp > /dev/null
                fi
            done
            for port in $ports_udp; do
                if [ "$firewall_tool" == "firewalld" ]; then
                    firewall-cmd --permanent --add-port=${port}/udp > /dev/null
                elif [ "$firewall_tool" == "ufw" ]; then
                    ufw allow ${port}/udp > /dev/null
                fi
            done

            if [ "$firewall_tool" == "firewalld" ]; then
                firewall-cmd --reload
            fi
            echo "✅ Firewall ports configured."
        fi
        echo

        # --- 5. Install k3s ---
        echo "-------------------------------------------------"
        echo "🚀 Installing k3s as a $k3s_type..."
        echo "-------------------------------------------------"
        local install_cmd="curl -sfL https://get.k3s.io |"
        local install_opts=""

        # Handle Rocky Linux specifics
        if [ "$os_id" == "rocky" ]; then
            echo "Rocky Linux detected. Applying specific configurations..."
            # Use wireguard-native backend for flannel to work with nf_tables
            install_opts=" --flannel-backend=wireguard-native"
            echo "✅ Using 'wireguard-native' flannel backend for nf_tables compatibility."
        fi

        if [ "$k3s_type" == "server" ]; then
            install_opts="INSTALL_K3S_EXEC='server${install_opts}'"
            eval "$install_cmd $install_opts sh -"
        else # agent
            read -p "Enter the k3s server URL (e.g., https://<server_ip>:6443): " k3s_url
            read -s -p "Enter the k3s server token: " k3s_token
            echo
            if [ -z "$k3s_url" ] || [ -z "$k3s_token" ]; then
                echo "❌ Server URL and token are required for agent setup. Aborting." >&2
                return
            fi
            install_opts="K3S_URL='$k3s_url' K3S_TOKEN='$k3s_token' INSTALL_K3S_EXEC='agent${install_opts}'"
            eval "$install_cmd $install_opts sh -"
        fi

        if [ $? -eq 0 ]; then
            echo "✅ k3s $k3s_type installed successfully!"
            if [ "$k3s_type" == "server" ]; then
                echo "Kubeconfig is located at /etc/rancher/k3s/k3s.yaml"
                echo "Run 'sudo k3s kubectl get nodes' to check status."
            fi
        else
            echo "❌ k3s installation failed." >&2
        fi
        ;;
      * )
        echo "Skipping k3s installation."
        ;;
    esac
    echo
}


# --- Script Execution ---

main() {
    change_hostname
    change_root_password
    local new_username
    new_username=$(create_sudo_user)
    install_k3s

    echo "================================================="
    echo "🎉 All selected tasks completed! 🎉"
    echo "================================================="
    if [ -n "$new_username" ]; then
        echo "You can now log in as '$new_username' using your SSH key."
    fi
}

# Run the main function
main