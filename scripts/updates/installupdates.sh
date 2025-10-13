#!/bin/bash
#  _____           _        _ _   _   _           _       _            
# |_   _|         | |      | | | | | | |         | |     | |           
#   | |  _ __  ___| |_ __ _| | | | | | |_ __   __| | __ _| |_ ___  ___ 
#   | | | '_ \/ __| __/ _` | | | | | | | '_ \ / _` |/ _` | __/ _ \/ __|
#  _| |_| | | \__ \ || (_| | | | | |_| | |_) | (_| | (_| | ||  __/\__ \
# |_____|_| |_|___/\__\__,_|_|_|  \___/| .__/ \__,_|\__,_|\__\___||___/
#                                      | |                              
#                                      |_|                              
#  

# Detect platform
if [ -f ~/.config/ml4w/settings/platform.sh ]; then
    install_platform="$(cat ~/.config/ml4w/settings/platform.sh)"
else
    # Auto-detect platform
    if [ -f /etc/arch-release ]; then
        install_platform="arch"
    elif [ -f /etc/fedora-release ]; then
        install_platform="fedora"
    else
        install_platform="arch"  # default to arch
    fi
fi

echo "╔═══════════════════════════════════════════════════════════╗"
echo "║                   System Update Process                   ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

case $install_platform in
    arch)
        # Detect AUR helper
        if [ -f ~/.config/ml4w/settings/aur.sh ]; then
            aur_helper="$(cat ~/.config/ml4w/settings/aur.sh)"
        elif command -v yay &>/dev/null; then
            aur_helper="yay"
        elif command -v paru &>/dev/null; then
            aur_helper="paru"
        else
            aur_helper=""
        fi
        
        echo "Platform: Arch Linux"
        if [ -n "$aur_helper" ]; then
            echo "AUR Helper: $aur_helper"
        fi
        echo ""
        echo "Starting system update..."
        echo ""
        
        # Update system
        if [ -n "$aur_helper" ] && command -v $aur_helper &> /dev/null; then
            $aur_helper -Syu
        else
            sudo pacman -Syu
        fi
        ;;
    fedora)
        echo "Platform: Fedora"
        echo ""
        echo "Starting system update..."
        echo ""
        
        sudo dnf upgrade
        ;;
    *)
        echo "Platform: Unknown ($install_platform)"
        echo ""
        echo "Attempting generic update with pacman..."
        echo ""
        
        sudo pacman -Syu
        ;;
esac

echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║           Update Complete!                               ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""
echo "Press Enter to close this window..."
read

