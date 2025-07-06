job "webapp" {
  datacenters = ["dc1"]
  group "app" {
    count = 2
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
        tags = ["haproxy.enable=true"]
      }
    }
  }
}
