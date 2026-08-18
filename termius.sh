#!/usr/bin/env bash
set -e

# ==========================================================
# 👑 KINGCLOUD • TERMIUS 👑
# INDIAN TRICOLOR EDITION • TAILSCALE + SSH • NO SYSTEMD
# ==========================================================

KINGCLOUD_INIT="/etc/init.d/kingcloud"
TS_STATE="/var/lib/tailscale/tailscaled.state"
TS_LOG="/var/log/kingcloud-tailscaled.log"

ROOT_USER="root"

# ==========================================================
# 👑 INDIAN TRICOLOR PALETTE
# ==========================================================

SAFFRON='\033[1;38;5;208m'
WHITE='\033[1;97m'
GREEN='\033[1;38;5;46m'
NAVY='\033[1;38;5;27m'
CYAN='\033[1;96m'
BLUE='\033[1;94m'
MAGENTA='\033[1;95m'
PINK='\033[1;38;5;201m'
YELLOW='\033[1;93m'
RED='\033[1;91m'
GRAY='\033[0;90m'
RESET='\033[0m'

# ==========================================================
# ROOT CHECK
# ==========================================================

if [ "$(id -u)" -ne 0 ]; then
    echo -e "${RED}❌ Please run this script as root.${RESET}"
    exit 1
fi

clear 2>/dev/null || true

# ==========================================================
# 👑 KINGCLOUD HEADER — FULL ASCII BANNER
# ==========================================================

echo
echo -e "${SAFFRON}  █   █ █████ █   █  ███   ████ █      ███  █   █ ████${RESET}"
echo -e "${SAFFRON}  █  █    █   ██  █ █     █     █     █   █ █   █ █   █${RESET}"
echo -e "${WHITE}  ███     █   █ █ █ █  ██ █     █     █   █ █   █ █   █${RESET}"
echo -e "${GREEN}  █  █    █   █  ██ █   █ █     █     █   █ █   █ █   █${RESET}"
echo -e "${GREEN}  █   █ █████ █   █  ███   ████ █████  ███   ███  ████${RESET}"
echo
echo -e "${SAFFRON}                ━━━━━━━━━━━━━${WHITE}━━━━━━━━━━━━${GREEN}━━━━━━━━━━━━${RESET}"
echo -e "${WHITE}                TERMIUS • SSH • TAILSCALE${RESET}"
echo -e "${NAVY}                NO SYSTEMD • ${MAGENTA}PANEL${RESET}"
echo -e "${SAFFRON}                ━━━━━━━━━━━━━${WHITE}━━━━━━━━━━━━${GREEN}━━━━━━━━━━━━${RESET}"
echo

echo -e "${CYAN}               👑 KINGCLOUD • TERMIUS 👑${RESET}"
echo -e "${GRAY}            ───────────────────────────${RESET}"
echo
echo -e "${SAFFRON}       ●${WHITE} ●${GREEN} ●${NAVY} ●${CYAN} ●${MAGENTA} ●${RESET}"
echo

# ==========================================================
# LOADING
# ==========================================================

loading() {
    local msg="$1"

    printf "${CYAN}  ◉ ${WHITE}%s${RESET}" "$msg"

    for i in 1 2 3; do
        sleep 0.25
        printf "${SAFFRON}.${RESET}"
        sleep 0.25
        printf "${WHITE}.${RESET}"
        sleep 0.25
        printf "${GREEN}.${RESET}"
    done

    echo
}

# ==========================================================
# PACKAGE UPDATE
# ==========================================================

loading "Updating packages"

apt update >/dev/null 2>&1

loading "Installing required packages"

apt install -y \
    curl \
    bash \
    sudo \
    openssh-server \
    iproute2 \
    >/dev/null 2>&1

# ==========================================================
# TAILSCALE DETECTION
# ==========================================================

TAILSCALE_INSTALLED=false

if command -v tailscale >/dev/null 2>&1; then
    TAILSCALE_INSTALLED=true
fi

if [ "$TAILSCALE_INSTALLED" = false ]; then

    loading "Installing Tailscale"

    curl -fsSL https://tailscale.com/install.sh | sh >/dev/null 2>&1

else

    echo -e "${GREEN}  ✓ Tailscale already installed${RESET}"

fi

# ==========================================================
# DIRECTORIES
# ==========================================================

mkdir -p /var/run/tailscale
mkdir -p /var/lib/tailscale
mkdir -p /run/sshd

# ==========================================================
# 👑 CREATE AUTO-START SERVICE
# ==========================================================

loading "Creating auto-start service"

cat > "$KINGCLOUD_INIT" <<'INITEOF'
#!/bin/sh

### BEGIN INIT INFO
# Provides:          kingcloud
# Required-Start:    $remote_fs $network
# Required-Stop:     $remote_fs
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: KingCloud Tailscale + SSH
### END INIT INFO

TS_STATE="/var/lib/tailscale/tailscaled.state"
TS_LOG="/var/log/kingcloud-tailscaled.log"

