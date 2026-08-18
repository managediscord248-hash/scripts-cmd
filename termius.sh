#!/usr/bin/env bash
set -e

# ==========================================================
# 👑 KINGCLOUD • TERMIUS 👑
# INDIAN TRICOLOR EDITION • TAILSCALE + SSH • NO SYSTEMD
# ==========================================================

KINGCLOUD_INIT="/etc/init.d/kingcloud"
TS_STATE="/var/lib/tailscale/tailscaled.state"
TS_LOG="/var/log/kingcloud-tailscaled.log"
TS_DATA_DIR="/var/lib/tailscale"
TS_RUNTIME_DIR="/var/run/tailscale"
TS_SOCKET="/var/run/tailscale/tailscaled.sock"
SSHD_PIDFILE="/run/sshd.pid"

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

# ==========================================================
# 👑 KINGCLOUD HEADER — FULL ASCII BANNER
# ==========================================================

show_banner() {
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
}

clear 2>/dev/null || true
show_banner

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
# 👑 MENU
# ==========================================================

echo -e "${WHITE}  1) Install & Run${RESET}"
echo -e "${WHITE}  2) Delete${RESET}"
echo -e "${WHITE}  3) Exit${RESET}"
echo

# ==========================================================
# 👑 INSTALL & RUN
# ==========================================================

install_and_run() {

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
SSHD_PIDFILE="/run/sshd.pid"

TS_SOCKET="/var/run/tailscale/tailscaled.sock"

# A crashed tailscaled can linger as a <defunct> zombie in this kind
# of container (nothing reaps orphans). pgrep still matches zombies
# by name, which falsely makes the daemon look "running" forever and
# blocks it from ever being (re)started. Ignore zombie-state pids.
tailscaled_running() {
    pid_list="$(pgrep -x tailscaled 2>/dev/null)"
    [ -z "$pid_list" ] && return 1
    for pid in $pid_list; do
        state="$(ps -o stat= -p "$pid" 2>/dev/null | tr -d ' ')"
        case "$state" in
            Z*) ;;
            *) return 0 ;;
        esac
    done
    return 1
}

start_tailscale() {

    mkdir -p /var/run/tailscale
    mkdir -p /var/lib/tailscale

    # If a live (non-zombie) tailscaled is up but its control socket
    # is gone or unreachable, e.g. after the /run tmpfs was reset,
    # kill it and restart cleanly instead of skipping.
    if tailscaled_running; then
        if [ ! -S "$TS_SOCKET" ] || ! tailscale --socket="$TS_SOCKET" status >/dev/null 2>&1; then
            pkill -x tailscaled >/dev/null 2>&1 || true
            sleep 1
        fi
    fi

    if ! tailscaled_running; then

        /usr/sbin/tailscaled \
            --tun=userspace-networking \
            --state="$TS_STATE" \
            --socket="$TS_SOCKET" \
            >>"$TS_LOG" 2>&1 &

        # Wait for the control socket to actually appear instead of
        # a flat sleep, so we don't race a slow-starting daemon.
        for _ in 1 2 3 4 5 6 7 8 9 10; do
            [ -S "$TS_SOCKET" ] && break
            sleep 1
        done
    fi
}

start_ssh() {

    mkdir -p /run/sshd

    # -----------------------------
    # Reload safely if already running (does not drop active
    # sessions), otherwise start directly. No systemctl, ever.
    # -----------------------------

    if [ -f "$SSHD_PIDFILE" ] && kill -0 "$(cat "$SSHD_PIDFILE" 2>/dev/null)" 2>/dev/null; then

        kill -HUP "$(cat "$SSHD_PIDFILE")" >/dev/null 2>&1 || true

    elif pgrep -x sshd >/dev/null 2>&1; then

        MASTER_PID="$(pgrep -x sshd | sort -n | head -n1)"
        kill -HUP "$MASTER_PID" >/dev/null 2>&1 || true

    else

        /usr/sbin/sshd >/dev/null 2>&1 || true

    fi
}

