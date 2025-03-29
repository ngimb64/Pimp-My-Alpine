# Required and Optional Environment Variables
variable "required_vars" {
  description = "List of required environment variables"
  type        = list(string)
  default     = ["AWS_ACCESS_KEY", "AWS_SECRET_KEY", "AWS_REGION", "AWS_INSTANCE_TYPE",
                 "AMI_NAME", "ADMIN", "ADMIN_PASS", "USER", "USER_PASS", "ROOT_PASS"]
}

variable "optional_vars" {
  description = "List of optional environment variables"
  type        = list(string)
  default     = ["SSID", "WIFI_PASS", "HOSTNAME", "DNS_OPTS", "SSH", "NTP", "DISK_OPTS",
                 "PACKAGES", "AWS_SUBNET_ID", "AWS_SECURITY_GROUP_ID",]
}

locals {
  # Convert required & optional variables into environment variable assignment format
  env_vars_list = concat(
    [for var_name in var.required_vars : "${var_name}=${env(var_name)}"],
    [for var_name in var.optional_vars : "${var_name}=${env(var_name)}" if env(var_name) != ""]
  )
}

builder "amazon-instance" {
  access_key        = env("AWS_ACCESS_KEY")
  secret_key        = env("AWS_SECRET_KEY")
  region            = env("AWS_REGION")
  instance_type     = env("AWS_INSTANCE_TYPE")
  subnet_id         = env("AWS_SUBNET_ID")
  security_group_id = env("AWS_SECURITY_GROUP_ID")
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
    Name = "${env("AMI_NAME")}-AMI-Latest"
  }
}

# Upload the setup script
provisioner "file" {
  source      = "scripts/extended-pimp.sh"
  destination = "/tmp"
}

# Run script with dynamically parsed environment variables
provisioner "shell" {
  script           = "/tmp/extended-pimp.sh"
  environment_vars = local.env_vars_list
}
