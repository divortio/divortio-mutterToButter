#!/bin/bash

################################################################################
#
# Divortio Audio mutterToButter - Local Watcher Service
#
# Version: 1.0
#
# Description:
# This script runs on your local machine to provide an automated processing
# workflow. It first processes any existing files in an input directory,
# then continuously watches for new files and processes them as they arrive.
# Temporary artifacts are cleaned up after each successful process.
#
# Prerequisite: 'inotify-tools' must be installed.
# (On Debian/Ubuntu: sudo apt-get install inotify-tools)
# (On Fedora/RHEL: sudo dnf install inotify-tools)
# (On macOS with Homebrew: brew install inotify-tools)
# Make it executable:
#
#Bash
#
#chmod +x local-watcher.sh
#Run it from your terminal, providing the input and output directories, and any optional processing flags you want to use for every file.
#   ./local-watcher.sh -i /path/to/my/scans -o /path/to/my/processed_audio --quality-medium -m --polish
################################################################################

# --- Script Configuration & Color Definitions ---
C_RESET='\033[0m'
C_RED='\033[0;31m'
C_GREEN='\033[0;32m'
C_YELLOW='\033[0;33m'
C_CYAN='\033[0;36m'
C_BOLD='\033[1m'

# --- Usage and Help Function ---
usage() {
  echo -e "${C_BOLD}Usage:${C_RESET} $0 -i <input_dir> -o <output_dir> [processing_flags]"
  echo
  echo -e "  A local watch service for the Divortio Audio mutterToButter."
  echo
  echo -e "${C_BOLD}Required:${C_RESET}"
  echo -e "  -i, --input      <path>   Path to the local directory to watch for audio files."
  echo -e "  -o, --output     <path>   Path to the local directory to save processed files."
  echo
  echo -e "${C_BOLD}Optional Processing Flags (passed to the cleaner scripts):${C_RESET}"
  echo -e "  --quality-high, --quality-medium, --quality-low"
  echo -e "  -d, --demucs, --no-mastering, --no-gate, --no-polish, etc."
  echo
  echo -e "  -h, --help                Display this help message and exit."
  exit 1
}

# --- Argument Parsing ---
if [ "$#" -lt 4 ]; then
  usage
fi

input_dir=""
output_dir=""
passthrough_args=""

# Parse input and output directories specifically
while [[ $# -gt 0 ]]; do
  case $1 in
  -i | --input)
    input_dir="$2"
    shift
    shift
    ;;
  -o | --output)
    output_dir="$2"
    shift
    shift
    ;;
  -h | --help)
    usage
    ;;
  *)
    # Add all other arguments to the passthrough string
    passthrough_args+=" $1"
    shift
    ;;
  esac
done

# --- Validation and Path Setup ---
if [[ -z "$input_dir" || -z "$output_dir" ]]; then
  echo -e "${C_RED}Error: Input and output directories are required.${C_RESET}"
  usage
fi
if [ ! -d "$input_dir" ]; then
  echo -e "${C_RED}Error: Input directory not found at '$input_dir'${C_RESET}"
  exit 1
fi
if ! command -v inotifywait &>/dev/null; then
  echo -e "${C_RED}Error: 'inotifywait' is not installed. Please install 'inotify-tools'.${C_RESET}"
  exit 1
fi

# Standardize paths
input_dir=$(realpath "$input_dir")
output_dir=$(realpath -m "$output_dir")
mkdir -p "$output_dir"

echo ">>> Divortio Audio mutterToButter Local Watch Service is running..."
echo ">>> Watching for new files in: ${C_CYAN}$input_dir${C_RESET}"
echo ">>> Processed files will be saved to: ${C_CYAN}$output_dir${C_RESET}"
echo ">>> Using passthrough flags: ${C_YELLOW}$passthrough_args${C_RESET}"

# --- Stage 1: Process all existing files on startup using the batch script ---
echo
echo ">>> Performing initial scan of existing files..."
./mutterToButterDir.sh -i "$input_dir" -o "$output_dir" $passthrough_args

echo
echo ">>> Initial scan complete. Now watching for new files..."

# --- Stage 2: Watch for new files and process them individually ---
inotifywait -m -e create -e moved_to --format '%f' "$input_dir" | while read FILENAME; do
  echo "--------------------------------------------------------"
  echo ">>> Detected new file: $FILENAME"

  INPUT_FILE="$input_dir/$FILENAME"
  BASE_NAME="${FILENAME%.*}"
  OUTPUT_FILE="$output_dir/${BASE_NAME}.mp3"

  # Give the system a moment to ensure the file is fully written before processing
  sleep 2

  # Call the main 'mutterToButter.sh' script on the single new file.
  # We do NOT pass --no-cleanup, so temporary files will be removed on success.
  # The --force flag is added to prevent any interactive prompts.
  ./mutterToButter.sh -i "$INPUT_FILE" \
    -o "$OUTPUT_FILE" \
    $passthrough_args \
    --force

  if [ $? -eq 0 ]; then
    echo ">>> Successfully processed: $FILENAME"
  else
    echo ">>> ERROR: Failed to process $FILENAME"
  fi
  echo ">>> Waiting for next file..."
  echo "--------------------------------------------------------"
done
