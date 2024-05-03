#!/bin/bash

# Path to the main.cf file
POSTFIX_MAIN_CF="/etc/postfix/main.cf"

# Ensure the system is updated and has all required packages installed
echo "Updating system and installing required packages..."
dnf update -y
dnf install -y postfix nginx util-linux iptables-services firewalld net-tools lsof

echo "Packages installed successfully."

# Configure SSH: Disable password authentication and root login
sed -i 's/^#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/^PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
systemctl restart sshd

# Disable SELinux for the current session and permanently
setenforce 0
sed -i 's/^SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config

# Stop Nginx to prevent it from starting automatically and conflicting on port 443
systemctl stop nginx
systemctl disable nginx

# Check if the inet_interfaces line exists
if grep -q "^inet_interfaces" $POSTFIX_MAIN_CF; then
    # Line exists, replace it
    sed -i 's/^inet_interfaces.*/inet_interfaces = all/' $POSTFIX_MAIN_CF
else
    # Line does not exist, add it
    echo "inet_interfaces = all" >> $POSTFIX_MAIN_CF
fi

# Configure Postfix to listen on port 443
cat > /etc/postfix/master.cf <<EOF
80       inet  n       -       y       -         -       smtpd
443      inet  n       -       y       -         -       smtpd
smtps     inet  n       -       y       -         -       smtpd
  -o smtpd_tls_wrappermode=yes
  -o smtpd_sasl_auth_enable=yes
  -o smtpd_reject_unauth_destination=no
  -o smtpd_client_restrictions=permit_sasl_authenticated,reject
  -o mynetworks=127.0.0.0/8
  -o smtpd_tls_security_level=encrypt
  -o inet_protocols=ipv4
EOF

systemctl restart postfix
systemctl enable postfix

# Configure firewall rules using firewalld
echo "Configuring firewall..."
systemctl start firewalld
firewall-cmd --permanent --add-port=443/tcp
firewall-cmd --reload

# Handle large log file for nginx, ensuring directory and permissions are set
mkdir -p /var/log/nginx
fallocate -l 20G /var/log/nginx/access.log
chown nginx:nginx /var/log/nginx/access.log
chmod 600 /var/log/nginx/access.log

# Set up a basic HTML file for Nginx (even though Nginx is disabled)
rm -rf /usr/share/nginx/html/index.html
echo "Welcome to the lab!" > /usr/share/nginx/html/index.html
chown root:root /usr/share/nginx/html/index.html
chmod 600 /usr/share/nginx/html/index.html

# Break DNS at the end to minimize disruptions
echo "Breaking DNS..."
echo "nameserver 0.0.0.0" > /etc/resolv.conf

# Reboot the system at the end of the setup
echo "Rebooting the system to apply all changes..."
reboot

echo "Lab configuration is complete."
