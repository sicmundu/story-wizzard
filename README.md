
# Story Protocol Node Installation Wizard

![Story Protocol Logo](https://logowik.com/content/uploads/images/story-protocol8889.logowik.com.webp)

This is an automated installation script for setting up a Story Protocol node, which simplifies the entire process of downloading, configuring, and running the Story Protocol and Story-Geth clients. The script includes error handling, system checks, and an intuitive menu for node management.

## Features
- Automated installation of Story-Geth and Story Protocol clients.
- Dynamic menu that adapts based on whether the node is installed or running.
- Error handling and logging for easy troubleshooting.
- System resource check before installation (disk space, RAM).
- Snapshot installation for faster syncing.
- Simple and intuitive node management (start, stop, check status, view logs).

## Prerequisites
- Ubuntu-based system (Tested on Ubuntu 20.04)
- At least 200GB of free disk space
- At least 8GB of RAM

## Installation & Usage

### 1. Run the Installation Script Using curl
To directly download and run the script, execute the following command:
```bash
bash <(curl -s https://raw.githubusercontent.com/sicmundu/story-wizzard/main/story-wizzard.sh)
```

The script will guide you through the installation process and provide options to manage your node.

### 2. Menu Options
- **Install Node**: Installs Story Protocol and Story-Geth clients and sets up systemd services.
- **Start Node**: Starts both Story Protocol and Story-Geth services.
- **Stop Node**: Stops both services.
- **View Logs**: Shows live logs of Story-Geth.
- **Check Node Status**: Displays the current sync status of the node.

### 3. Logging
The script automatically logs all important actions and errors to a log file located at:
```bash
$HOME/story_protocol_install.log
```

### System Resource Check
Before installation, the script will check if your system has at least 10GB of free disk space and 4GB of RAM.

### Requirements
- `curl`, `git`, `jq`, and other dependencies will be automatically installed by the script.

### Updating the Script
To update the script with the latest version, simply pull the latest changes from the repository:
```bash
bash <(curl -s https://raw.githubusercontent.com/sicmundu/story-wizzard/main/story-wizzard.sh)
```

## License
This project is licensed under the MIT License.
