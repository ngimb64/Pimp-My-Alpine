#!/bin/sh

# Environment variabless required for proper execution:
#   - ADMIN:  The name of the admin user to create
#   - ADMIN_PASS:  The password of the admin user
#   - USER:  The name of the user to create
#   - USER_PASS:  The password of the low privileged user
#   - ROOT_PASS:  The root password to be configured

# Enviorment variables to export for customization (optional):
#   - SSID:  The SSID of the wireless network to connect to, WIFI_PASS must also be set
#   - WIFI_PASS:  The password of the wireless network to connect to, SSID must also be set
#   - HOSTNAME:  The desired hostname to be configured, if not set it will be client
#                followed by a hyphen and six random characters
#   - DNS_OPTS:  The IP address of the DNS servers to be used in space separated string
#                like `export DNS_OPTS="1.1.1.1 1.0.0.1" and also supports domains like
#                `export DNS_OPTS="-d <domain> 1.1.1.1 1.0.0.1"
#   - SSH:  The SSH service setting, if not set to none the default openssh is used
#   - NTP:  The NTP service setting, if not set to none the default openntpd is used
#   - DISK_OPTS:  The disk options, if not set the disk type is system at /dev/sda, disk
#                 type can be changed to data like `export DISK_OPTS="-m data /dev/sda2"`
#   - PACKAGES:  The list of packages to be installed after initial setup,
#                supports multiple packages as a space separated string like
#                `export PACKAGES="package1 package2 package3"`


# Function for handling file creation errors with touch command
file_err() {
    echo "[*] Error: Cannot create file $1" >&2
}


# Function to generate random string of passed in length
generate_random_string() {
    length="$1"
    tr -dc 'A-Za-z0-9' < /dev/urandom | head -c "$length"
    echo
}


# Function to setup a persistent wireless connection
wifi_setup() {
    # Install needed packages from local cache
    apk add iw linux-firmware wireless-tools wpa_supplicant
    # Set wlan interface to active
    ip link set wlan0 up
    # Assign SSID and password in config file
    wpa_passphrase "$SSID" "$WIFI_PASS" > /etc/wpa_supplicant/wpa_supplicant.conf
    # Start the service daemon in the background
    wpa_supplicant -B -i wlan0 -c /etc/wpa_supplicant/wpa_supplicant.conf
    # Configure wireless interface with IP address
    udhcp -i wlan0
    # Add wireless interface to /etc/network/interfaces
    printf "%s\n%s\n%s\n" "auto lo" "auto wlan0" "iface wlan0 inet dhcp" >> /etc/network/interfaces
    # Manually restart (or start) networking
    rc-service networking --quiet restart &
    #ensure that networking is set to start on boot
    rc-update add networking boot
    # configure wpa_supplicant to start on boot
    rc-update add wpa_supplicant boot
}


# Function for handling errors when validating environment variables
missing_var_err() {
    # Print error and exit
    echo "[*] Error: $1 enviroment variable must be set with export command prior to execution" >&2
    exit 1
}


# Disable command history
rm -f ~/.ash_history && ln -s /dev/null ~/.ash_history

# If the admin variable is not present
[ -z "$ADMIN" ] && missing_var_err "ADMIN"
# If the admin password variable is not present
[ -z "$ADMIN_PASS" ] && missing_var_err "ADMIN_PASS"
# If the user variable is not present
[ -z "$USER" ] && missing_var_err "USER"
# If the user pass variable is not present
[ -z "$USER_PASS" ] && missing_var_err "USER_PASS"
# If the root password variable is not present
[ -z "$ROOT_PASS" ] && missing_var_err "ROOT_PASS"
# If WiFi SSID and password are present variables
[ -n "$SSID" ] && [ -n "$WIFI_PASS" ] && wifi_setup
# If the hostname variable is not present
[ -z "$HOSTNAME" ] && HOSTNAME="client-$(generate_random_string 6)"
# If the DNS servers variable is not present, set to CloudFlare default
[ -z "$DNS_OPTS" ] && DNS_OPTS="1.1.1.1 1.0.0.1"
# If the SSH service is not none or dropbear, set it to openssh default
[ "$SSH" != "none" ] && [ "$SSH" != "dropbear" ] && SSH="openssh"
# If the NTP service is not equal to none or busybox or openntpd, set it to crony default
[ "$NTP" != "none" ] && [ "$NTP" != "busybox" ] && [ "$NTP" != "openntpd" ] && NTP="crony"
# If the disk options variable is not present
[ -z "$DISK_OPTS" ] && DISK_OPTS="-m sys /dev/sda"

