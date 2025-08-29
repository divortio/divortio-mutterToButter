#!/bin/bash
# chmod +x install_deps_macos.sh
# ./install_deps_macos.sh

################################################################################
#
# Dependency Installer for macOS
#
# This script installs all necessary tools for the audio processing workflow
# using Homebrew for system packages and pip for Python packages.
#
################################################################################

# --- Color Definitions ---
C_RESET='\033[0m'
C_GREEN='\033[0;32m'
C_YELLOW='\033[0;33m'
C_BOLD='\033[1m'

echo -e "${C_BOLD}Starting dependency installation for macOS...${C_RESET}"

# --- 1. Install Homebrew (if not already installed) ---
if ! command -v brew &>/dev/null; then
  echo -e "${C_YELLOW}Homebrew not found. Installing Homebrew first...${C_RESET}"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  # Add Homebrew to PATH for the current session
  (
    echo
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"'
  ) >>~/.zprofile
  eval "$(/opt/homebrew/bin/brew shellenv)"
else
  echo -e "${C_GREEN}Homebrew is already installed.${C_RESET}"
fi

# --- 2. Install System Packages with Homebrew ---
echo -e "\n${C_YELLOW}Updating Homebrew and installing system packages (ffmpeg, jq, bc, python)...${C_RESET}"
# We install python to ensure we have a modern version and pip3.
# 'coreutils' provides 'realpath', which is needed by the orchestrator script.
brew update
brew install ffmpeg jq bc python coreutils

# --- 3. Install Python Packages with pip ---
echo -e "\n${C_YELLOW}Installing Python packages (demucs)...${C_RESET}"
# Use pip3 from the Homebrew-installed Python to install Demucs.
pip3 install -U demucs

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
