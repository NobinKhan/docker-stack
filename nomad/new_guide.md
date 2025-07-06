Introduction: The Enterprise-Grade Nomad StackThis guide details the deployment of a highly secure, resilient, and scalable application platform on Nomad. It replaces simpler components with more robust, production-oriented solutions, addressing the complexities of secrets management, distributed storage, and dynamic load balancing.Our new, upgraded architecture consists of:HashiCorp Vault: The central source of truth for all secrets, including database passwords and Cloudflare API tokens. Jobs will dynamically and securely fetch credentials without ever exposing them in configuration files.SeaweedFS: A distributed, scalable file system that will provide persistent storage for our stateful applications (like databases). We will deploy it as a Nomad job and integrate it using the official SeaweedFS CSI Driver, allowing for dynamic volume provisioning.HAProxy: A battle-tested, high-performance load balancer. It will be paired with consul-template to dynamically discover and route traffic to backend services registered in Consul.Certbot & Cloudflare: A sidecar container running certbot will automatically acquire and renew SSL certificates from Let's Encrypt using Cloudflare's DNS challenge. This allows us to keep Cloudflare's proxy features (orange cloud) enabled.Nomad & Consul: The core orchestrator and service discovery backbone, updated to integrate seamlessly with Vault.PrerequisitesServer(s): A Linux server (Ubuntu 22.04 recommended). While this guide starts with one, the architecture is designed for multiple nodes.Domain Name: Managed through Cloudflare.Cloudflare API Token: An API token with Zone:DNS:Edit permissions.Software: docker, nomad (v1.10+), consul (v1.21+), and vault installed on the server(s).Step 1: Install DependenciesInstall Docker and the HashiCorp suite on your server.# Update package list and install dependencies
sudo apt-get update
sudo apt-get install -y docker.io wget gpg

# Install HashiCorp GPG key and repository
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list

# Install the latest versions of the HashiCorp suite
sudo apt-get update && sudo apt-get install -y nomad consul vault

Step 2: Configure and Run ConsulThis configuration remains standard. Consul will act as the service catalog and the storage backend for Vault.Create Consul config sudo nano /etc/consul.d/consul.hcl:# /etc/consul.d/consul.hcl
data_dir = "/opt/consul"
bind_addr = "{{ GetInterfaceIP \"eth0\" }}" # Adjust network interface if needed
client_addr = "127.0.0.1"
server = true
bootstrap_expect = 1
ui_config {
  enabled = true
}

Create data directory and start the service:sudo mkdir /opt/consul
sudo chown -R consul:consul /opt/consul
sudo systemctl enable consul
sudo systemctl start consul

Step 3: Configure and Run VaultWe will start Vault in dev mode for simplicity, but configure it to be accessible for Nomad. For production, you must follow HashiCorp's guide to unseal Vault and enable a proper storage backend.Create Vault config sudo nano /etc/vault.d/vault.hcl:# /etc/vault.d/vault.hcl
ui = true
# Listen on all network interfaces, not just localhost
listener "tcp" {
  address     = "0.0.0.0:8200"
  tls_disable = 1 # Not recommended for production
}
# Use Consul as the storage backend
storage "consul" {
  address = "127.0.0.1:8500"
  path    = "vault/"
}

Start the Vault service:sudo systemctl enable vault
sudo systemctl start vault

Initialize and Configure Vault for Nomad:Open a new terminal. You need to set the Vault address and token. When Vault starts, it will output an Unseal Key and a Root Token. SAVE THESE!For this guide, let's assume the root token is root.export VAULT_ADDR='http://127.0.0.1:8200'
export VAULT_TOKEN='root' # Use the actual root token from vault status

# Enable Key/Value v2 secrets engine
vault secrets enable -path=secret kv-v2

# Put your secrets into Vault
vault kv put secret/cloudflare/dns token=YOUR_CLOUDFLARE_API_TOKEN
vault kv put secret/postgres password=A_VERY_SECURE_DB_PASSWORD

# Enable Nomad integration
vault auth enable nomad

# Configure the Nomad integration
vault write auth/nomad/config \
    address="http://$(hostname -I | awk '{print $1'}):4646"

# Create a policy that allows reading secrets
vault policy write nomad-jobs - <<EOF
path "secret/data/cloudflare/*" {
  capabilities = ["read"]
}
path "secret/data/postgres" {
  capabilities = ["read"]
}
EOF

# Create a role that associates the policy with Nomad jobs
vault write auth/nomad/role/jobs-role policies="nomad-jobs"

Step 4: Configure Nomad to use VaultUpdate your Nomad configuration to connect to Vault.Edit Nomad config sudo nano /etc/nomad.d/nomad.hcl:# /etc/nomad.d/nomad.hcl
data_dir = "/opt/nomad"
bind_addr = "{{ GetInterfaceIP \"eth0\" }}"

