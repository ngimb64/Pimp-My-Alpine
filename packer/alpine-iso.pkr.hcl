# Required and Optional Environment Variables
variable "required_vars" {
  description = "List of required environment variables for VirtualBox ISO build"
  type        = list(string)
  default     = [
    "ADMIN",
    "ADMIN_PASS",
    "USER",
    "USER_PASS",
    "ROOT_PASS"
  ]
}

variable "optional_vars" {
  description = "List of optional environment variables for VirtualBox ISO build"
  type        = list(string)
  default     = [
    "SSID",
    "WIFI_PASS",
    "HOSTNAME",
    "DNS_OPTS",
    "SSH",
    "NTP",
    "DISK_OPTS",
    "PACKAGES"
  ]
}

locals {
  # Create a list of assignments in the format VAR=value
  env_vars_list = concat(
    [for var_name in var.required_vars : "${var_name}=${env(var_name)}"],
    [for var_name in var.optional_vars : "${var_name}=${env(var_name)}" if env(var_name) != ""]
  )
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
  destination = "/tmp"
}

# Run script with dynamically parsed environment variables
provisioner "shell" {
  script           = "/tmp/extended-pimp.sh"
  environment_vars = local.env_vars_list
}
