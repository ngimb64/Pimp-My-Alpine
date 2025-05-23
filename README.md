# Pimp My Alpine

> A script suite for configuring a updated, hardened, and custom Alpine Linux system

## Table of Contents

- [Features](#Features)
- [Installation](#Installation)
- [Usage](#Usage)
- [Environment Variables](#Environment-Variables)
- [Contributing or Issues](#Contributing-or-Issues)
- [License](#License)

## Features

- Base pimp, which is intended to run after setup-alpine
	- adds community & testing repositories
	- re-updates
	- adds CPU microcode packages for AMD and Intel processors
	- sets up firewall configuration, installs and packages specified in environment variable
	- sets root password as well as admin & low privilege users and their passwords
	- locks root account
	- disable SSH root logins
	- generate keys for admin an low privilege users
	- ensure critical directories have proper permissions
	- establish auditing with rsyslog
	- disable unused file systems
	- tune kernel parameters
	- script overwrites itself with random data 100,000 times before self-deleting
<br>

- Extended pimp, automates setup-alpine using an answer file then runs the base pimp afterwards
<br>


## Installation

Overall the script has little dependencies, with the exception of using wireless connections where no wired is available which requires the Alpine Extended ISO is used to ensure that locally cached packages are available to be able to make a wireless connection. If HashiCorp Packer is used for deployment the below links are all that is needed to get everything installed:

- https://developer.hashicorp.com/packer/tutorials/docker-get-started/get-started-install-cli
	- https://chocolatey.org/install
<br>

- https://www.virtualbox.org/wiki/Downloads
<br>

- https://docs.docker.com/engine/install/
<br>


## Usage

It is highly recommended to disable command line history to prevent sensitive information exposure, below are examples where applicable with steps how re-enable command line history prior to project usage. For Windows, Command Prompt does not save command line history to disk (only retained in memory during session), making it the ideal shell to use these scripts.

Linux disable command line history:
```
rm ~/.ash_history && ln -s /dev/null ~/.ash_history
```
**Note**:  keep in mind the above command deletes the original history so make a copy if retaining it is desired

Linux enable command line history:
```
rm -f ~/.ash_history
```
<br>

Windows PowerShell disable saving command line history to log:
```
Set-PSReadlineOption -HistorySaveStyle SaveNothing
```
**Note**:  with PowerShell the command history can be re-enabled but will save all the commands executed in the session, therefore it is best to exit and open a new shell instead
<br>

Packer supports Linux and Windows systems, so below is how to set environment variables on both systems (though the examples are all Linux)

Setting environment variable in Linux:
```
export PKR_VAR_<name>=<value>
```

Setting environment variable in Windows Command Prompt:
```
set PKR_VAR_<name>=<value>
```

Setting environment variable in PowerShell:
```
$env:PKR_VAR_<name>=<value>
```
<br>


The other option is using the `-var` flag for each variable when using the build and validate commands in packer:
```
packer build -var "TEST=test1" -var "TEST=test2"
```
I find this to be the better option because I can template out the entire command with environment variables leaving commonly used values and redacting any sensitive information so it can be stored on disk for later use.
<br>


The usage depends on how the script intends on being used:

- For all scripts & templates it is critical to review their subsection in the Environment Variables section below
<br>

- `base-pimp.sh`, is intended to be executed after `setup-alpine`
	- After `setup-alpine` an internet connection should be established
	- Use wget to retrieve the script from the repository `wget https://raw.githubusercontent.com/ngimb64/Pimp-My-Alpine/refs/heads/main/scripts/base-pimp.sh`
	- Use `chmod +x <script_path>` to ensure the script is executable and run it
	- After running the script reboot and run `/etc/init.d/local start 2>/dev/null` to ensure installed boot scripts are run
<br>

- `extended-pimp.sh`, is intended to either be physically transferred via USB or using deployment tools like Packer & Vagrant
	- After running the script reboot and run `/etc/init.d/local start 2>/dev/null` to ensure installed boot scripts are run
<br>

**Note**:  to ensure the packer templates work properly, run `packer init packer.pkr.hcl` in the root folder to ensure provider plugins are installed

- Packer templates all have the same approach and all of them use the environment variables from the extended pimp script
- It is recommended to run the packer templates from the root folder of the project to prevent file path issues
	- `alpine-docker.pkr.hcl`, is intended to take the base Alpine image, customize it, and store the resulting image
		- After the process is complete, the image can be run by switching into the docker folder and running `docker-compose up -d`
	<br>

	- `alpine-ova.pkr.hcl`, is intended to take the base Alpine ISO, customize it, and store the resulting OVA image
	- Though this script seems to run fully, it currently is having issues with configurations persisting after the setup-alpine script and is not recommended until resolved
		- Before running the template, generate a private SSH key for the provisioner with `openssl genpkey -algorithm RSA -out packer/id_rsa.pem -pkeyopt rsa_keygen_bits:4096`
		- The alpine-ova template uses the URL and checksum for the standard ISO, here is how they would be set for the extended ISO instead of using the default standard
			- `export ISO_URL=https://dl-cdn.alpinelinux.org/alpine/latest-stable/releases/x86_64/alpine-extended-3.21.3-x86_64.iso`
			- `export ISO_CHECKSUM=4c72272d6fc4d67b884cf5568ebe42d7b59e186ae944873b39bf014ca46e1ce60379b560bebd7d7bc5bf250d6132ac6e91079a6b1b6a2d9ce788f34f35c87cc0`
		- After the process is complete, the resulting OVA can be easily imported into VirtualBox at the top tab `File -> Import Appliance`
<br>

- After the command line history has been disabled export the environment variables that are required and optional if desired
- Then simply build the template with `packer build <template_file>`
- After running the script and running the container or OVA, run `/etc/init.d/local start 2>/dev/null` to ensure installed boot scripts are run
<br>


## Environment Variables

### base-pimp

Environment variables required for proper execution:

- ADMIN: &nbsp; The name of the admin user to create
- ADMIN_PASS: &nbsp; The password of the admin user
- USER: &nbsp; The name of the user to create
- USER_PASS: &nbsp; The password of the low privileged user
- ROOT_PASS: &nbsp; The root password to be configured

Environment variables to export for customization (optional):

- SSH: &nbsp; The SSH service setting, if not set the default openssh is used (options: openssh, dropbear, none)
- NTP: &nbsp; The NTP service setting, if not set the default openntpd is used (options: busybox, openntd, chrony, none)
- PACKAGES: &nbsp; The list of packages to be installed after initial setup, supports multiple packages as a space separated string like `export PKR_VAR_PACKAGES="package1 package2 package3"`

### extended-pimp

Environment variables required for proper execution:

- ADMIN: &nbsp; The name of the admin user to create
- ADMIN_PASS: &nbsp; The password of the admin user
- USER: &nbsp; The name of the user to create
- USER_PASS: &nbsp; The password of the low privileged user
- ROOT_PASS: &nbsp; The root password to be configured

Environment variables to export for customization (optional):

- SSID: &nbsp; The SSID of the wireless network to connect to, WIFI_PASS must also be set
- WIFI_PASS: &nbsp; The password of the wireless network to connect to, SSID must also be set
- HOSTNAME: &nbsp; The desired hostname to be configured, if not set it will be client followed by a hyphen and six random characters
- DNS_OPTS: &nbsp; The IP address of the DNS servers to be used in space separated string like `export PKR_VAR_DNS_OPTS="1.1.1.1 1.0.0.1"` and also supports domains like `export PKR_VAR_DNS_OPTS="-d <domain> 1.1.1.1 1.0.0.1"`
- SSH: &nbsp; The SSH service setting, if not set the default openssh is used (options: openssh, dropbear, none)
- NTP: &nbsp; The NTP service setting, if not set the default crony is used (options: busybox, openntd, crony, none)
- DISK_OPTS: &nbsp; The disk options, if not set the disk type is system at /dev/sda, disk type can be changed to data like `export PKR_VAR_DISK_OPTS="-m data /dev/sda2"`
- PACKAGES: &nbsp; The list of packages to be installed after initial setup, supports multiple packages as a space separated string like `export PKR_VAR_PACKAGES="package1 package2 package3"`
<br>


### Packer Templates (includes variables from extended pimp script)

#### alpine-docker

Environment variables to export for customization (optional):

- DOCKER_BASE_IMAGE: &nbsp; The name of the base image used to build Docker container (alpine:latest default)

#### alpine-ova

Environment variables to export for customization (optional):

- ISO_URL: &nbsp; The URL to the ISO to be downloaded and used
- ISO_CHECKSUM: &nbsp; The hash checksum of the ISO to be downloaded and used
- DISK_SIZE: &nbsp; The size in MB of the disk to create for VM (10GB default)
<br>


## Contributing or Issues

[Contributing Documentation](CONTRIBUTING.md)
<br>


## License

The program is licensed under [PolyForm Noncommercial License 1.0.0](LICENSE.md)
<br>