start_services() {

    mkdir -p /var/run/tailscale
    mkdir -p /var/lib/tailscale
    mkdir -p /run/sshd

    # -----------------------------
    # TAILSCALE
    # -----------------------------

    if ! pgrep -x tailscaled >/dev/null 2>&1; then

        /usr/sbin/tailscaled \
            --tun=userspace-networking \
            --state="$TS_STATE" \
            >>"$TS_LOG" 2>&1 &

        sleep 3
    fi

    # -----------------------------
    # SSH
    # -----------------------------

    if command -v service >/dev/null 2>&1; then
        service ssh start >/dev/null 2>&1 || true
    fi

    if ! pgrep -x sshd >/dev/null 2>&1; then
        /usr/sbin/sshd >/dev/null 2>&1 || true
    fi
}

stop_services() {

    pkill -x tailscaled 2>/dev/null || true
    pkill -x sshd 2>/dev/null || true
}

restart_services() {

    stop_services
    sleep 1
    start_services
}

status_services() {

    echo
    echo "========== KINGCLOUD STATUS =========="

    if pgrep -x tailscaled >/dev/null 2>&1; then
        echo "Tailscale : RUNNING"
    else
        echo "Tailscale : STOPPED"
    fi

    if pgrep -x sshd >/dev/null 2>&1; then
        echo "SSH       : RUNNING"
    else
        echo "SSH       : STOPPED"
    fi

    echo "======================================"
}

case "$1" in

    start)
        start_services
        ;;

    stop)
        stop_services
        ;;

    restart)
        restart_services
        ;;

    status)
        status_services
        ;;

    *)
        echo "Usage: $0 {start|stop|restart|status}"
        exit 1
        ;;

esac

exit 0
INITEOF

chmod 755 "$KINGCLOUD_INIT"

# ==========================================================
# BOOT AUTO START
# ==========================================================

loading "Registering boot auto-start"

if command -v update-rc.d >/dev/null 2>&1; then
    update-rc.d kingcloud defaults >/dev/null 2>&1 || true
fi

if command -v rc-update >/dev/null 2>&1; then
    rc-update add kingcloud default >/dev/null 2>&1 || true
fi

# ==========================================================
# START TAILSCALE
# ==========================================================

loading "Starting Tailscale"

"$KINGCLOUD_INIT" start

sleep 3

# ==========================================================
# EXISTING TAILSCALE CHECK
# ==========================================================

TS_IP="$(tailscale ip -4 2>/dev/null || true)"

if [ -n "$TS_IP" ]; then

    echo
    echo -e "${GREEN}  ✓ Existing Tailscale session detected${RESET}"
    echo -e "${CYAN}  ✓ Using existing Tailscale IP: ${WHITE}${TS_IP}${RESET}"
    echo

else

    echo
    echo -e "${YELLOW}  Tailscale authentication required.${RESET}"
    echo

    tailscale up

    sleep 3

    TS_IP="$(tailscale ip -4 2>/dev/null || true)"

fi

if [ -z "$TS_IP" ]; then

    echo
    echo -e "${RED}  ❌ Could not obtain Tailscale IPv4.${RESET}"
    exit 1

fi

# ==========================================================
# SSH CONFIG
# ==========================================================

loading "Configuring SSH"

mkdir -p /run/sshd

cat > /etc/ssh/sshd_config <<'EOF'
PasswordAuthentication yes
PermitRootLogin yes
PubkeyAuthentication no
ChallengeResponseAuthentication no
UsePAM yes
Subsystem sftp /usr/lib/openssh/sftp-server
EOF

if ! /usr/sbin/sshd -t; then

    echo
    echo -e "${RED}  ❌ SSH configuration is invalid.${RESET}"
    exit 1

fi

# ==========================================================
# MANUAL ROOT PASSWORD
# ==========================================================

echo
echo -e "${SAFFRON}  🔐 Set your root password${RESET}"
echo -e "${GRAY}  Enter it below; it will NOT be displayed.${RESET}"
echo

while true; do
    read -r -s -p "  Enter new root password: " ROOT_PASSWORD
    echo
    read -r -s -p "  Confirm root password: " ROOT_PASSWORD_CONFIRM
    echo

    if [ -z "$ROOT_PASSWORD" ]; then
        echo -e "${RED}  ❌ Password cannot be empty.${RESET}"
        echo
        continue
    fi

    if [ "$ROOT_PASSWORD" != "$ROOT_PASSWORD_CONFIRM" ]; then
        echo -e "${RED}  ❌ Passwords do not match. Try again.${RESET}"
        echo
        continue
    fi

    printf '%s:%s\n' "$ROOT_USER" "$ROOT_PASSWORD" | chpasswd
    unset ROOT_PASSWORD
    unset ROOT_PASSWORD_CONFIRM
    break
done

echo -e "${GREEN}  ✓ Root password set successfully${RESET}"

