#!/bin/bash

# =========================================================
#                 👑 KINGCLOUD CMD PANEL
#             Pink + Blue Terminal Theme
# =========================================================

# Colors
PINK='\033[1;35m'
BLUE='\033[1;36m'
GOLD='\033[1;33m'
WHITE='\033[1;37m'
RED='\033[1;31m'
RESET='\033[0m'

# Crown + KINGCLOUD banner
banner() {
    echo -e "${GOLD}"
    echo "                 ♛"
    echo "              ╭─────╮"
    echo "             ╱  👑  ╲"
    echo "            ╱ KINGCLOUD ╲"
    echo "           ╰─────────────╯"
    echo -e "${RESET}"

    echo -e "${PINK}╔══════════════════════════════════════════════╗${RESET}"
    echo -e "${PINK}║${BLUE}              KINGCLOUD PANEL                ${PINK}║${RESET}"
    echo -e "${PINK}╠══════════════════════════════════════════════╣${RESET}"
    echo -e "${PINK}║${RESET} ${BLUE}1${RESET}  ${WHITE}VM Manager${RESET}                              ${PINK}║${RESET}"
    echo -e "${PINK}║${RESET} ${BLUE}2${RESET}  ${WHITE}Termius Installer${RESET}                      ${PINK}║${RESET}"
    echo -e "${PINK}║${RESET} ${BLUE}3${RESET}  ${WHITE}JTG Installer${RESET}                         ${PINK}║${RESET}"
    echo -e "${PINK}║${RESET} ${BLUE}4${RESET}  ${WHITE}Exit${RESET}                                  ${PINK}║${RESET}"
    echo -e "${PINK}╚══════════════════════════════════════════════╝${RESET}"
    echo
}

while true; do
    clear
    banner

    echo -ne "${BLUE}╭─[${PINK}KINGCLOUD${BLUE}]${RESET} ${WHITE}Select an option${RESET} ${BLUE}➜ ${RESET}"
    read choice

    case "$choice" in
        1)
            clear
            echo -e "${BLUE}Starting ${PINK}VM Manager${BLUE}...${RESET}"
            sleep 1
            bash <(curl -fsSL https://raw.githubusercontent.com/managediscord248-hash/scripts-cmd/refs/heads/main/vm.sh)
            ;;

        2)
            clear
            echo -e "${BLUE}Starting ${PINK}Termius Installer${BLUE}...${RESET}"
            sleep 1
            bash <(curl -fsSL https://raw.githubusercontent.com/managediscord248-hash/scripts-cmd/refs/heads/main/termius.sh)
            ;;

        3)
            clear
            echo -e "${BLUE}Starting ${PINK}JTG Installer${BLUE}...${RESET}"
            sleep 1
            bash <(curl -fsSL https://raw.githubusercontent.com/managediscord248-hash/scripts-cmd/refs/heads/main/jtg.sh)
            ;;

        4)
            clear
            echo -e "${GOLD}                 ♛${RESET}"
            echo -e "${GOLD}             KINGCLOUD${RESET}"
            echo
            echo -e "${BLUE}Thanks for using ${PINK}KINGCLOUD${BLUE}!${RESET}"
            echo
            exit 0
            ;;

        *)
            echo -e "${RED}Invalid option!${RESET}"
            sleep 2
            ;;
    esac

    echo
    echo -ne "${PINK}Press Enter to return to KINGCLOUD menu...${RESET}"
    read
done
