#!/bin/bash

while true; do
    clear

    echo "======================================"
    echo "          ☁️ KINGCLOUD"
    echo "======================================"
    echo ""
    echo "1) VM Manager"
    echo "2) Termius Installer"
    echo "3) JTG Installer"
    echo "4) Exit"
    echo ""

    read -p "Select an option [1-4]: " choice

    case "$choice" in
        1)
            bash <(curl -fsSL https://raw.githubusercontent.com/managediscord248-hash/scripts-cmd/refs/heads/main/vm.sh)
            ;;

        2)
            bash <(curl -fsSL https://raw.githubusercontent.com/managediscord248-hash/scripts-cmd/refs/heads/main/termius.sh)
            ;;

        3)
            bash <(curl -fsSL https://raw.githubusercontent.com/managediscord248-hash/scripts-cmd/refs/heads/main/jtg.sh)
            ;;

        4)
            echo "Goodbye! 👋"
            exit 0
            ;;

        *)
            echo "Invalid option!"
            sleep 2
            ;;
    esac

    echo ""
    read -p "Press Enter to return to the menu..."
done
