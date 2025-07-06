job "postgres" {
  datacenters = ["dc1"]
  type        = "service"

  group "db" {
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
      volume_mount {
        volume      = "pgdata"
        destination = "/var/lib/postgresql/data"
      }
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
      }
    }
  }
}
