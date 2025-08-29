#!/bin/bash

################################################################################
#
# Dependency Installer for Arch Linux
#
# This script uses the Pacman package manager.
#
################################################################################

# Ensure the script is run as root/sudo
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script with sudo: sudo ./install_deps_arch.sh"
  exit 1
fi

echo "Starting dependency installation for Arch Linux based systems..."

# --- 1. Update System and Install Packages ---
echo "Updating system and installing packages..."
# '--noconfirm' automatically answers 'yes' to prompts.
pacman -Syu --noconfirm
pacman -S --noconfirm ffmpeg jq bc python-pip coreutils

# --- 2. Install Python Packages with pip ---
echo "Installing Python packages (demucs)..."
pip install -U demucs

# --- 3. Final Verification ---
echo "Verifying installations..."
# ... (Verification logic is the same as other scripts) ...
