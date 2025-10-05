# One-Click Linux Hardening Script (`secshell.sh`)

This script is designed to apply a set of essential security best practices to a fresh **Debian** or **Ubuntu** server. It automates the initial hardening process to help protect your system from common threats.

---

## 🛡️ Features

* **Automatic Security Updates**: Configures `unattended-upgrades` to automatically install new security patches.
* **UFW Firewall**: Installs and enables the Uncomplicated Firewall (UFW) with a default-deny incoming policy.
* **SSH Hardening**:
    * Changes the default SSH port to `2222`.
    * Disables password-based and root login.
    * Enforces key-only authentication.
* **Brute-Force Protection**: Installs and configures `Fail2Ban` to automatically block IPs that repeatedly fail to log in.
* **Intrusion Detection & Malware Scanning**:
    * **AIDE**: An intrusion detection system that creates a baseline of your system files to detect unauthorized changes.
    * **ClamAV**: An open-source antivirus engine for detecting trojans, viruses, and malware.
    * **rkhunter** (Rootkit Hunter): A tool that scans for rootkits and other system backdoors.
* **Mandatory Access Control**: Ensures `AppArmor` is installed and running in enforcing mode.
* **Logging & Monitoring**: Installs `auditd` for detailed system auditing and `logwatch` for generating daily log summary reports.
* **Backup Skeleton**: Creates a simple placeholder backup script at `/usr/local/sbin/simple-backup.sh` for you to customize.

---

## 🚀 Usage

> **Warning**: This script makes significant changes to your system, including changing the SSH port and disabling password authentication. Ensure you have SSH key-based access set up before running it.

You can download and run the script with a single command. Execute it as the **root** user or with `sudo`.

```bash
curl -O https://path/to/your/secshell.sh
sudo bash secshell.sh
---
##⚠️ Important Post-Run Actions
1After the script completes, you must take the following steps:

Reconnect via SSH: Your SSH session will be disconnected. You need to reconnect using the new port and your SSH key
[ssh -p 2222 your_username@your_server_ip]

-2 
Configure Firewall Rules: The script only allows SSH traffic. If you run other services (like a web server), you must open the necessary ports.
# Example for a web server
sudo ufw allow http  # Port 80
sudo ufw allow https # Port 443

-3 Customize the Backup Script: The provided backup script is a placeholder. Edit it to point to your actual backup destination (e.g., an external drive, cloud storage, or another server).

sudo nano /usr/local/sbin/simple-backup.sh

-4 Schedule Scans: The script installs security scanners but does not schedule them. You should set up cron jobs or systemd timers to run AIDE and rkhunter scans regularly (e.g., daily).
Got it. Here is the updated README.md with all instances of the script name changed to secshell.sh.

Markdown

# One-Click Linux Hardening Script (`secshell.sh`)

This script is designed to apply a set of essential security best practices to a fresh **Debian** or **Ubuntu** server. It automates the initial hardening process to help protect your system from common threats.

---
```
## 🛡️ Features

* **Automatic Security Updates**: Configures `unattended-upgrades` to automatically install new security patches.
* **UFW Firewall**: Installs and enables the Uncomplicated Firewall (UFW) with a default-deny incoming policy.
* **SSH Hardening**:
    * Changes the default SSH port to `2222`.
    * Disables password-based and root login.
    * Enforces key-only authentication.
* **Brute-Force Protection**: Installs and configures `Fail2Ban` to automatically block IPs that repeatedly fail to log in.
* **Intrusion Detection & Malware Scanning**:
    * **AIDE**: An intrusion detection system that creates a baseline of your system files to detect unauthorized changes.
    * **ClamAV**: An open-source antivirus engine for detecting trojans, viruses, and malware.
    * **rkhunter** (Rootkit Hunter): A tool that scans for rootkits and other system backdoors.
* **Mandatory Access Control**: Ensures `AppArmor` is installed and running in enforcing mode.
* **Logging & Monitoring**: Installs `auditd` for detailed system auditing and `logwatch` for generating daily log summary reports.
* **Backup Skeleton**: Creates a simple placeholder backup script at `/usr/local/sbin/simple-backup.sh` for you to customize.

---
```
## 🚀 Usage

> **Warning**: This script makes significant changes to your system, including changing the SSH port and disabling password authentication. Ensure you have SSH key-based access set up before running it.

You can download and run the script with a single command. Execute it as the **root** user or with `sudo`.

```bash
curl -O https://path/to/your/secshell.sh
sudo bash secshell.sh
⚠️ Important Post-Run Actions
After the script completes, you must take the following steps:

Reconnect via SSH: Your SSH session will be disconnected. You need to reconnect using the new port and your SSH key.

Bash

ssh -p 2222 your_username@your_server_ip
Configure Firewall Rules: The script only allows SSH traffic. If you run other services (like a web server), you must open the necessary ports.

Bash

# Example for a web server
sudo ufw allow http  # Port 80
sudo ufw allow https # Port 443
Customize the Backup Script: The provided backup script is a placeholder. Edit it to point to your actual backup destination (e.g., an external drive, cloud storage, or another server).

Bash

sudo nano /usr/local/sbin/simple-backup.sh
Schedule Scans: The script installs security scanners but does not schedule them. You should set up cron jobs or systemd timers to run AIDE and rkhunter scans regularly (e.g., daily).

```
Disclaimer
This script is provided as a starting point for system hardening and comes with no warranty. Always review scripts from the internet before running them on your systems. Understand the changes being made, and ensure they are appropriate for your specific environment and use case.

 
