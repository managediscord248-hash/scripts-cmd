#!/usr/bin/env bash
set -e

clear 2>/dev/null || true

cat <<'EOF'

                 👑

  _  ___ _   _  ____   ____ _     ___  _   _
 | |/ / | | | |/ ___| / ___| |   / _ \| | | |
 | ' /| | | | | |  _ | |   | |  | | | | | | |
 | . \| |_| | |_| || |___| |__| |_| | |_| |
 |_|\_\\___/ \____| \____|_____\___/ \___/

================================================
              KINGCLOUD • TERMIUS
================================================

EOF

loading() {
    msg="$1"
    for i in 1 2 3; do
        printf "\r👑 KINGCLOUD $msg."
        sleep 0.3
        printf "\r👑 KINGCLOUD $msg.."
        sleep 0.3
        printf "\r👑 KINGCLOUD $msg..."
        sleep 0.3
    done
    echo
}

loading "Updating packages"
apt update >/dev/null 2>&1

loading "Installing required packages"
apt install -y curl bash sudo openssh-server iproute2 >/dev/null 2>&1

loading "Installing Tailscale"
if ! command -v tailscale >/dev/null 2>&1; then
    curl -fsSL https://tailscale.com/install.sh | sh >/dev/null 2>&1
fi

loading "Starting Tailscale"

mkdir -p /var/run/tailscale /var/lib/tailscale
pkill tailscaled 2>/dev/null || true

tailscaled \
    --tun=userspace-networking \
    --state=/var/lib/tailscale/tailscaled.state \
    >/tmp/tailscaled.log 2>&1 &

sleep 3

echo
echo "Open the authentication link if Tailscale asks for one."
echo

tailscale up

echo
loading "Setting root password"
passwd root

echo
loading "Configuring SSH"

mkdir -p /run/sshd

cat >/etc/ssh/sshd_config <<'EOF'
PasswordAuthentication yes
PermitRootLogin yes
PubkeyAuthentication no
ChallengeResponseAuthentication no
UsePAM yes
Subsystem sftp /usr/lib/openssh/sftp-server
EOF

pkill sshd 2>/dev/null || true
/usr/sbin/sshd

sleep 2

TS_IP="$(tailscale ip -4)"

if [ -z "$TS_IP" ]; then
    echo "ERROR: Could not get Tailscale IPv4."
    exit 1
fi

clear 2>/dev/null || true

cat <<EOF

                 👑

================================================
              KINGCLOUD • TERMIUS
================================================

              ✅ SETUP COMPLETE

🌐 TERMIUS IP
   $TS_IP

👤 USERNAME
   root

🔑 PASSWORD
   The password you just created

🔌 PORT
   22

📡 SSH STATUS
   ONLINE

================================================
             ⚡ Powered by KingCloud
================================================

EOF
