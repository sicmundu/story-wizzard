#!/bin/bash

# Colors and Emojis
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

CHECKMARK="\xE2\x9C\x85"
ERROR="\xE2\x9D\x8C"
PROGRESS="\xF0\x9F\x94\x84"
INSTALL="\xF0\x9F\x93\xA6"
SUCCESS="\xF0\x9F\x8E\x89"
WARNING="\xE2\x9A\xA0\xEF\xB8\x8F"
NODE="\xF0\x9F\x96\xA5\xEF\xB8\x8F"
INFO="\xE2\x84\xB9\xEF\xB8\x8F"

SCRIPT_VERSION="2.2.0"
LOG_FILE="$HOME/story_protocol_install.log"

# Story Protocol versions
STORY_GETH_VERSION="0.9.2-ea9f0d2"
STORY_VERSION="0.9.11-2a25df1"
STORY_GETH_URL="https://story-geth-binaries.s3.us-west-1.amazonaws.com/geth-public/geth-linux-amd64-$STORY_GETH_VERSION.tar.gz"
STORY_URL="https://story-geth-binaries.s3.us-west-1.amazonaws.com/story-public/story-linux-amd64-$STORY_VERSION.tar.gz"

# Function to show the header
show_header() {
    clear
    echo -e "${PURPLE}======================================${NC}"
    echo -e "${CYAN}    Story Protocol Node Installer    ${NC}"
    echo -e "${PURPLE}======================================${NC}"
    echo ""
}

# Function to show a separator
show_separator() {
    echo -e "${BLUE}--------------------------------------${NC}"
}

# Function to log messages
log() {
    local MESSAGE=$1
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $MESSAGE" >> "$LOG_FILE"
}

# Function to handle errors
handle_error() {
    local MESSAGE=$1
    log "$MESSAGE"
    echo -e "${ERROR} ${RED}$MESSAGE${NC}"
    exit 1
}

# Function to check for sufficient system resources
check_system_resources() {
    show_header
    echo -e "${INFO} ${YELLOW}Checking system resources...${NC}"
    local MIN_DISK=10 # GB
    local MIN_RAM=4 # GB

    local disk_avail=$(df -BG / | awk 'NR==2 {print $4}' | sed 's/G//')
    local ram_avail=$(free -g | awk '/^Mem:/{print $2}')

    if [ "$disk_avail" -lt "$MIN_DISK" ]; then
        handle_error "Insufficient disk space: ${disk_avail}GB available, ${MIN_DISK}GB required."
    fi

    if [ "$ram_avail" -lt "$MIN_RAM" ]; then
        handle_error "Insufficient RAM: ${ram_avail}GB available, ${MIN_RAM}GB required."
    fi

    echo -e "${CHECKMARK} ${GREEN}System resources are sufficient.${NC}"
}

# Function to install necessary packages
install_packages() {
    show_header
    echo -e "${NODE} ${GREEN}Updating system and installing required packages...${NC}"
    show_separator
    sudo apt update && sudo apt upgrade -y || handle_error "Failed to update the system."

    for pkg in curl git make jq build-essential gcc unzip wget lz4 aria2 pv; do
        check_installed "$pkg"
    done
}

# Function to check if a package is installed
check_installed() {
    local PACKAGE=$1
    if ! dpkg -l | grep -q "^ii\s*${PACKAGE}\s"; then
        echo -e "${INSTALL} ${YELLOW}Installing $PACKAGE...${NC}"
        sudo apt install -y "$PACKAGE" || handle_error "Failed to install $PACKAGE."
        echo -e "${CHECKMARK} ${GREEN}$PACKAGE has been installed.${NC}"
    else
        echo -e "${CHECKMARK} ${GREEN}$PACKAGE is already installed.${NC}"
    fi
}

# Function to install Story-Geth
install_story_geth() {
    show_header
    echo -e "${NODE} ${GREEN}Installing Story-Geth...${NC}"
    show_separator

    wget -O story-geth.tar.gz "$STORY_GETH_URL" || handle_error "Failed to download Story-Geth."
    tar -xzvf story-geth.tar.gz || handle_error "Failed to extract Story-Geth."

    [ ! -d "$HOME/go/bin" ] && mkdir -p "$HOME/go/bin"
    if ! grep -q "$HOME/go/bin" "$HOME/.bash_profile"; then
        echo 'export PATH=$PATH:$HOME/go/bin' >> "$HOME/.bash_profile"
    fi

    cp geth-linux-amd64-$STORY_GETH_VERSION/geth "$HOME/go/bin/story-geth" || handle_error "Failed to move Story-Geth binary."
    source "$HOME/.bash_profile"
    story-geth version || handle_error "Failed to verify Story-Geth installation."
}

# Function to install Story
install_story() {
    show_header
    echo -e "${NODE} ${GREEN}Installing Story...${NC}"
    show_separator

    wget -O story.tar.gz "$STORY_URL" || handle_error "Failed to download Story."
    tar -xzvf story.tar.gz || handle_error "Failed to extract Story."

    cp story-linux-amd64-$STORY_VERSION/story "$HOME/go/bin/story" || handle_error "Failed to move Story binary."
    source "$HOME/.bash_profile"
    story version || handle_error "Failed to verify Story installation."
}

