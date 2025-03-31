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

Overall the script has little dependencies, with the exception of using wireless connections where no wired is available which requires the Alpine Extended ISO is used to ensure that locally cached packages are available to be able to make a wireless connection. If HashiCorp Packer or Vagrant are used for deployment the below links are all that is needed to get everything installed:

- https://developer.hashicorp.com/packer/tutorials/docker-get-started/get-started-install-cli
	- https://chocolatey.org/install
<br>

- https://developer.hashicorp.com/vagrant/install
<br>


## Usage

It is highly recommended to disable command line history to prevent sensitive information exposure, below are examples where applicable with steps how re-enable command line history prior to project usage.

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

Packer and Vagrant support Linux and Windows systems, so below is how to set environment variables on both systems (though the examples are all Linux)

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
<br>


The usage depends on how the script intends on being used:

- For all use cases except deployment related (Packer, Vagrant, etc.), the environment variables (especially required) need to be set, refer to Environment Variables section below
	- Example:  `export ROOT_PASS=<password>`
<br>

- base-pimp.sh, is intended to be executed after `setup-alpine`
	- After `setup-alpine` an internet connection should be established
	- Use wget to retrieve the script from the repository `<ADD COMMAND>`
	- Use `chmod +x <script_path>` to ensure the script is executable and run it
<br>

- extended-pimp.sh, is intended to either be physically transferred via USB or using deployment tools like Packer & Vagrant
	- When using Packer & Vagrant, the environment variables need to be established in the Packer file to allow the provisoner to access them during execution instead of exporting them in shell
		- Packer templates all have the same approach and all of them use the environment variables from the extended pimp script
		- The only exception is the alpine-aws template, whose additional environment variables can be found below
		- It is recommended to run the packer templates from the root folder of the project to prevent file path issues
	<br>

	- For Packer templates alpine-iso and alpine-vagrant ensure the DISK_SIZE environment variable is set if a size other than 10240 default is desired
		- Both these templates use the url and checksum for the standard ISO but are customizable variables like DISK_SIZE, here is how they would be set for the extended ISO instead of using the default standard
			- `export ISO_URL=https://dl-cdn.alpinelinux.org/alpine/latest-stable/releases/x86_64/alpine-extended-3.21.3-x86_64.iso`
			- `export ISO_CHECKSUM=4c72272d6fc4d67b884cf5568ebe42d7b59e186ae944873b39bf014ca46e1ce60379b560bebd7d7bc5bf250d6132ac6e91079a6b1b6a2d9ce788f34f35c87cc0`

**Note**:  to ensure the packer templates work properly, run `packer init packer.pkr.hcl` in the root folder to ensure provider plugins are installed

- After the command line history has been disabled export the environment variables that are required and optional if desired
- Then simply build the template with `packer build <template_file>`
	- For Vagrant box generation, the resulting box can be added with `vagrant box add <.box_file> --name <box_name>`
<br>


## Environment Variables

### base-pimp

Environment variables required for proper execution:

- ADMIN:  The name of the admin user to create
- ADMIN_PASS:  The password of the admin user
- USER:  The name of the user to create
- USER_PASS:  The password of the low privileged user
- ROOT_PASS:  The root password to be configured

Environment variables to export for customization (optional):

- SSH:  The SSH service setting, if not set to none the default openssh is used
- NTP:  The NTP service setting, if not set to none the default openntpd is used
- PACKAGES:  The list of packages to be installed after initial setup,
			 supports multiple packages as a space separated string like
			 `export PACKAGES="package1 package2 package3"`


### extended-pimp

Environment variables required for proper execution:

- ADMIN:  The name of the admin user to create
- ADMIN_PASS:  The password of the admin user
- USER:  The name of the user to create
- USER_PASS:  The password of the low privileged user
- ROOT_PASS:  The root password to be configured

Environment variables to export for customization (optional):

- SSID:  The SSID of the wireless network to connect to, WIFI_PASS must also be set
- WIFI_PASS:  The password of the wireless network to connect to, SSID must also be set
- HOSTNAME:  The desired hostname to be configured, if not set it will be client followed by a hyphen and six random characters
- DNS_OPTS:  The IP address of the DNS servers to be used in space separated string like `export DNS_OPTS="1.1.1.1 1.0.0.1"` and also supports domains like `export DNS_OPTS="-d <domain> 1.1.1.1 1.0.0.1"`
- SSH:  The SSH service setting, if not set to none the default openssh is used
- NTP:  The NTP service setting, if not set to none the default openntpd is used
- DISK_OPTS:  The disk options, if not set the disk type is system at /dev/sda, disk type can be changed to data like `export DISK_OPTS="-m data /dev/sda2"`
- PACKAGES:  The list of packages to be installed after initial setup, supports multiple packages as a space separated string like `export PACKAGES="package1 package2 package3"`
<br>


### Packer Templates (includes variables from extended pimp script)

#### alpine-aws

Environment variables required for proper execution:

- AWS_ACCESS_KEY:  The AWS API access key
- AWS_SECRET_KEY:  The AWS API secret key
- AWS_REGION:  The AWS region where EC2 will be provisioned
- AWS_INSTANCE_TYPE:  The type of EC2 instance to be utilized
- AMI_NAME:  The name of the Amazon Machine Image to build

Environment variables to export for customization (optional):

- AWS_SUBNET_ID:
- AWS_SECURITY_GROUP_ID:
<br>


## Contributing or Issues

[Contributing Documentation](CONTRIBUTING.md)
<br>


## License

The program is licensed under [PolyForm Noncommercial License 1.0.0](LICENSE.md)
<br>
