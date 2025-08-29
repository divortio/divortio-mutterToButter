#!/bin/sh

# chmod +x install_deps_linux_alpine.sh
# ./install_deps_linux_alpine.sh

################################################################################
#
# Dependency Installer for Alpine Linux
#
# This script uses the APK package manager to install dependencies.
# It should be run as the root user.
#
################################################################################

# --- Color Definitions ---
C_RESET='\033[0m'
C_GREEN='\033[0;32m'
C_YELLOW='\033[0;33m'
C_BOLD='\033[1m'

echo "${C_BOLD}Starting dependency installation for Alpine Linux...${C_RESET}"

# --- 1. Update Package Lists and Install Packages ---
echo "\n${C_YELLOW}Updating APK cache and installing packages...${C_RESET}"
# Alpine requires build-base for some Python packages
apk update
apk add ffmpeg jq bc coreutils build-base
# Install only the essential runtime packages.
# This list now excludes python3 and py3-pip.
apk update
apk add --no-cache ffmpeg jq bc coreutils inotify-tools

# --- 3. Final Verification ---
echo "\n${C_YELLOW}Verifying installations...${C_RESET}"
all_found=true
for cmd in ffmpeg ffprobe demucs bc jq realpath; do
  if ! command -v $cmd >/dev/null 2>&1; then
    echo "Error: Command '$cmd' not found after installation."
    all_found=false
  fi
done

if [ "$all_found" = true ]; then
  echo "\n${C_GREEN}${C_BOLD}✅ All dependencies have been successfully installed!${C_RESET}"
else
  echo "\n${C_RED}Some dependencies failed to install. Please check the output above for errors.${C_RESET}"
fi
