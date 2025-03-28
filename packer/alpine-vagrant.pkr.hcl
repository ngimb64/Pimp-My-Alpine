variable "iso_url" {
  type    = string
  default = "http://dl-cdn.alpinelinux.org/alpine/latest-stable/releases/x86_64/alpine-standard.iso"
}

variable "iso_checksum" {
  type    = string
  default = "your_iso_checksum_here"
}

source "virtualbox-iso" "alpine_vagrant" {
  iso_url      = var.iso_url
  iso_checksum = var.iso_checksum

  vm_name        = "alpine-vagrant"
  shutdown_command = "echo 'powered off'"
  communicator     = "none"
  disk_size        = 10240
  headless         = true

  boot_wait       = "10s"
  boot_command    = [
    "<wait5><enter>"
  ]
}

build {
  name    = "alpine-vagrant-build"
  sources = ["source.virtualbox-iso.alpine_vagrant"]

  provisioner "shell" {
    environment_vars = [
      "HARDENING_LEVEL=high",
      "EXTRA_PACKAGES=vim,htop"
    ]
    script = "scripts/harden_alpine.sh"
  }

  post-processor "vagrant" {
    output = "alpine-hardened.box"
  }
}
