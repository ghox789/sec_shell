#!/usr/bin/env bash
#
# secure-linux.sh – One‑click hardening for a fresh Debian/Ubuntu system.
# ---------------------------------------------------------------
# What it does:
#   1️⃣ Enable automatic security updates
#   2️⃣ Install & configure UFW firewall
#   3️⃣ Harden SSH (custom port, key‑only auth, Fail2Ban)
#   4️⃣ Install IDS/anti‑malware tools (AIDE, ClamAV, rkhunter)
#   5️⃣ Enable AppArmor in enforcing mode
#   6️⃣ Set up basic log monitoring (auditd, logwatch)
#   7️⃣ Install a placeholder backup script (customise the destination)
#
# Run as root (or with sudo):
#   sudo bash secure-linux.sh
# ---------------------------------------------------------------

set -euo pipefail
IFS=$'\n\t'

# ------------------- Helper Functions -------------------
log()   { echo -e "\e[32m[+] $*\e[0m"; }
warn()  { echo -e "\e[33m[!] $*\e[0m"; }
error_exit() {
    echo -e "\e[31m[-] $*\e[0m" >&2
    exit 1
}

# --- ROBUSTNESS FIX: Ensure script is run as root ---
if [[ "$EUID" -ne 0 ]]; then
    error_exit "This script must be run as root. Please use sudo."
fi

# ------------------- 1. Automatic Security Updates -------------------
log "Enabling unattended security upgrades …"
apt-get update -qq
DEBIAN_FRONTEND=noninteractive apt-get install -yqq unattended-upgrades apt-listchanges

# Force the package to be configured (re‑run if already done)
dpkg-reconfigure -plow unattended-upgrades

cat > /etc/apt/apt.conf.d/50unattended-upgrades <<'EOF'
Unattended-Upgrade::Allowed-Origins {
        "${distro_id}:${distro_codename}-security";
};
Unattended-Upgrade::Automatic-Reboot "true";
Unattended-Upgrade::Automatic-Reboot-Time "02:00";
EOF
log "Automatic security upgrades configured."

# ------------------- 2. Firewall (UFW) -------------------
log "Installing and configuring UFW firewall …"
apt-get install -yqq ufw

# Default policies
ufw default deny incoming
ufw default allow outgoing

# Choose a non‑standard SSH port (feel free to change)
SSH_PORT=2222
ufw allow "${SSH_PORT}/tcp" comment 'SSH (custom port)'

# Uncomment the following lines if you need web traffic
# ufw allow 80/tcp comment 'HTTP'
# ufw allow 443/tcp comment 'HTTPS'

ufw --force enable
log "UFW enabled. Current rules:"
ufw status verbose

# ------------------- 3. SSH Hardening -------------------
log "Hardening SSH configuration …"
SSHD_CONF="/etc/ssh/sshd_config"

# Backup original config (timestamped)
cp "$SSHD_CONF" "${SSHD_CONF}.bak.$(date +%s)"

# Helper to set/override a directive in sshd_config
set_sshd_option() {
    local key="$1" value="$2"
    # --- ROBUSTNESS FIX: Allow for whitespace before the key ---
    if grep -qE "^\s*#?\s*${key}" "$SSHD_CONF"; then
        sed -i -E "s|^\s*#?\s*(${key}).*|\1 ${value}|" "$SSHD_CONF"
    else
        echo "${key} ${value}" >>"$SSHD_CONF"
    fi
}

set_sshd_option "Port"                     "$SSH_PORT"
set_sshd_option "Protocol"                 "2"
set_sshd_option "PermitRootLogin"          "no"
set_sshd_option "PasswordAuthentication"   "no"
set_sshd_option "ChallengeResponseAuthentication" "no"
set_sshd_option "PubkeyAuthentication"    "yes"
set_sshd_option "X11Forwarding"           "no"
set_sshd_option "AllowTcpForwarding"      "no"
set_sshd_option "MaxAuthTries"            "3"
set_sshd_option "LogLevel"                "VERBOSE"

# --- ERROR FIX: Robustly detect the SSH service name ---
# This logic checks for the common names and exits if neither is found.
if systemctl list-units --type=service | grep -q 'ssh.service'; then
    SSH_UNIT="ssh.service"
elif systemctl list-units --type=service | grep -q 'sshd.service'; then
    SSH_UNIT="sshd.service"
