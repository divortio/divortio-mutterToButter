#!/bin/bash

################################################################################
#
# Divortio Audio mutterToButter - Batch Processor
#
# Version: 1.2
#
# Description:
# This script processes an entire directory of audio files by calling the main
# 'mutterToButter.sh' script for each valid file. It is non-interactive, skips
# files that have already been processed, and includes a dry-run mode. It now
# accepts all relevant flags from the core processor.
#
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
  echo -e "${C_BOLD}Usage:${C_RESET} $0 -i <input_dir> [options]"
  echo
  echo -e "  A non-interactive batch processor for the Divortio Audio mutterToButter."
  echo
  echo -e "${C_BOLD}Required:${C_RESET}"
  echo -e "  -i, --input      <path>   Path to the directory containing audio files to process."
  echo
  echo -e "${C_BOLD}Batch Control Options:${C_RESET}"
  echo -e "  -o, --output     <path>   Path to the output directory. (Default: [input_dir]/out/)"
  echo -e "  --dry-run                 Show the processing plan without executing."
  echo
  echo -e "${C_BOLD}Processing Flags (passed to each 'mutterToButter.sh' process):${C_RESET}"
  echo -e "  --quality-high            Set output to HIGH quality VBR (~130 kbps, -q:a 5)."
  echo -e "  --quality-medium          Set output to MEDIUM quality VBR (~100 kbps, -q:a 7)."
  echo -e "  --quality-low             Set output to LOW quality VBR (~65 kbps, -q:a 9). (Default)"
  echo -e "  -d, --demucs              Enable AI vocal separation."
  echo -e "  -m, --mastering           Enable the final hyper-dynamic mastering pass."
  echo -e "  -g, --gate                Enable dynamic noise gating."
  echo -e "  -c, --clarity-boost       Enable high-frequency boost."
  echo -e "  -p, --parallel   <jobs>   Number of parallel chunks PER FILE."
  echo -e "  --force                   Force overwrite of existing files (if somehow found by the child script)."
  echo -e "  --no-cleanup              Prevent deletion of temporary chunk files for each processed audio."
  echo -e "  --log-file       <path>   Note: a unique log is already created for each file inside its temp dir."
  echo
  echo -e "  -h, --help                Display this help message and exit."
  exit 1
}

# --- Script Start & Argument Parsing ---
start_time=$(date +%s)
input_dir=""
output_dir=""
is_dry_run=false
passthrough_args="" # Variable to store flags to pass to the child script

while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
    -i|--input) input_dir="$2"; shift; shift ;;
    -o|--output) output_dir="$2"; shift; shift ;;
    --dry-run) is_dry_run=true; shift ;;

    # Passthrough Flags
    -d|--demucs) passthrough_args+=" $1"; shift ;;
    -m|--mastering) passthrough_args+=" $1"; shift ;;
    -g|--gate) passthrough_args+=" $1"; shift ;;
    -c|--clarity-boost) passthrough_args+=" $1"; shift ;;
    --quality-high) passthrough_args+=" $1"; shift ;;
    --quality-medium) passthrough_args+=" $1"; shift ;;
    --quality-low) passthrough_args+=" $1"; shift ;;
    --force) passthrough_args+=" $1"; shift ;;
    --no-cleanup) passthrough_args+=" $1"; shift ;;
    -p|--parallel) passthrough_args+=" $1 $2"; shift; shift ;;
    --log-file) passthrough_args+=" $1 '$2'"; shift; shift ;;

    -h|--help) usage ;;
    *) echo -e "${C_RED}Error: Unknown option '$1'${C_RESET}"; usage ;;
  esac
done

# --- Validation and Path Setup ---
if [[ -z "$input_dir" ]]; then echo -e "${C_RED}Error: Input directory is required.${C_RESET}"; usage; fi
if [ ! -d "$input_dir" ]; then echo -e "${C_RED}Error: Input directory not found at '$input_dir'${C_RESET}"; exit 1; fi

# Standardize paths
input_dir=$(realpath "$input_dir")
if [[ -z "$output_dir" ]]; then
    output_dir="$input_dir/out"
