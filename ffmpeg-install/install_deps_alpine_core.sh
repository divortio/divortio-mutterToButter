#!/bin/sh

################################################################################
#
# Core Dependency Installer for Alpine Linux
#
# Version: 1.1
#
# This script uses the APK package manager to install only the essential,
# lightweight dependencies for the Divortio Audio mutterToButter. It intentionally
# excludes Python, as it is only required for the Demucs AI extension.
#
################################################################################

# --- Color Definitions (limited for basic sh compatibility) ---
C_GREEN='\033[0;32m'
C_YELLOW='\033[0;33m'
C_RED='\033[0;31m'
C_BOLD='\033[1m'
C_RESET='\033[0m'

echo "${C_BOLD}Starting CORE dependency installation for Alpine Linux...${C_RESET}"

# --- 1. Update Package Lists and Install Packages ---
echo "\n${C_YELLOW}Updating APK cache and installing core packages...${C_RESET}"

# Install only the essential runtime packages.
# This list now excludes python3 and py3-pip.
apk update
apk add --no-cache ffmpeg jq bc coreutils inotify-tools

# --- 2. Final Verification ---
echo "\n${C_YELLOW}Verifying core installations...${C_RESET}"
all_found=true
for cmd in ffmpeg ffprobe jq bc realpath inotifywait; do
    if ! command -v $cmd > /dev/null 2>&1; then
        echo "${C_RED}Error: Command '$cmd' not found after installation.${C_RESET}"
        all_found=false
    fi
done

if [ "$all_found" = true ]; then
    echo "\n${C_GREEN}${C_BOLD}✅ Core dependencies have been successfully