# Function to create systemd service files
create_service_files() {
    show_header
    echo -e "${INSTALL} ${GREEN}Creating service files...${NC}"
    show_separator

    # Story-Geth Service File
    sudo tee /etc/systemd/system/story-geth.service > /dev/null <<EOF
[Unit]
Description=Story Geth Client
After=network.target

[Service]
User=$(whoami)
ExecStart=$HOME/go/bin/story-geth --iliad --syncmode full
Restart=on-failure
RestartSec=3
LimitNOFILE=4096

[Install]
WantedBy=multi-user.target
EOF

    # Story Service File
    sudo tee /etc/systemd/system/story.service > /dev/null <<EOF
[Unit]
Description=Story Client
After=network.target story-geth.service

[Service]
User=$(whoami)
ExecStart=$HOME/go/bin/story --config /etc/story/config.json
Restart=on-failure
RestartSec=3
LimitNOFILE=4096

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl daemon-reload || handle_error "Failed to reload systemd."
    sudo systemctl enable story-geth story || handle_error "Failed to enable services."
    sudo systemctl start story-geth story || handle_error "Failed to start services."
}

# Function to uninstall Story node
uninstall_story_node() {
    show_header
    echo -e "${ERROR} ${RED}Uninstalling Story Node...${NC}"
    show_separator

    sudo systemctl stop story story-geth
    sudo systemctl disable story story-geth
    sudo rm -f /etc/systemd/system/story.service /etc/systemd/system/story-geth.service
    sudo systemctl daemon-reload

    rm -f "$HOME/go/bin/story" "$HOME/go/bin/story-geth"
    echo -e "${CHECKMARK} ${GREEN}Story Node has been uninstalled.${NC}"
}

# Function to update Story node
update_story_node() {
    show_header
    echo -e "${PROGRESS} ${YELLOW}Updating Story Node...${NC}"
    show_separator

    uninstall_story_node
    install_story_geth
    install_story
    create_service_files
    echo -e "${SUCCESS} ${GREEN}Story Node has been updated to the latest version.${NC}"
}

# Main menu with dynamic buttons
main_menu() {
    while true; do
        show_header

        if is_node_installed; then
            if is_node_running; then
                echo -e "${NODE} ${GREEN}Story Protocol Node is installed and running.${NC}"
                echo -e "1. Stop Node ${ERROR}"
                echo -e "2. View Logs ${INFO}"
                echo -e "3. Check Node Status ${INFO}"
                echo -e "4. Update Node ${PROGRESS}"
                echo -e "5. Uninstall Node ${ERROR}"
            else
                echo -e "${NODE} ${YELLOW}Story Protocol Node is installed but not running.${NC}"
                echo -e "1. Start Node ${CHECKMARK}"
                echo -e "2. View Logs ${INFO}"
                echo -e "3. Check Node Status ${INFO}"
                echo -e "4. Update Node ${PROGRESS}"
                echo -e "5. Uninstall Node ${ERROR}"
            fi
        else
            echo -e "${NODE} ${RED}Story Protocol Node is not installed.${NC}"
            echo -e "1. Install Node ${INSTALL}"
        fi

        echo -e "0. Exit ${ERROR}"
        show_separator
        read -p "Choose an option: " option

        case $option in
            1)
                if is_node_installed; then
                    if is_node_running; then
                        sudo systemctl stop story story-geth || handle_error "Failed to stop services."
                        echo -e "${CHECKMARK} ${GREEN}Story Protocol Node has been stopped.${NC}"
                    else
                        start_node
                    fi
                else
                    check_system_resources
                    install_packages
                    install_story_geth
                    install_story
                    create_service_files
                fi
                ;;
            2) view_logs ;;
            3) check_node_status ;;
            4) update_story_node ;;
            5) uninstall_story_node ;;
            0) exit 0 ;;
            *) echo -e "${ERROR} ${RED}Invalid choice!${NC}" ;;
        esac
        read -p "Press Enter to continue..."
    done
}

# Function to check if the node is installed
is_node_installed() {
    if [ -f "/etc/systemd/system/story-geth.service" ] && [ -f "/etc/systemd/system/story.service" ]; then
        return 0
    else
        return 1
    fi
}

# Function to check if the node is running
is_node_running() {
    if systemctl is-active --quiet story-geth && systemctl is-active --quiet story; then
        return 0
    else
        return 1
    fi
}

# Function to view logs
view_logs() {
    show_header
    echo -e "${INFO} ${YELLOW}Showing Story Protocol Node Logs...${NC}"
    sudo journalctl -u story -u story-geth --no-pager -n 100
}

# Function to check node status
check_node_status() {
    show_header
    echo -e "${INFO} ${YELLOW}Checking Story Protocol Node Status...${NC}"
    systemctl status story story-geth
}

# Function to start the node
start_node() {
    sudo systemctl start story story-geth || handle_error "Failed to start services."
    echo -e "${CHECKMARK} ${GREEN}Story Protocol Node has been started.${NC}"
}

# Start main menu
main_menu