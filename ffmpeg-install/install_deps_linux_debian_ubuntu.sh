#!/bin/bash
# chmod +x install_deps_linux_debian_ubuntu.sh
# sudo ./install_deps_linux_debian_ubuntu.sh
################################################################################
#
# Dependency Installer for Linux (Debian/Ubuntu)
#
# This script installs all necessary tools for the audio processing workflow
# using the APT package manager and pip for Python packages.
# It should be run with sudo privileges.
#
################################################################################

# --- Color Definitions ---
C_RESET='\033[0m'
C_GREEN='\033[0;32m'
C_YELLOW='\033[0;33m'
C_BOLD='\033[1m'

# Ensure the script is run as root/sudo
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script with sudo: sudo ./install_deps_linux.sh"
  exit 1
fi

echo -e "${C_BOLD}Starting dependency installation for Linux (Debian/Ubuntu based)...${C_RESET}"

# --- 1. Update Package Lists ---
echo -e "\n${C_YELLOW}Updating package lists...${C_RESET}"
apt-get update

# --- 2. Install System Packages with APT ---
echo -e "\n${C_YELLOW}Installing system packages (ffmpeg, jq, bc, python3-pip)...${C_RESET}"
# The '-y' flag automatically answers 'yes' to installation prompts.
# 'realpath' is part of the 'coreutils' package, which is almost always pre-installed.
apt-get install -y ffmpeg jq bc

# --- 4. Final Verification ---
echo -e "\n${C_YELLOW}Verifying installations...${C_RESET}"
all_found=true
for cmd in ffmpeg ffprobe demucs bc jq realpath; do
  if ! command -v $cmd &>/dev/null; then
    echo -e "Error: Command '$cmd' not found after installation."
    all_found=false
  fi
done

if [ "$all_found" = true ]; then
  echo -e "\n${C_GREEN}${C_BOLD}✅ All dependencies have been successfully installed!${C_RESET}"
else
  echo -e "\n${C_RED}Some dependencies failed to install. Please check the output above for errors.${C_RESET}"
fi

echo -e "\n${C_BOLD}Note for other Linux distributions:${C_RESET}"
echo "If you are using Fedora/CentOS/RHEL, the equivalent command for step 2 would be:"
echo "sudo dnf install -y ffmpeg jq bc python3-pip"
