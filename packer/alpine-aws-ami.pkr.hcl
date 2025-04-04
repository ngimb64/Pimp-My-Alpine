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
  description = "Optional WIFI SSID"
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
  description = "Optional packages to install at end of installation"
  type        = string
  default     = ""
}

# AWS required variables section
variable "AWS_ACCOUNT_ID" {
  description = "AWS account ID"
  type        = string
  sensitive   = true
}

variable "S3_BUCKET" {
  description = "AWS S3 bucket where AMIs are stored"
  type        = string
}

variable "X509_CERT_PATH" {
  description = "Path to valid x509 certificate for AWS account"
  type        = string
}

variable "X509_KEY_PATH" {
  description = "Path to valid x509 private key for AWS account"
  type        = string
}

variable "AWS_ACCESS_KEY" {
  description = "AWS access key"
  type        = string
  sensitive   = true
}

variable "AWS_SECRET_KEY" {
  description = "AWS secret key"
  type        = string
  sensitive   = true
}

variable "AWS_REGION" {
  description = "AWS region"
  type        = string
}

variable "AWS_INSTANCE_TYPE" {
  description = "AWS instance type"
  type        = string
}

# AWS optional variables section
variable "AMI_NAME" {
  description = "AWS instance type"
  type        = string
  default     = "alpine-pimp"
}

variable "AWS_SUBNET_ID" {
  description = "AWS Subnet ID"
  type        = string
  default     = ""
}

variable "AWS_SECURITY_GROUP_ID" {
  description = "AWS Security Group ID"
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
    "PACKAGES=${var.PACKAGES}"
  ]
}

data "amazon-ami" "alpine-base" {
  filters = {
    virtualization-type = "hvm"
    name                = "*alpine-ami-3.18-x86_64*"
    root-device-type    = "instance-store"
  }
  owners      = ["951157211495"]
  most_recent = true
  region      = var.AWS_REGION
}

source "amazon-instance" "alpine-pimp-ami" {
  account_id        = var.AWS_ACCOUNT_ID
  s3_bucket         = var.S3_BUCKET
  x509_cert_path    = var.X509_CERT_PATH
  x509_key_path     = var.X509_KEY_PATH
  ami_name          = "${var.AMI_NAME}-{{timestamp}}"
  access_key        = var.AWS_ACCESS_KEY
  secret_key        = var.AWS_SECRET_KEY
  region            = var.AWS_REGION
  instance_type     = var.AWS_INSTANCE_TYPE
  source_ami        = data.amazon-ami.alpine-base.id
  subnet_id         = var.AWS_SUBNET_ID
  security_group_id = var.AWS_SECURITY_GROUP_ID
  ssh_username      = "root"
  communicator      = "ssh"
}

build {
  sources = ["source.amazon-instance.alpine-pimp-ami"]

  provisioner "file" {
    source      = "scripts/extended-pimp.sh"
    destination = "/opt/extended-pimp.sh"
  }

  provisioner "shell" {
    environment_vars = local.env_vars_list
    inline           = [
      "sh /opt/extended-pimp.sh"
    ]
  }
}
