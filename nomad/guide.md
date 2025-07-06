## Introduction

This guide will walk you through setting up a powerful, production-ready, single-server application platform using HashiCorp Nomad and Consul, with Traefik as a reverse proxy for automatic service discovery and SSL. This setup is designed for simplicity on a single node while being architecturally prepared for seamless expansion to a multi-server cluster.

### The final architecture will look like this:

*   **Cloudflare:** Manages your DNS and acts as a proxy (orange cloud), providing DDoS protection and hiding your server's IP.
*   **Traefik (Reverse Proxy):** Runs as a Nomad job, listens for traffic, and automatically discovers other services. It will handle routing (`pgadmin.your_domain.com` -> pgAdmin container) and obtain Let's Encrypt SSL certificates using a secure DNS challenge.
*   **Nomad (Orchestrator):** Runs as both a server and client. It manages the lifecycle of all your applications (Traefik, Postgres, pgAdmin, etc.).
*   **Consul (Service Discovery):** Provides a service catalog. Nomad registers services with Consul, and Traefik reads from it to configure its routing rules.
*   **Docker:** The container runtime managed by Nomad.

### Prerequisites

*   **Server:** A Linux server (Ubuntu 22.04 is recommended) with a public IP address.
*   **Domain Name:** A domain you own, managed through Cloudflare.
*   **Cloudflare API Token:** An API token with `Zone:DNS:Edit` permissions for your domain.
*   **Software:** `docker`, `nomad`, and `consul` installed on the server.
*   **Firewall:** Ports `80` (HTTP), `443` (HTTPS), and `22` (SSH) should be open to the internet.

## Step 1: Install Dependencies

First, install Docker, Nomad, and Consul on your server.

```bash
# Update package list
sudo apt-get update

# Install Docker
sudo apt-get install -y docker.io
```

# Install HashiCorp GPG key and repository
```
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list

# Install Nomad and Consul
sudo apt-get update && sudo apt-get install -y nomad consul

## Step 2: Configure and Run Consul

We'll configure Consul to run as a single server. The `bootstrap_expect = 1` is key for a single-node setup.

Create the configuration file:

sudo mkdir -p /etc/consul.d
sudo touch /etc/consul.d/consul.hcl
```

Edit the file `sudo nano /etc/consul.d/consul.hcl` and add the following content. Replace `eth0` with your server's primary network interface if it's different (use `ip a` to check).

```hcl
# /etc/consul.d/consul.hcl
data_dir = "/opt/consul"
client_addr = "127.0.0.1"
bind_addr = "{{ GetInterfaceIP \"eth0\" }}"
server = true
bootstrap_expect = 1
ui_config {
  enabled = true
}
ports {
  dns = 53
}
```

Create the data directory and set permissions:
```bash
sudo mkdir /opt/consul
sudo chown -R consul:consul /opt/consul
```

Start and enable the Consul service:
```bash
sudo systemctl enable consul
sudo systemctl start consul
```

Verify: Check the status with `sudo systemctl status consul` and see cluster members with `consul members`.

## Step 3: Configure and Run Nomad

Now, configure Nomad to run in both server and client mode and connect it to Consul.

Create the configuration file:
```bash
sudo mkdir -p /etc/nomad.d
sudo touch /etc/nomad.d/nomad.hcl
```

Edit the file `sudo nano /etc/nomad.d/nomad.hcl` and add the following:

```hcl
# /etc/nomad.d/nomad.hcl
data_dir = "/opt/nomad"
bind_addr = "{{ GetInterfaceIP \"eth0\" }}"
server {
  enabled = true
  bootstrap_expect = 1
}
client {
  enabled = true
}
consul {
  address = "127.0.0.1:8500"
}
```

Create the data directory and set permissions:
```bash
sudo mkdir /opt/nomad
sudo chown -R nomad:nomad /opt/nomad
```

Start and enable the Nomad service:
```bash
sudo systemctl enable nomad
sudo systemctl start nomad
```

Verify: Run `nomad node status` and `nomad server members`. You should see one node that is both ready and alive.

## Step 4: Cloudflare DNS Setup

In your Cloudflare dashboard, create an A record pointing to your server's public IP. Using the DNS challenge for SSL means you can and should keep the Cloudflare proxy active (orange cloud).

**Wildcard Record for Services:**
*   **Type:** `A`
*   **Name:** `*` (This will cover `pgadmin.your_domain.com`, `webapp.your_domain.com`, etc.)
*   **IPv4 address:** `<your_server_ip>`
*   **Proxy status:** Proxied (Orange cloud). This is now recommended.

## Step 5: Deploy the Reverse Proxy (Traefik v3)

We will run Traefik v3 as a Nomad job, configured to use Cloudflare's DNS challenge for SSL.

Create the Traefik job file: `touch traefik.nomad`

Add the following content. Replace `your_email@example.com` and `your_cloudflare_api_token`.

