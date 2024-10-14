#!/bin/bash

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check for sudo privileges
if [ "$EUID" -ne 0 ]; then
    echo "This script requires sudo privileges."
    exit 1
fi

# Check if Rclone is installed, if not prompt the user to install it
if ! command_exists rclone; then
    echo "Rclone is not installed. Please install Rclone first to proceed."
    if command_exists pacman; then
        echo "Installing Rclone on Arch-based system..."
        sudo pacman -S rclone
    elif command_exists apt; then
        echo "Installing Rclone on Debian-based system..."
        sudo apt update && sudo apt install rclone
    else
        echo "Please manually install Rclone as your package manager is not recognized."
        exit 1
    fi
fi

# Ask for the Rclone remote drive name
read -p "Enter the name of your Rclone drive (e.g., OneDriveAdmin): " RCLONE_DRIVE

# Ask for folder location
read -p "Enter the folder name where backup files should be created (default: ~/Backup): " FOLDER_NAME
FOLDER_NAME=${FOLDER_NAME:-"$HOME/Backup"}
FOLDER_PATH=$(realpath "$FOLDER_NAME")

# Create folder if it doesn't exist
mkdir -p "$FOLDER_PATH"
echo "Created folder at $FOLDER_PATH"

# Create the rclone backup script
RCLONE_SCRIPT="$FOLDER_PATH/rclone_backup.sh"
cat <<EOF > "$RCLONE_SCRIPT"
#!/bin/bash

# Run the rclone backup and capture output
OUTPUT=\$(rclone sync /"$RCLONE_DRIVE":Hyprland-bak --filter-from "$FOLDER_PATH/filter.txt" --skip-links 2>&1)



# Print summary to console (or you could log it to a file)
echo -e "\$SUMMARY_MESSAGE"
EOF

# Make the rclone backup script executable
chmod +x "$RCLONE_SCRIPT"
echo "Created and made rclone_backup.sh executable in $FOLDER_PATH"

# Add the content of filter.txt directly to the script
cat <<EOF > "$FOLDER_PATH/filter.txt"
# Include the entire /etc directory
+ /etc/**

# Include specific directories under /home/radiant
+ /home/radiant/Desktop/**
+ /home/radiant/Documents/**
+ /home/radiant/Pictures/**

# Exclude everything else
- *
EOF

echo "Created filter.txt with backup rules in $FOLDER_PATH"

# Create a systemd service for backup (rcloneback.service)
SERVICE_PATH="/etc/systemd/system/rcloneback.service"
cat <<EOF | sudo tee "$SERVICE_PATH" >/dev/null
[Unit]
Description=Run Rclone Backup Script at Startup

[Service]
ExecStart=$RCLONE_SCRIPT
User=$(whoami)
WorkingDirectory=$FOLDER_PATH
Environment=DISPLAY=:0
Environment=XAUTHORITY=$HOME/.Xauthority
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

# Enable and start the service
sudo systemctl daemon-reload
sudo systemctl enable rcloneback.service
sudo systemctl start rcloneback.service
echo "Service created, enabled, and started as rcloneback.service."

# Success message
echo "Setup complete! The rclone backup script will now run on every startup."
