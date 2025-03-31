# Required variables section
variable "ADMIN" {
  description = "Admin username"
  type        = string
}

variable "ADMIN_PASS" {
  description = "Admin password"
  type        = string
  sensitive   = true
}

variable "USER" {
  description = "User username"
  type        = string
}

variable "USER_PASS" {
  description = "User password"
  type        = string
  sensitive   = true
}

variable "ROOT_PASS" {
  description = "Root password"
  type        = string
  sensitive   = true
}

# Optional variables section
variable "SSID" {
  description = "Optional SSID"
  type        = string
  default     = ""
  sensitive   = true
}

variable "WIFI_PASS" {
  description = "Optional WIFI password"
  type        = string
  default     = ""
  sensitive   = true
}

variable "HOSTNAME" {
  description = "Optional hostname"
  type        = string
  default     = ""
}

variable "DNS_OPTS" {
  description = "Optional DNS options"
  type        = string
  default     = ""
}

variable "SSH" {
  description = "Optional SSH config"
  type        = string
  default     = "openssh"
}

variable "NTP" {
  description = "Optional NTP settings"
  type        = string
  default     = "openntpd"
}

variable "DISK_OPTS" {
  description = "Optional disk options"
  type        = string
  default     = ""
}

variable "PACKAGES" {
  description = "Optional packages to install"
  type        = string
  default     = ""
}

locals {
  env_vars_list = [
    "ADMIN=${var.ADMIN}",
    "ADMIN_PASS=${var.ADMIN_PASS}",
    "USER=${var.USER}",
    "USER_PASS=${var.USER_PASS}",
    "ROOT_PASS=${var.ROOT_PASS}",
    "SSID=${var.SSID}",
    "WIFI_PASS=${var.WIFI_PASS}",
    "HOSTNAME=${var.HOSTNAME}",
    "DNS_OPTS=${var.DNS_OPTS}",
    "SSH=${var.SSH}",
    "NTP=${var.NTP}",
    "DISK_OPTS=${var.DISK_OPTS}",
    "PACKAGES=${var.PACKAGES}",
  ]
}

# ISO-specific variables
variable "iso_url" {
  description = "URL to the Alpine Linux ISO"
  type        = string
  default     = "https://dl-cdn.alpinelinux.org/alpine/latest-stable/releases/x86_64/alpine-standard-3.21.3-x86_64.iso"
}

variable "iso_checksum" {
  description = "Checksum for the Alpine Linux ISO"
  type        = string
  default     = "sha512:7f06d99e9c212bad281e6dd1e628f582c446d912d4711f3d8a6cbccc18834d3d0d40dd8ca9eda82bff41bde616c8b9fcc23d47a4a56dc12863c5681d69578495"
}

variable "disk_size" {
  description = "Disk size for the virtual machine"
  type        = number
  default     = 10240
}

builder "virtualbox-iso" "alpine_iso" {
  iso_url      = var.iso_url
  iso_checksum = var.iso_checksum

  vm_name          = "alpine-pimp-iso"
  shutdown_command = "echo 'powered off'"
  communicator     = "none"
  disk_size        = var.disk_size
  headless         = true

  boot_wait    = "10s"
  boot_command = [
    "<wait5><enter>"
  ]
}

# Upload the pimp script
provisioner "file" {
  source      = "scripts/extended-pimp.sh"
  destination = "/opt/extended-pimp.sh"
}

# Run script with dynamically parsed environment variables
provisioner "shell" {
  script           = "/opt/extended-pimp.sh"
  environment_vars = local.env_vars_list
}
