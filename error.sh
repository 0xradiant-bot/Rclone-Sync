#!/bin/sh

# Colors :
Green='\033[0;32m'        # Green
Cyan='\033[1;36m'        # Cyan
No='\e[0m'

clear
echo -e "${Cyan} ____    __    ____   ___  _   _   "
echo -e "${Cyan}(  _ \  /__\  (_  _) / __)( )_( )  "
echo -e "${Cyan} ) _ < /(__)\   )(  ( (__  ) _ (   "
echo -e "${Cyan}(____/(__)(__) (__)  \___)(_) (_)  "
echo -e "${Cyan} __  __    __    _  _              "
echo -e "${Cyan}(  \/  )  /__\  ( \( )             "
echo -e "${Cyan} )    (  /(__)\  )  (              "
echo -e "${Cyan}(_/\/\_)(__)(__)(_)\_)             "
echo -e "${Green}By: @0xRad1ant${No}"

# Add BlackArch repository
if ! grep -q "blackarch" /etc/pacman.conf; then
    echo "[blackarch]" >> /etc/pacman.conf
    echo "Server = https://blackarch.org/blackarch/\$repo/os/\$arch" >> /etc/pacman.conf
    echo "BlackArch repository added successfully."
else
    echo "BlackArch repository is already added."
fi

# Update package database
sudo pacman -Syu --noconfirm

# Install Yay if not installed
if ! command -v yay &> /dev/null; then
    echo "Installing Yay..."
    sudo pacman -S --needed git base-devel --noconfirm
    git clone https://aur.archlinux.org/yay.git
    cd yay || exit
    makepkg -si --noconfirm
    cd .. && rm -rf yay
else
    echo "Yay is already installed."
fi

# Function to install packages if not already installed
install_package() {
    package=$1
    conflict_pkg=$2
    if ! pacman -Qq | grep -qw "$package"; then
        if yay -Qq | grep -qw "$package"; then
            echo "$package is available in AUR, installing..."
            yay -S --noconfirm "$package"
        else
            echo "$package is not installed, installing..."
            if [ -n "$conflict_pkg" ]; then
                # Check for conflicting package
                if pacman -Qq | grep -qw "$conflict_pkg"; then
                    echo "$conflict_pkg is installed, removing it first..."
                    sudo pacman -Rns --noconfirm "$conflict_pkg"
                fi
            fi
            sudo pacman -S --needed --noconfirm "$package"
        fi
    else
        echo "$package is already installed."
    fi
}

# System Utilities
install_package "git"
install_package "wget"
install_package "curl"
install_package "fastfetch"
install_package "btop"

# Networking
install_package "networkmanager"
install_package "nmap"
install_package "net-tools"
install_package "wireshark"
install_package "wifite"

# File System Utilities
install_package "ntfs-3g" "exfatprogs"
install_package "exfat-utils"

# Terminal & Shell
install_package "tmux"
install_package "bash-completion"

# Fonts
install_package "ttf-dejavu"
install_package "noto-fonts"
install_package "noto-fonts-emoji"

# Applications
install_package "firefox"
install_package "zen-browser-bin"
install_package "vlc"
install_package "libreoffice-fresh"
install_package "eog"
install_package "partitionmanager"
install_package "spotify"
install_package "obs-studio"
install_package "obsidian"
install_package "vesktop"
install_package "termius"

# Other
install_package "reflector"
install_package "rclone"
install_package "pacman-mirrorlist"
install_package "openvpn"
install_package "logwatch"
install_package "man-db"
install_package "hash-identifier"
install_package "hashcat"
install_package "google-chrome"
install_package "fast"
install_package "downgrade"
install_package "cloudflare-warp-bin"
install_package "arandr"
install_package "archlinux-keyring"
install_package "aircrack-ng"

# Development
install_package "visual-studio-code-bin"
install_package "nvim"
install_package "nodejs"
install_package "npm"

# Install find-the-command
install_package "find-the-command"

# Enable UFW and set up basic rules
sudo ufw enable
sudo systemctl enable ufw

# Check SSH and disable it
if systemctl is-active --quiet sshd; then
    echo "Disabling SSH service..."
    sudo systemctl stop sshd.service
    sudo systemctl disable sshd.service
else
    echo "SSHD service is not active."
fi

# Adding find-the-command source to .zshrc or .bashrc
if [ -f "$HOME/.zshrc" ]; then
    echo "source /usr/share/doc/find-the-command/ftc.zsh" >> "$HOME/.zshrc"
    echo "Added find-the-command to .zshrc"
elif [ -f "$HOME/.bashrc" ]; then
    echo "source /usr/share/doc/find-the-command/ftc.bash" >> "$HOME/.bashrc"
    echo "Added find-the-command to .bashrc"
fi

echo "All installations completed and configurations are set!"
