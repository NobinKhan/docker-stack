# If user ssh key defined in hosts file
ansible k3s_servers -i hosts.ini -b -m apt -a "update_cache=yes upgrade=yes"

# If user ssh key NOT defined in hosts file
ansible k3s_servers -i hosts.ini \
    --user=nazrul \
    --private-key=~/.ssh/id_ed25519 \
    -b -m apt -a "update_cache=yes upgrade=yes"

# With ansible playbook
ansible-playbook -i hosts.ini server-update.yml
