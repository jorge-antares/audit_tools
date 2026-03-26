#!/bin/bash
set -euo pipefail

# Usage: vm_init.sh <trusted-ssh-ip>
# Hardens iptables on an OCI Ubuntu 24.04 web server.
# Must be run as root. Existing rules are flushed and replaced.

if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <trusted-ssh-ip>" >&2
    exit 1
fi

TRUSTED_IP="$1"

# Validate the IP address format
if ! [[ "$TRUSTED_IP" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}(/[0-9]{1,2})?$ ]]; then
    echo "Error: '$TRUSTED_IP' is not a valid IPv4 address or CIDR range." >&2
    exit 1
fi

# Flush existing rules and delete custom chains
iptables -F
iptables -X

# Allow loopback interface
iptables -A INPUT -i lo -j ACCEPT

# Allow established and related sessions (stateful tracking)
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# Drop invalid packets
iptables -A INPUT -m conntrack --ctstate INVALID -j DROP

# OCI: allow DHCP responses (required for dynamic IP assignment on OCI)
iptables -A INPUT -p udp --sport 67 --dport 68 -j ACCEPT

# OCI: allow link-local range (instance metadata service at 169.254.169.254,
#      used by oracle-cloud-agent for monitoring and instance configuration)
iptables -A INPUT -s 169.254.0.0/16 -j ACCEPT

# Allow ICMP echo-request (ping), rate-limited to mitigate flood attempts
iptables -A INPUT -p icmp --icmp-type echo-request -m limit --limit 1/s --limit-burst 5 -j ACCEPT

# SSH: allow only from trusted IP, block all others
iptables -A INPUT -p tcp --dport 22 -s "$TRUSTED_IP" -j ACCEPT
iptables -A INPUT -p tcp --dport 22 -j DROP

# HTTP and HTTPS
iptables -A INPUT -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -p tcp --dport 443 -j ACCEPT

# Drop malformed TCP packets (commonly used in port scans and exploits)
iptables -A INPUT -p tcp --tcp-flags ALL NONE -j DROP        # Null packet
iptables -A INPUT -p tcp --tcp-flags ALL ALL -j DROP         # XMAS packet
iptables -A INPUT -p tcp --tcp-flags SYN,FIN SYN,FIN -j DROP
iptables -A INPUT -p tcp --tcp-flags SYN,RST SYN,RST -j DROP

# Set default policies last (after all ACCEPT rules) to avoid lockout on error
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

# Persist rules across reboots
if command -v netfilter-persistent &>/dev/null; then
    netfilter-persistent save
elif command -v iptables-save &>/dev/null; then
    iptables-save > /etc/iptables/rules.v4
fi
