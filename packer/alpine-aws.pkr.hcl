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

# AWS variables section
variable "AWS_ACCESS_KEY" {
    description = "AWS Access Key"
    type        = string
    sensitive   = true
}

variable "AWS_SECRET_KEY" {
    description = "AWS Secret Key"
    type        = string
    sensitive   = true
}

variable "AWS_REGION" {
    description = "AWS Region"
    type        = string
}

variable "AWS_INSTANCE_TYPE" {
    description = "AWS Instance Type"
    type        = string
}

variable "AWS_SUBNET_ID" {
    description = "AWS Subnet ID"
    type        = string
    default     = null
}

variable "AWS_SECURITY_GROUP_ID" {
    description = "AWS Security Group ID"
    type        = string
    default     = null
}

variable "AMI_NAME" {
    description = "AWS Instance Type"
    type        = string
    default     = "alpine-pimp"
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

builder "amazon-instance" {
  access_key        = var.AWS_ACCESS_KEY
  secret_key        = var.AWS_SECRET_KEY
  region            = var.AWS_REGION
  instance_type     = var.AWS_INSTANCE_TYPE
  subnet_id         = lookup(var, "AWS_SUBNET_ID", null)
  security_group_id = lookup(var, "AWS_SECURITY_GROUP_ID", null)
  ami_name          = "alpine-image-${timestamp()}"
  ssh_username      = "root"

  source_ami_filter {
    filters = {
      virtualization-type = "hvm"
      name                = "*alpine-ami-3.18-x86_64*"
      root-device-type    = "instance-store"
    }
    owners      = ["951157211495"]
    most_recent = true
  }

  tags {
    Name = "${var.AMI_NAME}-AMI-Latest"
  }
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