fi
output_dir=$(realpath -m "$output_dir")

# Create output directory first
echo -e "${C_YELLOW}Ensuring output directory exists: ${C_CYAN}$output_dir${C_RESET}"
mkdir -p "$output_dir"
echo

# --- File Discovery and Planning ---
echo -e "${C_CYAN}--- Stage 1: Scanning for Audio Files ---${C_RESET}"

all_audio_files=()
while IFS= read -r file; do
    all_audio_files+=("$file")
done < <(find "$input_dir" -maxdepth 1 -type f -iregex '.*\.\(mp3\|wav\|m4a\|flac\|aac\|ogg\)')

total_found=${#all_audio_files[@]}
echo "Found $total_found potential audio file(s) in the input directory."

files_to_process=()
files_to_skip=()

for input_file in "${all_audio_files[@]}"; do
    filename=$(basename "$input_file")
    base_name="${filename%.*}"
    expected_output_file="$output_dir/${base_name}.mp3"

    if [ -f "$expected_output_file" ]; then
        files_to_skip+=("$input_file")
    else
        files_to_process+=("$input_file")
    fi
done

total_to_process=${#files_to_process[@]}
total_to_skip=${#files_to_skip[@]}

# --- User Summary ---
echo
echo -e "${C_BOLD}--- Batch Processing Plan ---${C_RESET}"
echo -e "Total audio files found:\t\t${C_YELLOW}$total_found${C_RESET}"
echo -e "Files already processed (skip):\t${C_CYAN}$total_to_skip${C_RESET}"
echo -e "Files to be processed:\t\t${C_GREEN}$total_to_process${C_RESET}"
echo "---------------------------------"
echo

# --- Dry Run Check ---
if [ "$is_dry_run" = true ]; then
    echo -e "${C_YELLOW}Dry run enabled. The following files would be processed:${C_RESET}"
    for file in "${files_to_process[@]}"; do
        echo "  - $(basename "$file")"
    done
    echo
    echo "Exiting without processing."
    exit 0
fi

if [ $total_to_process -eq 0 ]; then
    echo "No new files to process. Exiting."
    exit 0
fi

# --- Processing Loop ---
echo
echo -e "${C_CYAN}--- Stage 2: Starting Batch Processing ---${C_RESET}"
processed_count=0
for input_file in "${files_to_process[@]}"; do
    processed_count=$((processed_count + 1))
    filename=$(basename "$input_file")
    base_name="${filename%.*}"
    output_file="$output_dir/${base_name}.mp3"

    echo
    echo -e "${C_BOLD}----------------------------------------------------------------------${C_RESET}"
    echo -e "${C_YELLOW}Processing file $processed_count of $total_to_process: ${C_CYAN}$filename${C_RESET}"
    echo -e "${C_BOLD}----------------------------------------------------------------------${C_RESET}"

    # Construct the command to call the main cleaner script
    ./mutterToButter.sh -i "$input_file" -o "$output_file" $passthrough_args

    if [ $? -ne 0 ]; then
        echo -e "${C_RED}An error occurred while processing $filename. Stopping batch process.${C_RESET}"
        exit 1
    fi
done

# --- Final Summary Report ---
end_time=$(date +s)
total_seconds=$((end_time - start_time))
processing_time_formatted=$(date -u -d @"$total_seconds" +'%M minutes and %S seconds')

echo
echo -e "${C_GREEN}${C_BOLD}========================================${C_RESET}"
echo -e "${C_GREEN}${C_BOLD}        Batch Process Complete!         ${C_RESET}"
echo -e "${C_GREEN}${C_BOLD}========================================${C_RESET}"
echo -e "${C_CYAN}Successfully processed:${C_RESET}\t $total_to_process file(s)"
echo -e "${C_CYAN}Total time taken:${C_RESET}\t\t $processing_time_formatted"
echo -e "${C_CYAN}Output located in:${C_RESET}\t\t $output_dir"
echo -e "${C_GREEN}${C_BOLD}========================================${C_RESET}"