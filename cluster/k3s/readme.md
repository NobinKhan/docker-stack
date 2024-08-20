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
```text
-A INPUT -p tcp -m state --state NEW -m tcp --dport 80 -j ACCEPT
-A INPUT -p tcp -m state --state NEW -m tcp --dport 443 -j ACCEPT
-A INPUT -p tcp -m state --state NEW -m tcp --dport 6443 -j ACCEPT
-A INPUT -p tcp -m state --state NEW -m tcp --dport 10250 -j ACCEPT
-A INPUT -p tcp -m state --state NEW -m tcp --dport 5001 -j ACCEPT
-A INPUT -p udp -m state --state NEW -m udp --dport 51820 -j ACCEPT
```
## Add above rules in firewall settings and restore the firewall
```bash
sudo iptables -L INPUT
sudo iptables-restore < /etc/iptables/rules.v4
```
## To set a fully qualified domain name (FQDN) for your server with the following command.

```bash
sudo hostnamectl set-hostname mail.your-domain.com
sudo nano /etc/hosts
```
## Edit it like below. (Use arrow keys to move the cursor in the file.)
```text
127.0.0.1       mail.your-domain.com localhost
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

### Step 4: Prepare K3s config file
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
- master-01.barrzen.com
write-kubeconfig-mode: 0644

EOF
```

### Step 5: Prepare K3s config file worker
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

```bash
curl -sfL https://get.k3s.io | sh -s - --write-kubeconfig-mode 644

curl -sfL https://get.k3s.io | sh -s - agent --server https://master01.barrzen.com:6443

kubectl label nodes worker01 kubernetes.io/role=worker
```
