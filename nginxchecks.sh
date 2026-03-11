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

echo "==== Nginx Access Log Report ===="
echo "File: $NGINX_ACCESS_LOG_PATH"
echo "Generated: $(date -Is)"
echo

TOTAL_REQUESTS="$(wc -l < "$NGINX_ACCESS_LOG_PATH" | tr -d ' ')"
echo "Total requests: $TOTAL_REQUESTS"
echo

echo "== Request methods =="
awk '{print $6}' "$NGINX_ACCESS_LOG_PATH" \
  | tr -d '"' \
  | grep -E '^[A-Z]+$' \
  | sort | uniq -c | sort -nr
echo

echo "== Status code classes (2xx/3xx/4xx/5xx) =="
awk '{
  code=$9
  if (code ~ /^[0-9]{3}$/) {
    class=substr(code,1,1)"xx"
    counts[class]++
  }
}
END {
  printf "2xx: %d\n", counts["2xx"]+0
  printf "3xx: %d\n", counts["3xx"]+0
  printf "4xx: %d\n", counts["4xx"]+0
  printf "5xx: %d\n", counts["5xx"]+0
}' "$NGINX_ACCESS_LOG_PATH"
echo

echo "== Top status codes =="
awk '$9 ~ /^[0-9]{3}$/ {print $9}' "$NGINX_ACCESS_LOG_PATH" \
  | sort | uniq -c | sort -nr
echo

echo "== Top 10 client IPs =="
awk '{print $1}' "$NGINX_ACCESS_LOG_PATH" \
  | sort | uniq -c | sort -nr | head -n 10
echo

echo "== Top 10 requested paths =="
awk '{print $7}' "$NGINX_ACCESS_LOG_PATH" \
  | sort | uniq -c | sort -nr | head -n 10
echo

echo "==== End of report ===="