```nomad
# traefik.nomad
job "traefik" {
  datacenters = ["dc1"]
  type        = "system"

  group "traefik" {
    network {
      port "http" { to = 80 }
      port "https" { to = 443 }
    }

    volume "acme" {
      type      = "host"
      source    = "traefik-acme"
      read_only = false
    }

    task "traefik" {
      driver = "docker"

      # Use Traefik v3
      config {
        image = "traefik:v3.0"
        ports = ["http", "https"]
        args = [
          "--api.dashboard=true",
          "--providers.consulcatalog.prefix=traefik",
          "--providers.consulcatalog.exposedbydefault=false",
          "--entrypoints.web.address=:80",
          "--entrypoints.websecure.address=:443",
          "--entrypoints.web.http.redirections.entrypoint.to=websecure",
          "--entrypoints.web.http.redirections.entrypoint.scheme=https",
          "--certificatesresolvers.le.acme.email=your_email@example.com",
          "--certificatesresolvers.le.acme.storage=/acme/acme.json",
          # Use the DNS-01 challenge with Cloudflare
          "--certificatesresolvers.le.acme.dnschallenge.provider=cloudflare"
        ]
      }

      # IMPORTANT: Securely provide your Cloudflare API token
      # In a real production setup, use Nomad's variable system or Vault.
      env {
        CLOUDFLARE_DNS_API_TOKEN = "your_cloudflare_api_token"
      }

      volume_mount {
        volume      = "acme"
        destination = "/acme"
        read_only   = false
      }

      service {
        name = "traefik-dashboard"
        port = "http"
        tags = [
          "traefik.enable=true",
          "traefik.http.routers.traefik.rule=Host(`traefik.your_domain.com`)",
          "traefik.http.routers.traefik.service=api@internal", # Use the internal API service in v3
          "traefik.http.routers.traefik.entrypoints=websecure",
          "traefik.http.routers.traefik.tls.certresolver=le"
        ]
      }
    }
  }
}
```

Run the job: `nomad job run traefik.nomad`

## Step 6: Deploy Your Applications

The application job files remain largely the same, but the Traefik tags are slightly updated for clarity.

### A. PostgreSQL (Private, with Persistent Data)

This job remains unchanged. It uses a host volume, which is fine for a single node. See Step 7 for multi-node persistence.

```nomad
# postgres.nomad
job "postgres" {
  datacenters = ["dc1"]
  type        = "service"
  group "db" {
    volume "pgdata" {
      type   = "host"
      source = "postgres-data"
    }
    task "postgres" {
      driver = "docker"
      config {
        image = "postgres:15"
        ports = ["db"]
        volume_mount {
          volume      = "pgdata"
          destination = "/var/lib/postgresql/data"
        }
        env {
          POSTGRES_USER     = "admin"
          POSTGRES_PASSWORD = "a_very_secure_password" # Change this!
          POSTGRES_DB       = "appdb"
        }
      }
      service {
        name = "postgres"
        port = "db"
      }
      resources {
        cpu    = 500
        memory = 1024
        network {
          port "db" { static = 5432 }
        }
      }
    }
  }
}
```

Run the job: `nomad job run postgres.nomad`

### B. pgAdmin4 & My Web App (Public)

The job files for pgadmin and webapp are also the same. The key is that the `traefik.http.routers.*.tls.certresolver=le` tag tells Traefik to automatically get a certificate for the specified host using the "le" resolver we configured with the DNS challenge.

## Step 7: Advanced Topics and Next Steps

This guide covers the basics of getting a single-node cluster running. For the next steps in your production journey, including scaling, security, and persistent storage, please see the following detailed guide:

*   **[Advanced Guide: Nomad Variables and SeaweedFS Storage](./variables_and_storage_guide.md)**
    *   Securely managing secrets (e.g., API tokens, database credentials) with Nomad's built-in variables.
    *   Setting up a distributed and persistent storage layer with SeaweedFS and the official CSI driver.

For your record the latest version:
consul -v
Consul v1.21.2
Revision 136b9cb8
Build Date 2025-06-18T08:16:39Z

nomad -v
Nomad v1.10.2
BuildDate 2025-06-09T22:00:49Z

Can you please generate another Guide for me where you should use the latest version in mind so that configs don't get messed up. I need some extraa things and changes like below in this new guide.
1. Securely managing secrets (e.g., API tokens, database credentials) with Nomad's built-in variables or vaoult (you can choose the better one for my case).
2. Setting up a distributed and persistent storage layer with SeaweedFS and the official CSI driver. (when I will add more server it will help to distribute files or data also include how make a backup the data in s3 if it's possible)
3. Traefik is very good reverse proxy but i personaly like haproxy. if think haproxy is also possible to use in our setup then replace traefik with haproxy and keep in mind that we need to configure ssl certs with cloudflare.
