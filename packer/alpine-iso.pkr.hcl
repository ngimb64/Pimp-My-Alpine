variable "iso_url" {
  type    = string
  default = "http://dl-cdn.alpinelinux.org/alpine/latest-stable/releases/x86_64/alpine-standard.iso"
}

variable "iso_checksum" {
  type    = string
  default = "your_iso_checksum_here"
}

# Define a source that builds the ISO image (using VirtualBox in this example)
source "virtualbox-iso" "alpine_iso" {
  iso_url      = var.iso_url
  iso_checksum = var.iso_checksum

  # Builder-specific settings
  vm_name        = "alpine-iso"
  shutdown_command = "echo 'powered off'"
  communicator     = "none"
  disk_size        = 10240
  headless         = true

  # Additional builder options (e.g. boot commands, http_directory, etc.)
  boot_wait       = "10s"
  boot_command    = [
    "<wait5><enter>"
  ]
}

build {
  name    = "alpine-iso-build"
  sources = ["source.virtualbox-iso.alpine_iso"]

  provisioner "shell" {
    # You can pass in environment variables here or have your script read them from the environment
    environment_vars = [
      "HARDENING_LEVEL=high",
      "EXTRA_PACKAGES=vim,htop"
    ]
    script = "scripts/harden_alpine.sh"
  }
}
