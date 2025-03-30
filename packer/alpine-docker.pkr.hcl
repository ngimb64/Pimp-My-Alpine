variable "required_vars" {
  description = "List of required environment variables for the Docker build"
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
  description = "List of optional environment variables for the Docker build"
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
  # Convert required & optional variables into environment variable assignment format
  env_vars_list = concat(
    [for var_name in var.required_vars : "${var_name}=${env(var_name)}"],
    [for var_name in var.optional_vars : "${var_name}=${env(var_name)}" if env(var_name) != ""]
  )
}

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

  # Upload the pimp script
  provisioner "file" {
    source      = "scripts/extended-pimp.sh"
    destination = "/tmp"
  }

  # Run script with dynamically parsed environment variables
  provisioner "shell" {
    environment_vars = local.env_vars_list
    inline = [
      "sh /tmp/extended-pimp.sh"
    ]
  }

  # Tag the image as latest
  post-processor "docker-tag" {
    repository = "alpine-pimp"
    tag        = "latest"
  }
}
