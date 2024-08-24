# K3s Cluster Install Instruction

## Port List tcp
```text
80,443,6443,10250,5001
```

## Port List udp
```text
51820
```

## open ports in ubuntu

### Step 1: Open iptables ports
```bash
sudo apt install nano
sudo nano /etc/iptables/rules.v4
```

### Step 2: Add below iptables rules
```text
-A INPUT -p tcp -m state --state NEW -m tcp --dport 80 -j ACCEPT
-A INPUT -p tcp -m state --state NEW -m tcp --dport 443 -j ACCEPT
-A INPUT -p tcp -m state --state NEW -m tcp --dport 6443 -j ACCEPT
-A INPUT -p tcp -m state --state NEW -m tcp --dport 10250 -j ACCEPT
-A INPUT -p tcp -m state --state NEW -m tcp --dport 5001 -j ACCEPT
-A INPUT -p udp -m state --state NEW -m udp --dport 51820 -j ACCEPT
```
`close and save the file`

### Step 3: Restore the firewall
```bash
sudo iptables-restore < /etc/iptables/rules.v4
sudo iptables -L INPUT
```

## Set a fully qualified domain name. (Master nodes only)

### Step 1: Set hostname and edit /etc/hosts
```bash
sudo hostnamectl set-hostname mail.example.com
sudo nano /etc/hosts
```
### Step 2: Edit it like below.
```text
127.0.0.1       mail.example.com localhost
```
Save and close the file. (To save a file in Nano text editor, press Ctrl+O, then press Enter to confirm. To close the file, press Ctrl+X.)


## Install K3s

### Step 1: Create config directory
```bash
sudo mkdir -p /etc/rancher/k3s
```

### Step 2: Create kublet config file
```bash
sudo tee /etc/rancher/k3s/kubelet.config <<EOF
apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration
shutdownGracePeriod: 30s
shutdownGracePeriodCriticalPods: 10s
EOF
```

### Step 3: Generate secret for master node
```bash
openssl rand -hex 10 > /etc/rancher/k3s/cluster-token
```

## Master Nodes Configuration
### Step 1: Prepare K3s config file.
```bash
sudo tee /etc/rancher/k3s/config.yaml <<EOF
token-file: /etc/rancher/k3s/cluster-token
disable:
- local-storage
- servicelb
- traefik
etcd-expose-metrics: true
kube-controller-manager-arg:
- bind-address=0.0.0.0
- terminated-pod-gc-threshold=10
kube-proxy-arg:
- metrics-bind-address=0.0.0.0
kube-scheduler-arg:
- bind-address=0.0.0.0
kubelet-arg:
- config=/etc/rancher/k3s/kubelet.config
node-taint:
- node-role.kubernetes.io/master=true:NoSchedule
tls-san:
- master01.barrzen.com
write-kubeconfig-mode: 644

EOF
```
### Step 2: Execute below commands to install k3s
```bash
curl -sfL https://get.k3s.io | sh -s - --write-kubeconfig-mode 644
```

## Worker Nodes Configuration
### Step 1: Prepare K3s config file.
```bash
sudo tee /etc/rancher/k3s/config.yaml <<EOF
token-file: /etc/rancher/k3s/cluster-token
node-label:
  - 'node_type=worker'
kubelet-arg:
  - 'config=/etc/rancher/k3s/kubelet.config'
kube-proxy-arg:
  - 'metrics-bind-address=0.0.0.0'

EOF
```

### Step 2: Execute below commands to install k3s
```bash
curl -sfL https://get.k3s.io | sh -s - agent --server https://master01.barrzen.com:6443
```

### Step 3: Label worker nodes as worker
```bash
kubectl label nodes worker01 kubernetes.io/role=worker
```

## Instal kubctl & helm on local machine

### Step 1: Install kubectl (Linux only)
```bash
# Command for x86_64
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

# Command for arm64
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/arm64/kubectl"

# Install kubectl
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Check kubectl version
kubectl version --client
```

### Step 2: Install helm
```bash
# Install command
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Check helm version
helm version
```

### Step 3: Install kubecolor & arkade
```bash
helm repo add kubecolor https://kubecolor.github.io/charts
helm repo update
helm install kubecolor kubecolor/kubecolor

curl -sLS https://get.arkade.dev | sudo sh
```
