#!/bin/bash
# chmod +x install_deps_fedora.sh
# sudo ./install_deps_fedora.sh
################################################################################
#
# Dependency Installer for Fedora/RHEL/CentOS
#
# This script uses the DNF package manager (or YUM on older systems)
# to install all necessary tools for the audio processing workflow.
#
################################################################################

# --- Color Definitions ---
C_RESET='\033[0m'
C_GREEN='\033[0;32m'
C_YELLOW='\033[0;33m'
C_BOLD='\033[1m'

# Ensure the script is run as root/sudo
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script with sudo: sudo ./install_deps_fedora.sh"
  exit 1
fi

echo -e "${C_BOLD}Starting dependency installation for Fedora/RHEL based systems...${C_RESET}"

# Determine package manager
if command -v dnf &>/dev/null; then
  PKG_MANAGER="dnf"
else
  PKG_MANAGER="yum"
fi
echo "Using '$PKG_MANAGER' package manager."

# --- 1. Install System Packages ---
# Note: You may need to enable the EPEL repository on RHEL/CentOS for ffmpeg.
# On modern Fedora, RPM Fusion repository is often needed for ffmpeg.
echo -e "\n${C_YELLOW}Installing system packages (ffmpeg, jq, bc, python3-pip)...${C_RESET}"
$PKG_MANAGER install -y ffmpeg jq bc python3-pip coreutils

# --- 2. Install Python Packages with pip ---
echo -e "\n${C_YELLOW}Installing Python packages (demucs)...${C_RESET}"
pip3 install -U demucs

# --- 3. Final Verification ---
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
