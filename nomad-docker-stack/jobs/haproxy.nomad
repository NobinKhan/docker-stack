job "haproxy" {
  datacenters = ["dc1"]
  type = "system"

  group "ingress" {
    network {
      port "http" { to = 80 }
      port "https" { to = 443 }
    }

    task "haproxy" {
      driver = "docker"
      config {
        image = "haproxy:2.8"
        ports = ["http", "https"]
      }
    }
  }
}