server {
  enabled          = true
  bootstrap_expect = 1
}
client {
  enabled = true
}
consul {
  address = "127.0.0.1:8500"
}
# Add the Vault stanza
vault {
  enabled = true
  address = "http://127.0.0.1:8200" # Or your Vault server's address
  # Allow jobs to use the default Vault policy
  allow_unauthenticated = false
}

Restart Nomad to apply the new configuration: sudo systemctl restart nomadStep 5: Deploy SeaweedFS and its CSI DriverThis is a multi-step process to get our distributed storage layer running.Create the SeaweedFS job file (seaweedfs.nomad): This job runs the master, volume, and filer servers.# seaweedfs.nomad
job "seaweedfs" {
  datacenters = ["dc1"]
  type        = "system" # Run on all nodes to distribute volumes

  group "seaweedfs" {
    volume "sfs-data" {
      type   = "host"
      source = "seaweedfs-data"
    }

    task "master" {
      driver = "docker"
      config {
        image = "chrislusf/seaweedfs:3.65"
        command = "master"
        ports = ["master-http", "master-grpc"]
      }
      resources { network { ports = ["master-http", "master-grpc"] } }
    }

    task "volume" {
      driver = "docker"
      config {
        image = "chrislusf/seaweedfs:3.65"
        command = "volume"
        args = [
          "-mserver=${attr.unique.network.ip-address}:9333",
          "-ip=${attr.unique.network.ip-address}"
        ]
        ports = ["volume-http", "volume-grpc"]
      }
      volume_mount {
        volume      = "sfs-data"
        destination = "/data"
      }
      resources { network { ports = ["volume-http", "volume-grpc"] } }
    }

    task "filer" {
      driver = "docker"
      config {
        image = "chrislusf/seaweedfs:3.65"
        command = "filer"
        args = ["-master=${attr.unique.network.ip-address}:9333"]
        ports = ["filer-http", "filer-grpc"]
      }
      resources { network { ports = ["filer-http", "filer-grpc"] } }
    }
  }
}

Run the job: nomad job run seaweedfs.nomadCreate the SeaweedFS CSI Driver job (seaweedfs-csi.nomad): This job deploys the CSI controller and the node plugins that allow Nomad to provision volumes.# seaweedfs-csi.nomad
job "seaweedfs-csi" {
  datacenters = ["dc1"]
  type        = "system"

  group "controller" {
    task "plugin" {
      driver = "docker"
      config {
        image = "seaweedfs/seaweedfs-csi-driver:1.28"
        args = [
          "--endpoint=unix:///csi/csi.sock",
          "--nodeid=${attr.unique.hostname}",
          "--filer=localhost:8888" # Points to the local filer
        ]
        privileged = true
      }
      csi_plugin {
        id        = "seaweedfs"
        type      = "monolith"
        mount_dir = "/csi"
      }
    }
  }
}