start_services() {

    mkdir -p /var/run/tailscale
    mkdir -p /var/lib/tailscale
    mkdir -p /run/sshd

    start_tailscale
    start_ssh
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

    start-tailscale)
        mkdir -p /var/run/tailscale
        mkdir -p /var/lib/tailscale
        start_tailscale
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
        echo "Usage: $0 {start|stop|restart|status|start-tailscale}"
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
    # START TAILSCALE (SSH is intentionally NOT started yet —
    # sshd_config has not been written out below this point)
    # ==========================================================

    loading "Starting Tailscale"

    "$KINGCLOUD_INIT" start-tailscale >/dev/null 2>&1

    sleep 3

    # ==========================================================
    # EXISTING TAILSCALE CHECK
    # ==========================================================

    TS_IP="$(tailscale --socket="$TS_SOCKET" ip -4 2>/dev/null || true)"

    if [ -n "$TS_IP" ]; then

        echo
        echo -e "${GREEN}  ✓ Existing Tailscale session detected${RESET}"
        echo -e "${CYAN}  ✓ Using existing Tailscale IP: ${WHITE}${TS_IP}${RESET}"
        echo

    else

        echo
        echo -e "${YELLOW}  Tailscale authentication required.${RESET}"
        echo

        tailscale --socket="$TS_SOCKET" up

        sleep 3

        TS_IP="$(tailscale --socket="$TS_SOCKET" ip -4 2>/dev/null || true)"

    fi

    if [ -z "$TS_IP" ]; then

        echo
        echo -e "${RED}  ❌ Could not obtain Tailscale IPv4.${RESET}"
        exit 1

    fi

    # ==========================================================
    # SSH CONFIG (written BEFORE sshd is ever started)
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

    if ! /usr/sbin/sshd -t >/dev/null 2>&1; then

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
    # START SSH (config is now written + validated — first real
    # start, or a safe HUP reload if something was already
    # running from a previous run)
    # ==========================================================

    loading "Starting SSH"

    "$KINGCLOUD_INIT" start >/dev/null 2>&1

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
}

# ==========================================================
# 👑 DELETE — FULLY REMOVE TERMIUS + TAILSCALE
# ==========================================================

delete_kingcloud() {

    echo
    echo -e "${YELLOW}  ⚠  This will completely remove the KingCloud Termius${RESET}"
    echo -e "${YELLOW}     installation and Tailscale from this machine.${RESET}"
    echo -e "${GRAY}     SSH itself and your current SSH session will NOT be touched.${RESET}"
    echo

    read -r -p "$(echo -e "${RED}  Type DELETE to confirm: ${RESET}")" CONFIRM_DELETE

    if [ "$CONFIRM_DELETE" != "DELETE" ]; then
        echo
        echo -e "${GRAY}  Cancelled. No changes were made.${RESET}"
        echo
        exit 0
    fi

    loading "Stopping KingCloud services"

    pkill -x tailscaled >/dev/null 2>&1 || true

    loading "Removing boot auto-start"

    if command -v update-rc.d >/dev/null 2>&1; then
        update-rc.d -f kingcloud remove >/dev/null 2>&1 || true
    fi

    if command -v rc-update >/dev/null 2>&1; then
        rc-update del kingcloud default >/dev/null 2>&1 || true
    fi

    loading "Removing KingCloud service files"

    rm -f "$KINGCLOUD_INIT" >/dev/null 2>&1 || true
    rm -f "$TS_LOG" >/dev/null 2>&1 || true

    loading "Removing Tailscale"

    if command -v apt-get >/dev/null 2>&1; then
        apt-get remove -y tailscale >/dev/null 2>&1 || true
        apt-get purge -y tailscale >/dev/null 2>&1 || true
    elif command -v apk >/dev/null 2>&1; then
        apk del tailscale >/dev/null 2>&1 || true
    elif command -v dnf >/dev/null 2>&1; then
        dnf remove -y tailscale >/dev/null 2>&1 || true
    elif command -v yum >/dev/null 2>&1; then
        yum remove -y tailscale >/dev/null 2>&1 || true
    fi

    rm -rf "$TS_DATA_DIR" >/dev/null 2>&1 || true
    rm -rf "$TS_RUNTIME_DIR" >/dev/null 2>&1 || true
    rm -rf /run/tailscale >/dev/null 2>&1 || true
    rm -f /etc/default/tailscaled >/dev/null 2>&1 || true

    echo
    echo -e "${GREEN}  ✓ KingCloud Termius and Tailscale have been removed.${RESET}"
    echo -e "${GRAY}  ✓ SSH and your current session remain untouched.${RESET}"
    echo
    echo -e "${SAFFRON}👑 KINGCLOUD${WHITE} • ${GREEN}TERMIUS${RESET} 👑"
    echo

    exit 0
}

# ==========================================================
# 👑 MENU DISPATCH
# ==========================================================

while true; do

    read -r -p "$(echo -e "${CYAN}Enter choice [1-3]: ${RESET}")" MENU_CHOICE

    case "$MENU_CHOICE" in

        1)
            clear 2>/dev/null || true
            show_banner
            install_and_run
            break
            ;;

        2)
            clear 2>/dev/null || true
            show_banner
            delete_kingcloud
            break
            ;;

        3)
            echo
            echo -e "${GRAY}  Exiting.${RESET}"
            echo
            exit 0
            ;;

        *)
            echo -e "${RED}  ❌ Invalid choice. Please enter 1, 2, or 3.${RESET}"
            echo
            ;;

    esac

done
