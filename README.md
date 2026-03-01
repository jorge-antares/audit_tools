Audit Tools
===========

Small collection of bash scripts to perform basic audits on an Ubuntu server.

Files
- checkups.sh: system security audit. Prints a report to stdout. Optional argument: path to Nginx error log.
- nginxchecks.sh: analyzes an Nginx access log and prints counts (methods, status classes, top IPs, top paths).

Usage
- Run `checkups.sh` optionally passing an Nginx error log path:

```bash
./checkups.sh [path-to-nginx-error-log]
```

- Run `nginxchecks.sh` with the access log path:

```bash
./nginxchecks.sh /var/log/nginx/access.log
```

Notes
- Scripts are read-only and designed to run on the host (may require root to read logs in /var/log).
- No configuration changes are made by these scripts.
