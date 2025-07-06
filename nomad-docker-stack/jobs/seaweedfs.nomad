job "seaweedfs" {
  datacenters = ["dc1"]
  type        = "system"

  group "seaweedfs" {
    network {
      mode = "host"
    }

    task "master" {
      driver = "docker"
      config {
        image = "chrislusf/seaweedfs:3.65"
        command = "master"
        ports = ["master-http", "master-grpc"]
      }
      resources {
        ports = {
          "master-http" = 9333
          "master-grpc" = 19333
        }
      }
    }

    task "volume" {
      driver = "docker"
      config {
        image = "chrislusf/seaweedfs:3.65"
        command = "volume"
        args = [
          "-mserver=localhost:9333",
          "-ip=localhost"
        ]
        ports = ["volume-http", "volume-grpc"]
      }
      resources {
        ports = {
          "volume-http" = 8080
          "volume-grpc" = 18080
        }
      }
    }

    task "filer" {
      driver = "docker"
      config {
        image = "chrislusf/seaweedfs:3.65"
        command = "filer"
        args = ["-master=localhost:9333"]
        ports = ["filer-http", "filer-grpc"]
      }
      resources {
        ports = {
          "filer-http" = 8888
          "filer-grpc" = 18888
        }
      }
    }
  }
}
