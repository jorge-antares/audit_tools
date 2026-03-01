#!/usr/bin/env bash
set -euo pipefail

ACCESS_LOG_PATH="${1:-}"

if [[ -z "$ACCESS_LOG_PATH" ]]; then
  echo "Usage: $0 <path-to-nginx-access-log>"
  exit 1
fi

if [[ ! -f "$ACCESS_LOG_PATH" ]]; then
  echo "Error: File not found: $ACCESS_LOG_PATH"
  exit 1
fi

echo "==== Nginx Access Log Report ===="
echo "File: $ACCESS_LOG_PATH"
echo "Generated: $(date -Is)"
echo

TOTAL_REQUESTS="$(wc -l < "$ACCESS_LOG_PATH" | tr -d ' ')"
echo "Total requests: $TOTAL_REQUESTS"
echo

echo "== Request methods =="
awk '{print $6}' "$ACCESS_LOG_PATH" \
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
}' "$ACCESS_LOG_PATH"
echo

echo "== Top status codes =="
awk '$9 ~ /^[0-9]{3}$/ {print $9}' "$ACCESS_LOG_PATH" \
  | sort | uniq -c | sort -nr
echo

echo "== Top 10 client IPs =="
awk '{print $1}' "$ACCESS_LOG_PATH" \
  | sort | uniq -c | sort -nr | head -n 10
echo

echo "== Top 10 requested paths =="
awk '{print $7}' "$ACCESS_LOG_PATH" \
  | sort | uniq -c | sort -nr | head -n 10
echo

echo "==== End of report ===="