else
    error_exit "Could not find ssh.service or sshd.service. Cannot restart SSH."
fi

systemctl restart "$SSH_UNIT"
log "SSH restarted on port $SSH_PORT (unit: $SSH_UNIT)."

# ------------------- Fail2Ban (protect SSH) -------------------
log "Installing Fail2Ban …"
apt-get install -yqq fail2ban

cat > /etc/fail2ban/jail.local <<EOF
[sshd]
enabled = true
port    = ${SSH_PORT}
filter  = sshd
logpath = %(sshd_log)s
maxretry = 3
bantime = 1h
EOF

systemctl restart fail2ban
log "Fail2Ban started and protecting SSH."

# ------------------- 4. IDS / Anti‑Malware -------------------
log "Installing AIDE (file‑integrity monitor) …"
apt-get install -yqq aide
aideinit
cp /var/lib/aide/aide.db.new /var/lib/aide/aide.db
log "AIDE database initialized."

log "Installing ClamAV …"
apt-get install -yqq clamav clamav-daemon
freshclam   # update signatures
systemctl enable clamav-freshclam --now
systemctl enable clamav-daemon --now
log "ClamAV ready (use clamscan -r /path to scan)."

log "Installing rkhunter (rootkit scanner) …"
apt-get install -yqq rkhunter
rkhunter --update
rkhunter --propupd
log "rkhunter installed and baseline created."

# ------------------- 5. AppArmor (MAC) -------------------
log "Ensuring AppArmor is in enforcing mode …"
apt-get install -yqq apparmor apparmor-utils
systemctl enable apparmor --now
if aa-status | grep -q "enforce mode"; then
    log "AppArmor is active and enforcing."
else
    warn "AppArmor profiles are not fully enforced – check with aa-status."
fi

# ------------------- 6. Log Rotation & Basic Monitoring -------------------
log "Installing Logwatch for daily summaries …"
apt-get install -yqq logwatch
log "Logwatch installed (daily mail to root)."

log "Installing auditd for kernel‑level auditing …"
apt-get install -yqq auditd audispd-plugins
systemctl enable auditd --now
log "auditd running."

# ------------------- 7. Simple Backup Skeleton -------------------
log "Creating a placeholder backup script (customise DEST_DIR) …"
cat > /usr/local/sbin/simple-backup.sh <<'EOS'
#!/usr/bin/env bash
# Tiny backup wrapper – edit DEST_DIR to point at your real backup location.
set -euo pipefail
SRC_DIR="/home"
DEST_DIR="/mnt/backup"   # <<< EDIT THIS PATH BEFORE USING!
TIMESTAMP=$(date +"%Y%m%d-%H%M")
ARCHIVE="${DEST_DIR}/backup-${HOSTNAME}-${TIMESTAMP}.tar.gz"

echo "[*] Starting backup of ${SRC_DIR} → ${ARCHIVE}"
tar --numeric-owner --acls --xattrs -czpf "${ARCHIVE}" "${SRC_DIR}"
echo "[*] Backup finished."
EOS
chmod +x /usr/local/sbin/simple-backup.sh
log "Backup stub installed at /usr/local/sbin/simple-backup.sh (edit DEST_DIR!)."

# ------------------- Final Summary -------------------
# --- ERROR FIX: Changed <<'EOF' to <<EOF to allow variable expansion. ---
cat <<EOF

=============================================================
✅  System hardening complete!

Key protections applied:
  • Unattended security updates
  • UFW firewall (default deny inbound)
  • SSH on custom port ${SSH_PORT}, key‑only auth, protected by Fail2Ban
  • AIDE file‑integrity monitoring
  • ClamAV anti‑virus scanner
  • rkhunter rootkit checker
  • AppArmor in enforcing mode
  • auditd + logwatch for auditing & daily logs
  • Starter backup script (customise destination)

Next steps you may want to take:
  • Verify SSH connectivity:   ssh -p ${SSH_PORT} user@your-host
  • Add any additional UFW rules for services you actually run.
  • Schedule regular AIDE / rkhunter scans via cron or systemd timers.
  • Replace the backup stub with your preferred remote storage solution.
  • Review ${SSHD_CONF} for any extra hardening options you need.

If anything looks odd, the original SSH config backup is stored
with a timestamp, like: ${SSHD_CONF}.bak.1664991823

Happy (and secure) computing!

EOF
