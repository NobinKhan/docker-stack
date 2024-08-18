# K3s Cluster Install Instruction

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
- 10.0.0.11
write-kubeconfig-mode: 0644

EOF
```
```bash
curl -sfL https://get.k3s.io | K3S_TOKEN=<server_token> sh -s - server --write-kubeconfig-mode '0644' --node-taint 'node-role.kubernetes.io/control-plane:NoSchedule' --disable 'servicelb' --disable 'traefik' --disable 'local-storage' --kube-controller-manager-arg 'bind-address=0.0.0.0' --kube-proxy-arg 'metrics-bind-address=0.0.0.0' --kube-scheduler-arg 'bind-address=0.0.0.0' --kubelet-arg 'config=/etc/rancher/k3s/kubelet.config' --kube-controller-manager-arg 'terminated-pod-gc-threshold=10'

curl -sfL https://get.k3s.io | sh -s - --write-kubeconfig-mode 644 --disable servicelb --token some_random_password --node-taint CriticalAddonsOnly=true:NoExecute --bind-address 192.168.0.10 --disable-cloud-controller --disable local-storage

curl -sfL https://get.k3s.io | K3S_TOKEN=`cat k3s_secret.txt` sh -s - server --cluster-init --disable=servicelb
```