# ==========================================================
# START SSH
# ==========================================================

loading "Starting SSH"

"$KINGCLOUD_INIT" start

sleep 2

# ==========================================================
# STATUS
# ==========================================================

if pgrep -x tailscaled >/dev/null 2>&1; then
    TS_STATUS="${GREEN}ONLINE${RESET}"
else
    TS_STATUS="${RED}OFFLINE${RESET}"
fi

if pgrep -x sshd >/dev/null 2>&1; then
    SSH_STATUS="${GREEN}ONLINE${RESET}"
else
    SSH_STATUS="${RED}OFFLINE${RESET}"
fi

# ==========================================================
# 👑 FINAL SCREEN — FULL ASCII BANNER
# ==========================================================

clear 2>/dev/null || true

echo
echo -e "${SAFFRON}  █   █ █████ █   █  ███   ████ █      ███  █   █ ████${RESET}"
echo -e "${SAFFRON}  █  █    █   ██  █ █     █     █     █   █ █   █ █   █${RESET}"
echo -e "${WHITE}  ███     █   █ █ █ █  ██ █     █     █   █ █   █ █   █${RESET}"
echo -e "${GREEN}  █  █    █   █  ██ █   █ █     █     █   █ █   █ █   █${RESET}"
echo -e "${GREEN}  █   █ █████ █   █  ███   ████ █████  ███   ███  ████${RESET}"
echo
echo -e "${WHITE}                    T E R M I U S${RESET}"
echo
echo -e "${WHITE}                     KINGCLOUD PANEL${RESET}"
echo -e "${GREEN}          TAILSCALE  •  SSH  •  NO SYSTEMD${RESET}"
echo -e "${SAFFRON}                ━━━━━━━━━━━━━${WHITE}━━━━━━━━━━━━${GREEN}━━━━━━━━━━━━${RESET}"
echo

echo -e "${CYAN}╔══════════════════════════════════════════════╗${RESET}"
echo -e "${CYAN}║${RESET}             ${GREEN}✓ SETUP COMPLETE${RESET}              ${CYAN}║${RESET}"
echo -e "${CYAN}╠══════════════════════════════════════════════╣${RESET}"
echo -e "${CYAN}║${RESET}                                              ${CYAN}║${RESET}"
printf "${CYAN}║${RESET}  🌐 TAILSCALE IP     : ${WHITE}%-18s${RESET} ${CYAN}║${RESET}\n" "$TS_IP"
printf "${CYAN}║${RESET}  👤 USERNAME         : ${WHITE}%-18s${RESET} ${CYAN}║${RESET}\n" "$ROOT_USER"
printf "${CYAN}║${RESET}  🔑 ROOT PASSWORD    : ${YELLOW}%-18s${RESET} ${CYAN}║${RESET}\n" "SET MANUALLY"
printf "${CYAN}║${RESET}  🔌 SSH PORT         : ${WHITE}%-18s${RESET} ${CYAN}║${RESET}\n" "22"
echo -e "${CYAN}║${RESET}  📡 TAILSCALE        : ${TS_STATUS}              ${CYAN}║${RESET}"
echo -e "${CYAN}║${RESET}  🔐 SSH              : ${SSH_STATUS}              ${CYAN}║${RESET}"
echo -e "${CYAN}║${RESET}  ♻️  AUTO START       : ${GREEN}ENABLED${RESET}              ${CYAN}║${RESET}"
echo -e "${CYAN}║${RESET}                                              ${CYAN}║${RESET}"
echo -e "${CYAN}╠══════════════════════════════════════════════╣${RESET}"
echo -e "${CYAN}║${RESET}  ${MAGENTA}After VPS reboot:${RESET}                         ${CYAN}║${RESET}"
echo -e "${CYAN}║${RESET}  ${GREEN}✓ Tailscale starts automatically${RESET}         ${CYAN}║${RESET}"
echo -e "${CYAN}║${RESET}  ${GREEN}✓ SSH starts automatically${RESET}              ${CYAN}║${RESET}"
echo -e "${CYAN}║${RESET}                                              ${CYAN}║${RESET}"
echo -e "${CYAN}╚══════════════════════════════════════════════╝${RESET}"

echo
echo -e "${SAFFRON}●${WHITE} ●${GREEN} ●${NAVY} ●${CYAN} ●${MAGENTA} ●${RESET}"
echo
echo -e "${GRAY}Service: /etc/init.d/kingcloud${RESET}"
echo
echo -e "${WHITE}Manual commands:${RESET}"
echo -e "${CYAN}  service kingcloud start${RESET}"
echo -e "${CYAN}  service kingcloud stop${RESET}"
echo -e "${CYAN}  service kingcloud restart${RESET}"
echo -e "${CYAN}  service kingcloud status${RESET}"
echo
echo -e "${SAFFRON}👑 KINGCLOUD${WHITE} • ${GREEN}TERMIUS${RESET} 👑"
echo
