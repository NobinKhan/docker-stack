# Enterprise-Grade Nomad Stack: The Containerized Guide

This guide details the deployment of a highly secure, resilient, and scalable application platform on Nomad using a fully containerized approach with Docker Compose. This method provides an isolated, portable, and easy-to-manage environment.

## Architecture

*   **Docker Compose**: Orchestrates the entire stack, including Nomad, Consul, and Vault.
*   **HashiCorp Vault**: Manages all secrets.
*   **SeaweedFS**: Provides persistent, distributed storage for stateful applications.
*   **HAProxy**: Acts as the load balancer, dynamically configured via `consul-template`.
*   **Certbot & Cloudflare**: Automates SSL certificate acquisition and renewal.
*   **Nomad & Consul**: The core orchestrator and service discovery backbone.

## Prerequisites

*   A server with Docker and Docker Compose installed.
*   A domain name managed through Cloudflare.
*   A Cloudflare API Token with `Zone:DNS:Edit` permissions.

## Setup

1.  **Clone the Repository**: Clone this repository to your local machine.
2.  **Navigate to the Directory**: `cd nomad-docker-stack`

## Step 1: Start the Core Infrastructure

This single command will start the Consul, Vault, and Nomad containers in detached mode:

```bash
docker-compose up -d
```

## Step 2: Initialize and Configure Vault

1.  **Exec into the Vault Container**:

    ```bash
    docker exec -it vault /bin/sh
    ```

2.  **Initialize Vault**:

    ```bash
    vault operator init
    ```

    **IMPORTANT**: Save the Unseal Keys and the Initial Root Token. You will need them.

3.  **Unseal Vault**: Use the unseal keys from the previous step.

    ```bash
    vault operator unseal <UNSEAL_KEY_1>
    vault operator unseal <UNSEAL_KEY_2>
    vault operator unseal <UNSEAL_KEY_3>
    ```

4.  **Log in to Vault**:

    ```bash
    vault login <INITIAL_ROOT_TOKEN>
    ```

5.  **Configure Vault for Nomad**:

    ```bash
    # Enable Key/Value v2 secrets engine
    vault secrets enable -path=secret kv-v2

    # Put your secrets into Vault
    vault kv put secret/cloudflare/dns token=YOUR_CLOUDFLARE_API_TOKEN
    vault kv put secret/postgres password=A_VERY_SECURE_DB_PASSWORD

    # Enable Nomad integration
    vault auth enable nomad

    # Configure the Nomad integration
    vault write auth/nomad/config address="http://nomad:4646"

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
    ```

6.  **Exit the Vault Container**:

    ```bash
    exit
    ```

## Step 3: Deploy Nomad Jobs

Now that the core infrastructure is running and configured, you can deploy the Nomad jobs.

1.  **Deploy SeaweedFS and its CSI Driver**:

    ```bash
    nomad job run jobs/seaweedfs.nomad
    nomad job run jobs/seaweedfs-csi.nomad
    ```

2.  **Verify CSI**:

    ```bash
    nomad volume status
    ```

3.  **Deploy HAProxy**:

    ```bash
    nomad job run jobs/haproxy.nomad
    ```

4.  **Deploy Applications**:

    ```bash
    nomad job run jobs/postgres.nomad
    nomad job run jobs/webapp.nomad
    ```

## Conclusion

You now have a fully containerized, enterprise-grade Nomad stack running on your machine. You can access the UIs for each component at:

*   **Nomad**: http://localhost:4646
*   **Consul**: http://localhost:8500
*   **Vault**: http://localhost:8200
