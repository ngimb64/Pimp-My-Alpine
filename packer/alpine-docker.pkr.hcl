variable "docker_base_image" {
  type    = string
  default = "alpine:latest"
}

source "docker" "alpine" {
  image  = var.docker_base_image
  commit = true
}

build {
  name    = "alpine-docker-build"
  sources = ["source.docker.alpine"]

  provisioner "shell" {
    environment_vars = [
      "HARDENING_LEVEL=high",
      "EXTRA_PACKAGES=vim,htop"
    ]
    inline = [
      "apk update",
      "sh /scripts/harden_alpine.sh"
    ]
  }

  post-processor "docker-tag" {
    repository = "alpine-hardened"
    tag        = "latest"
  }
}

