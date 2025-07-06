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
          "--filer=localhost:8888"
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
