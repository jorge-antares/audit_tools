#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: $0 [-a|--accesslog <path>] [-e|--errorlog <path>]"
}

NGINX_ERROR_LOG_PATH=""
NGINX_ACCESS_LOG_PATH=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    -a|--accesslog)
      if [[ $# -lt 2 ]]; then
        echo "Missing value for $1" >&2
        usage >&2
        exit 1
      fi
      NGINX_ACCESS_LOG_PATH="$2"
      shift 2
      ;;
    -e|--errorlog)
      if [[ $# -lt 2 ]]; then
        echo "Missing value for $1" >&2
        usage >&2
        exit 1
      fi
      NGINX_ERROR_LOG_PATH="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

echo "==== Security Audit Report ===="
echo "Host: $(hostname -f 2>/dev/null || hostname)"
echo "Date: $(date -Is)"
echo

echo "==[ 1) SSH logins (recent) ]=="
last -ai | head -n 20 || true
echo
echo "-- Failed SSH attempts (last 200 auth lines) --"
grep -Ei "Failed password|Invalid user|authentication failure" /var/log/auth.log 2>/dev/null | tail -n 200 || true
echo

echo "==[ 2) Network connections ]=="
echo "-- Listening sockets --"
ss -tulpen || true
echo
echo "-- Established TCP connections --"
ss -tpn state established || true
echo

echo "==[ 3) Nginx logs ]=="
echo "-- Recent nginx errors --"
if [[ -z "$NGINX_ERROR_LOG_PATH" ]]; then
  echo "No Nginx error log provided"
else
  tail -n 100 "$NGINX_ERROR_LOG_PATH" 2>/dev/null || echo "No nginx error log found at: $NGINX_ERROR_LOG_PATH"
fi
echo
echo "-- Top suspicious status codes in access.log (401/403/404/5xx) --"
if [[ -z "$NGINX_ACCESS_LOG_PATH" ]]; then
  echo "No Nginx access log provided"
else
  awk '$9 ~ /^(401|403|404|5[0-9][0-9])$/ {print $9}' "$NGINX_ACCESS_LOG_PATH" 2>/dev/null \
    | sort | uniq -c | sort -nr || echo "No nginx access log found at: $NGINX_ACCESS_LOG_PATH"
fi
echo

echo "==[ 4) Hardening quick checks ]=="
echo "-- SSH config (PermitRootLogin / PasswordAuthentication) --"
grep -E "^(PermitRootLogin|PasswordAuthentication)" /etc/ssh/sshd_config 2>/dev/null || true
echo
echo "-- Users with sudo group --"
getent group sudo | cut -d: -f4 || true
echo
echo "-- Pending security updates --"
apt-get -s upgrade 2>/dev/null | grep -i security || echo "No explicit security upgrades shown."
echo

echo "==== End of report ===="