# Set the answer file name
answerFile="/tmp/answers.cfg"
# Create the answer file for setup-alpine script
touch "$answerFile" || file_err "$answerFile"
cat > "$answerFile" <<-__EOF__
# Use US layout with US variant
KEYMAPOPTS="us us"

# Set hostname
HOSTNAMEOPTS=$HOSTNAME

# Set device manager to mdev
DEVDOPTS=mdev

# Contents of /etc/network/interfaces
INTERFACESOPTS="auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp
hostname $HOSTNAME-$(generate_random_string 6)
"

# Set CloudFlare as DNS servers
DNSOPTS="$DNS_OPTS"

# Set timezone to UTC
TIMEZONEOPTS="UTC"

# set http/ftp proxy
PROXYOPTS=none

# Add first mirror (CDN)
APKREPOSOPTS="-1"

# Create admin user
USEROPTS="-a -u -g audio,input,video,netdev $ADMIN"

# Install Openssh
SSHDOPTS=$SSH

# Use openntpd
NTPOPTS="$NTP"

# Use /dev/sda as a sys disk
DISKOPTS="$DISK_OPTS"

# Disable dedicated backup storage
LBUOPTS=none

# Use default apk cache location
APKCACHEOPTS=none
__EOF__

# Ensure the setup scripts are installed
apk add --no-cache alpine-conf
# Set up alpine linux with the above configuration
yes | setup-alpine -e -f "$answerFile"

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

# Install necessary packages
apk add --no-cache doas iptables ip6tables logrotate rsyslog sudo

# If packages is a present variable
if [ -n "$PACKAGES" ]; then
    # Iterate through space separated packages string
    for element in $PACKAGES; do
        # Install current package in string
        apk add "$element"
    done
fi

# Set appropriate permissions on critical directories
[ -f /root ] && chmod 700 /root
[ -f /boot/grub/grub.cfg ] && chmod 600 /boot/grub/grub.cfg
[ -f /etc/ssh/sshd_config ] && chmod 600 /etc/ssh/sshd_config

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

# Set the root password
printf "%s:%s" "root" "$ROOT_PASS" | chpasswd
# Set the admin user password
printf "%s:%s" "$ADMIN" "$ADMIN_PASS" | chpasswd
# Create a low privilege user on the system
adduser -D -h "/home/$USER" -s /bin/ash "$USER"
# Set the low privilege user password
printf "%s:%s" "$USER" "$USER_PASS" | chpasswd

# Generate RSA key for low privilege user
mkdir -p "/home/$USER/.ssh"
yes "" | ssh-keygen -q -t rsa -b 4096 -f "/home/$USER/.ssh/id_rsa" -N ""
chown "$USER:$USER" "/home/$USER/.ssh" "/home/$USER/.ssh/id_rsa" "/home/$USER/.ssh/id_rsa.pub"

# Set local boot script path
bootScript="/etc/local.d/post-setup.start"
# Create local boot script to remove root SSH capabilites
cat > "$bootScript" <<-__EOF__
#!/bin/sh

# Flush existing rules
iptables -F
iptables -X
# Allow established and related connections before applying default drop policies
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
# Set default policies
iptables -P INPUT DROP
iptables -P OUTPUT DROP
iptables -P FORWARD DROP
# Allow incoming SSH and apply rate limiting if SSH is enabled
if [ "$SSH" != "none" ]; then
    iptables -A INPUT -p tcp --dport 22 -m state --state NEW -m limit --limit 3/min --limit-burst 5 -j ACCEPT
    iptables -A INPUT -p tcp --dport 22 -m state --state NEW -j DROP
fi
# Allow outgoing NTP if enabled
[ "$NTP" != "none" ] && iptables -A OUTPUT -p udp --dport 123 -j ACCEPT
# Allow outgoing DNS
iptables -A OUTPUT -p udp --dport 53 -j ACCEPT
iptables -A OUTPUT -p tcp --dport 53 -j ACCEPT
# Allow outgoing HTTP (for apk to work)
iptables -A OUTPUT -p tcp --dport 80 -j ACCEPT
# Set iptables to start on reboot
rc-update add iptables
# Write the firewall rules to disk
rc-service iptables save

# Lock the root account
passwd -l root
# Disable SSH root logins
sed -i 's/^#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config
# Have script delete itself after first run
rm -f "\$(readlink -f "\$0")"
__EOF__

# Set the boot script permissions to executable
chmod +x "$bootScript"
# Ensure the local script serivce is enabled
rc-update add local default
# Overwrite caller script with random data 100,000 times then delete
shred -zu -n 100000 "$(readlink -f "$0")"
