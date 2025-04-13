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
  default     = "crony"
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

# ISO-specific variables
variable "ISO_URL" {
  description = "URL to the Alpine Linux ISO"
  type        = string
  default     = "https://dl-cdn.alpinelinux.org/alpine/latest-stable/releases/x86_64/alpine-standard-3.21.3-x86_64.iso"
}

variable "ISO_CHECKSUM" {
  description = "Checksum for the Alpine Linux ISO"
  type        = string
  default     = "sha512:7f06d99e9c212bad281e6dd1e628f582c446d912d4711f3d8a6cbccc18834d3d0d40dd8ca9eda82bff41bde616c8b9fcc23d47a4a56dc12863c5681d69578495"
}

variable "DISK_SIZE" {
  description = "Disk size for the virtual machine (10GB default)"
  type        = number
  default     = 10240
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
    "PACKAGES=${var.PACKAGES}"
  ]
}

source "virtualbox-iso" "alpine-pimp-ova" {
  guest_os_type    = "Linux26_64"
  iso_url          = var.ISO_URL
  iso_checksum     = var.ISO_CHECKSUM
  ssh_username     = "root"
  shutdown_command = "poweroff"
  vm_name          = "alpine-pimp-ova"
  disk_size        = var.DISK_SIZE
  headless         = true
  format           = "ova"

  boot_wait    = "15s"
  boot_command = [
    "root<enter>",
    "ip link set eth0 up<enter>",
    "udhcpc -i eth0<enter>",
    "apk add openssh<enter>",
    "mkdir -p /root/.ssh && chmod 700 /root/.ssh<enter>",
    "printf '%s\\n' '{{ .SSHPublicKey }}' > /root/.ssh/authorized_keys<enter>",
    "chmod 600 /root/.ssh/authorized_keys<enter>",
    "sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config<enter>",
    "printf '%s\\n' 'PasswordAuthentication no' >> /etc/ssh/sshd_config<enter>",
    "rc-update add sshd<enter>",
    "rc-service sshd restart<enter>"
  ]
}

build {
  sources = ["sources.virtualbox-iso.alpine-pimp-ova"]

  provisioner "shell" {
    environment_vars = local.env_vars_list
    script           = "scripts/extended-pimp.sh"
  }
}
