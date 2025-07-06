data_dir  = "/opt/nomad"
bind_addr = "0.0.0.0"

server {
  enabled          = true
  bootstrap_expect = 1
}

client {
  enabled = true
  options = {
    "docker.privileged.enabled" = "true"
  }
}

consul {
  address = "consul:8500"
}

vault {
  enabled = true
  address = "http://vault:8200"
}
