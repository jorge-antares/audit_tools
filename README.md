Audit Tools
===========

Small collection of bash scripts to perform basic audits on an Ubuntu server.

Files
- checkups.sh: system security audit. Prints a report to stdout. Optional flags: Nginx access and error log paths.
- nginxchecks.sh: analyzes an Nginx access log and prints counts (methods, status classes, top IPs, top paths).
- vm_init.sh: configures iptables to allow SSH only from a trusted IP address and block all others.

Usage
- Run `checkups.sh` with optional access and error log flags:

```bash
./checkups.sh --accesslog /var/log/nginx/access.log --errorlog /var/log/nginx/error.log
```

- Run `nginxchecks.sh` with the access log path:

```bash
./nginxchecks.sh --accesslog /var/log/nginx/access.log --errorlog /var/log/nginx/error.log
```

- Run `vm_init.sh` with the trusted IP address allowed for SSH:

```bash
sudo ./vm_init.sh <trusted-ip>
```

For example:

```bash
sudo ./vm_init.sh 203.0.113.42
```

Notes
- Scripts are read-only and designed to run on the host (may require root to read logs in /var/log).
- No configuration changes are made by these scripts.
