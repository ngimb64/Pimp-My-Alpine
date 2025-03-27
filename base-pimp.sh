#!/bin/sh

# Note: before exporting environment variables in the terminal, command line history
#       should be temporary disabled with `rm ~/.ash_history && ln -s /dev/null ~/.ash_history`.
#       When it is time to re-enable history use `rm -f ~/.ash_history`, keep in mind the
#       command deletes the original history so make a copy if retaining it is desired.

# Environment variabless required for proper execution
#   - ADMIN:  The name of the admin user to create
#   - ADMIN_PASS:  The password of the admin user
#   - USER:  The name of the user to create
#   - USER_PASS:  The password of the low privileged user
#   - ROOT_PASS:  The root password to be configured

# Enviorment variables to export for customization (optional):
#   - SSH:  The SSH service setting, if not set to none the default openssh is used
#   - NTP:  The NTP service setting, if not set to none the default openntpd is used
#   - PACKAGES:  The list of packages to be installed after initial setup,
#                supports multiple packages as a space separated string like
#                `export PACKAGES="package1 package2 package3"`

# Remove the comment from community url
sed 's/^#//g' /etc/apk/repositories > /etc/apk/sed-parse
# Move the above output file to overwrite the original
mv /etc/apk/sed-parse /etc/apk/repositories
# Add the testing repository to repositories file
printf "@testing %s%s\n" "$(tail -n 1 /etc/apk/repositories | sed -E 's|(.*?)(/[^/]+){2}$|\1/|')" edge/testing >> /etc/apk/repositories

# Update package lists
apk update
# Upgrade apk if available
apk add --upgrade apk-tools
# Upgrade any other available upgrades
apk upgrade --available

# Get the processor architecture
ARCH="$(uname -m)"
# If AMD processor is utilized, install CPU microcode
[ "$ARCH" = "x86_64" ] && apk add amd-ucode
# If Intel processor is utilized, install CPU microcode
[ "$ARCH" = "i386" ] && apk add intel-ucode

# Install ufw and needed packages
apk add ip6tables logrotate ufw
# Deny all incoming and outgoing traffic by default
ufw default deny incoming
ufw default deny outgoing
# Open SSH port and limit connection attempts if not none
[ "$SSH" != "none" ] && ufw limit SSH
# Allow outgoing NTP if not none
[ "$NTP" != "none" ] && ufw allow out 123/udp
# Configure outgoing HTTP and DNS for apk to work
ufw allow out DNS
ufw allow out 80/tcp
# Enable ufw and add to rc boot scripts
ufw enable
rc-update add ufw

# If packages is a present variable
if [ -n "$PACKAGES" ]; then
    # Iterate through space separated packages string
    for element in $PACKAGES; do
        # Install current package in string
        apk add "$element"
    done
fi

# Set the root password
printf "%s:%s" "root" "$ROOT_PASS" | chpasswd
# Set the admin user password
printf "%s:%s" "$ADMIN" "$ADMIN_PASS" | chpasswd
# Create a low privilege user on the system
adduser -D -h "/home/$USER" -s /bin/ash "$USER"
# Set the low privilege user password
printf "%s:%s" "$USER" "$USER_PASS" | chpasswd
# Lock the root account
passwd -l root

# Disable SSH root logins
sed -i 's/^#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config

# Generate RSA key for admin user
mkdir -p "/home/$ADMIN/.ssh"
ssh-keygen -t rsa -b 4096 -f "/home/$ADMIN/.ssh"
chown "$ADMIN:$ADMIN" "/home/$ADMIN/.ssh" "/home/$ADMIN/.ssh/id_rsa" "/home/$ADMIN/.ssh/id_rsa.pub"

# Generate RSA key for low privilege user
mkdir -p "/home/$USER/.ssh"
ssh-keygen -t rsa -b 4096 -f "/home/$USER/.ssh"
chown "$USER:$USER" "/home/$USER/.ssh" "/home/$USER/.ssh/id_rsa" "/home/$USER/.ssh/id_rsa.pub"

# Set appropriate permissions on critical directories
chmod 700 /root
chmod 600 /boot/grub/grub.cfg
chmod 600 /etc/ssh/sshd_config

# Add needed packages for audit logging
apk add audit rsyslog
# Ensure the proper dir exists for audit rules
mkdir -p /etc/audit/rules.d
# Add rules to audit rule file
auditRuleFile=/etc/audit/rules.d/audit.rules
{
    printf "%s\n" "-w /etc/passwd -p wa -k passwd_changes"
    printf "%s\n" "-w /etc/shadow -p wa -k shadow_changes"
    printf "%s\n" "-w /etc/group -p wa -k group_changes"
} >> "$auditRuleFile"

# Disable unused file systems
filesysDisableFile=/etc/modprobe.d/disable-filesystems.conf
{
    printf "%s\n" "install cramfs /bin/true"
    printf "%s\n" "install freevxfs /bin/true"
    printf "%s\n" "install jffs2 /bin/true"
    printf "%s\n" "install hfs /bin/true"
    printf "%s\n" "install hfsplus /bin/true"
    printf "%s\n" "install squashfs /bin/true"
    printf "%s\n" "install udf /bin/true"
    printf "%s\n" "install vfat /bin/true"
} >> "$filesysDisableFile"

# Tune kernel parameters
kernelFile=/etc/sysctl.conf
{
    printf "%s\n" "net.ipv4.ip_forward = 0"
    printf "%s\n" "net.ipv4.conf.all.accept_source_route = 0"
    printf "%s\n" "net.ipv4.conf.all.accept_redirects = 0"
    printf "%s\n" "net.ipv4.conf.all.secure_redirects = 0"
    printf "%s\n" "net.ipv4.conf.all.log_martians = 1"
    printf "%s\n" "net.ipv4.conf.default.log_martians = 1"
    printf "%s\n" "net.ipv4.icmp_echo_ignore_broadcasts = 1"
    printf "%s\n" "net.ipv4.icmp_ignore_bogus_error_responses = 1"
    printf "%s\n" "net.ipv4.tcp_syncookies = 1"
    printf "%s\n" "net.ipv4.conf.all.send_redirects = 0"
    printf "%s\n" "net.ipv4.conf.default.send_redirects = 0"
} >> $kernelFile

# Overwwrite executed script with random data 100,000 times and delete
shred -zu -n 100000 "$(readlink -f "$0")"
# Reboot the system again to ensure kernel related config are in effect
reboot