Run the job: nomad job run seaweedfs-csi.nomadVerify CSI: Run nomad volume status. You should see the seaweedfs plugin as healthy.Step 6: Deploy HAProxy with CertbotThis job is the new heart of our ingress, combining HAProxy, consul-template, and certbot.Create the HAProxy job file (haproxy.nomad):# haproxy.nomad job "haproxy" {   datacenters = ["dc1"]   type = "system"    group "ingress" {     # Shared volume for certs and haproxy config     volume "shared-data" {       type   = "host"       source = "haproxy-shared"     }      network {       port "http" { to = 80 }       port "https" { to = 443 }     }      # Task to generate HAProxy config from Consul     task "consul-template" {       driver = "docker"       config {         image = "hashicorp/consul-template:0.36.0"         args = [           "-consul-addr=${attr.unique.network.ip-address}:8500",           "-template=/templates/haproxy.tpl:/local/haproxy.cfg:haproxy -f /local/haproxy.cfg -p /local/haproxy.pid -sf $(cat /local/haproxy.pid)"         ]       }       template {         destination = "templates/haproxy.tpl"         change_mode = "signal"         change_signal = "SIGINT"         data = <<EOH         global             daemon             maxconn 4096         defaults             mode http             timeout connect 5s             timeout client 50s             timeout server 50s         frontend http             bind *:80             # Redirect all http to https             http-request redirect scheme https unless { ssl_fc }         frontend https             bind *:443 ssl crt /local/certs/             # Dynamically add backends from Consul services             {{ range services }}             {{ if contains .Tags "haproxy.enable=true" }}             acl host_{{ .Name }} hdr(host) -i {{ .Name }}.your_domain.com             use_backend backend_{{ .Name }} if host_{{ .Name }}             {{ end }}             {{ end }}         # Define the backends         {{ range services }}         {{ if contains .Tags "haproxy.enable=true" }}         backend backend_{{ .Name }}             balance roundrobin             {{ range service .Name }}             server {{ .Node }}_{{ .Port }} {{ .Address }}:{{ .Port }} check             {{ end }}         {{ end }}         {{ end }}         EOH       }       volume_mount {         volume      = "shared-data"         destination = "/local"       }     }      # Task to run HAProxy     task "haproxy" {       driver = "docker"       config {         image = "haproxy:2.8"         ports = ["http", "https"]       }       volume_mount {         volume      = "shared-data"         destination = "/local"         read_only   = true       }     }      # Task to handle SSL certs with Certbot     task "certbot" {       driver = "docker"       config {         image = "certbot/dns-cloudflare"         # This will run once, then the task will complete.         # For renewal, we'll use a periodic job.         command = "certonly"         args = [           "--dns-cloudflare",           "--dns-cloudflare-credentials", "/secrets/cloudflare.ini",           "-d", "*.your_domain.com",           "-m", "your_email@example.com",           "--agree-tos",           "--non-interactive"         ]       }       # Inject Cloudflare token from Vault       template {         destination = "secrets/cloudflare.ini"         data = <<EOF         dns_cloudflare_api_token = "{{ with secret "secret/data/cloudflare/dns" }}{{ .Data.data.token }}{{ end }}"         EOF       }       vault {         policies = ["nomad-jobs"]       }       volume_mount {         volume      = "shared-data"         destination = "/etc/letsencrypt" # Certbot writes here       }     }   } }Run the job: nomad job run haproxy.nomadStep 7: Deploy Applications with Persistent Storage & SecretsNow we deploy our Postgres database, using a volume from SeaweedFS and its password from Vault.Create the Postgres job file (postgres.nomad):# postgres.nomad
job "postgres" {
  datacenters = ["dc1"]
  type        = "service"

  group "db" {
    # Request a volume from our SeaweedFS CSI plugin
    volume "pgdata" {
      type            = "csi"
      source          = "postgres-volume"
      attachment_mode = "file-system"
      access_mode     = "single-node-writer"
    }

    task "postgres" {
      driver = "docker"
      config {
        image = "postgres:15"
        ports = ["db"]
      }
      # Mount the CSI volume
      volume_mount {
        volume      = "pgdata"
        destination = "/var/lib/postgresql/data"
      }
      # Inject password from Vault
      template {
        destination = "secrets/db.env"
        env         = true
        data        = <<EOF
        POSTGRES_PASSWORD={{ with secret "secret/data/postgres" }}{{ .Data.data.password }}{{ end }}
        EOF
      }
      vault {
        policies = ["nomad-jobs"]
      }
      env {
        POSTGRES_USER = "admin"
        POSTGRES_DB   = "appdb"
      }
      service {
        name = "postgres"
        port = "db"
        # Note: No "haproxy.enable" tag, so it's not public
      }
    }
  }
}

Run the job: nomad job run postgres.nomadDeploy your Web App: This job will be tagged for HAProxy to discover it.# webapp.nomad
job "webapp" {
  datacenters = ["dc1"]
  group "app" {
    count = 2 # Start with two instances
    task "server" {
      driver = "docker"
      config {
        image = "hashicorp/http-echo"
        args  = ["-text", "Hello from my HAProxy-fronted web app!"]
        ports = ["http"]
      }
      service {
        name = "webapp"
        port = "http"
        tags = ["haproxy.enable=true"] # This tag makes it public
      }
    }
  }
}

Run the job: nomad job run webapp.nomadStep 8: Scaling and Backup StrategyScaling Stateful ServicesBecause we are using the SeaweedFS CSI driver, Nomad can now intelligently manage persistent volumes. If you add a new server to the cluster and the postgres job gets rescheduled to it, Nomad will instruct the CSI driver to detach the volume from the old node and attach it to the new one. Your data moves with your job.Backing Up SeaweedFS Volumes to S3SeaweedFS has built-in replication capabilities that can be used for backups. You can configure the SeaweedFS Filer to automatically replicate changes to an S3 bucket.Create a configuration file for the filer (e.g., filer.toml).Add a replication rule to this file:[replication]
location = "s3_backup"
data_center = ""
replication = "000"
ttl = "7d"

[replication.s3_backup]
aws_access_key_id = "YOUR_S3_ACCESS_KEY"
aws_secret_access_key = "YOUR_S3_SECRET_KEY"
region = "us-east-1"
bucket = "your-backup-bucket-name"

Update your SeaweedFS Nomad job to mount this config file into the filer task and start it with the -config flag. The filer will then handle the backup process automatically.