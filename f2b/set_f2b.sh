#!/bin/bash
# 
#
# WARNING:
# Since this script modifies system files using root privileges, review its files before running.
# It copies jail.local and filter files to /etc/fail2ban, updates logsdir in jail.local, and creates new iptables action files for Docker compatibility.
#
# f2b should be owned by root:
# chown root:root -R f2b
# chmod 644 -R f2b

LOG_DIR=$1

if [ -z "$LOG_DIR" ]; then
  echo "Usage: $0 <absolute_path_to_log_directory>. Example: $0 /home/user/nginx/log"
  exit 1
fi

if [[ ! "$LOG_DIR" =~ ^/ ]]; then
  echo "Error: LOG_DIR must be an absolute path."
  exit 1
fi

# 1) COPY FILES
cp -v ./jail.local /etc/fail2ban/jail.local
cp -v ./filter.d/*.conf /etc/fail2ban/filter.d/
echo "STEP 1 COMPLETED: Copied jail.local and filter.d/*.conf to /etc/fail2ban/"

# 2) UPDATE LOGSDIR IN JAIL.LOCAL
sed -i "s|logsdir[[:space:]]*=[[:space:]]*.*|logsdir = $LOG_DIR|g" /etc/fail2ban/jail.local
echo "STEP 2 COMPLETED: Updated logsdir in /etc/fail2ban/jail.local to $LOG_DIR"

# 3) COPY CONF FILES
cp -v /etc/fail2ban/action.d/iptables.conf /etc/fail2ban/action.d/iptables-forward.conf
cp -v /etc/fail2ban/action.d/iptables-allports.conf /etc/fail2ban/action.d/iptables-allports-forward.conf
cp -v /etc/fail2ban/action.d/iptables-multiport.conf /etc/fail2ban/action.d/iptables-multiport-forward.conf
echo "STEP 3 COMPLETED: Copied and renamed iptables action files in /etc/fail2ban/action.d/"

# 4) REPLACE NAMES IN ACTION FILES
sed -i 's/chain[[:space:]]*=[[:space:]]*INPUT/chain=DOCKER-USER/g' /etc/fail2ban/action.d/iptables-forward.conf
sed -i 's/iptables.conf/iptables-forward.conf/g' /etc/fail2ban/action.d/iptables-multiport-forward.conf
sed -i 's/iptables.conf/iptables-forward.conf/g' /etc/fail2ban/action.d/iptables-allports-forward.conf
echo "STEP 4 COMPLETED: Updated chain name and action file references in the new iptables action files"

# 5) ASK IF RESTART FAIL2BAN
read -p "Do you want to restart fail2ban now? (y/n) " RESTART
if [[ "$RESTART" =~ ^[Yy]$ ]]; then
  systemctl restart fail2ban
  echo "STEP 5 COMPLETED: Restarted fail2ban service"
else
  echo "STEP 5 SKIPPED: Fail2ban service not restarted"
fi