#!/bin/bash

################################################################################
#
# Divortio Audio mutterToButter
#
# Version: 2.5 - Final Optimized
#
# Description:
# This is the main user-facing script. It manages a resilient, auditable, and
# parallel workflow, passing all processing instructions to the optimized
# single-pass engine.
#
# # ...is equivalent to this.
# This simple command...
# ./mutterToButter.sh -i input.wav -o output.mp3
# # ...is equivalent to this.
#./mutterToButter.sh -i input.wav -o output.mp3 -m -g --polish --quality-high --loudness -19
# # Run without the polish pass
#./mutterToButter.sh -i input.wav -o output.mp3 --no-polish
################################################################################

# --- Script Configuration & Color Definitions ---
C_RESET='\033[0m'
C_RED='\033[0;31m'
C_GREEN='\033[0;32m'
C_YELLOW='\033[0;33m'
C_CYAN='\033[0;36m'
C_BOLD='\033[1m'

# --- Global Variables for Cleanup Trap ---
SHOULD_CLEANUP=true
temp_dir=""
concat_list_file=""
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)

# --- Cleanup Function and Exit Trap ---
cleanup() {
  if [ "$SHOULD_CLEANUP" = true ]; then
    echo -e "${C_YELLOW}\nCleaning up temporary files...${C_RESET}"
    if [ -d "$temp_dir" ]; then rm -r "$temp_dir"; fi
    if [ -f "$concat_list_file" ]; then rm "$concat_list_file"; fi
    echo -e "${C_GREEN}Cleanup complete.${C_RESET}"
  else
    echo -e "${C_YELLOW}\n--no-cleanup flag set or error occurred. Temporary files preserved in: $temp_dir${C_RESET}"
  fi
}
trap cleanup EXIT

# --- Usage and Help Function ---
usage() {
  echo -e "${C_BOLD}Usage:${C_RESET} $0 -i <input_file> [options]"
  echo
  echo -e "${C_BOLD}Required:${C_RESET}"
  echo -e "  -i, --input      <path>   Path to the input audio file."
  echo
  echo -e "${C_BOLD}Output & Quality Options:${C_RESET}"
  echo -e "  -o, --output     <path>   Full filepath for the final output MP3. (Default: [input_dir]/[filename]_proc.mp3)"
  echo -e "  --loudness       <LUFS>   Target loudness in LUFS. (Default: -19)"
  echo -e "  --quality-high            Set output to HIGH quality VBR (~130 kbps, -q:a 5). (Default)"
  echo -e "  --quality-medium          Set output to MEDIUM quality VBR (~100 kbps, -q:a 7)."
  echo -e "  --quality-low             Set output to LOW quality VBR (~65 kbps, -q:a 9)."
  echo
  echo -e "${C_BOLD}Processing Control:${C_RESET}"
  echo -e "  -d, --demucs              AI Extension. Enable AI-powered vocal separation."
  echo -e "  --no-mastering            Disable the default mastering pass (dynamic EQ, limiter)."
  echo -e "  --no-gate                 Disable the default dynamic noise gate."
  echo -e "  --no-polish               Disable the default final polish pass (tonal EQ, soft clip)."
  echo
  echo -e "${C_BOLD}Other Options:${C_RESET}"
  echo -e "  --temp-dir       <path>   Directory for temporary chunks. (Default: /tmp/[input_file_md5])"
  echo -e "  --log-file       <path>   Full filepath for the processing receipt log."
  echo -e "  --no-cleanup              Flag to prevent deletion of temporary files."
  echo -e "  --force                   Force overwrite of the output file without prompting."
  echo -e "  --dry-run                 Show all commands that would be run without executing them."
  echo -e "  -p, --parallel   <jobs>   Number of parallel jobs. (Default: all CPU cores; 0 or 1 for serial)"
  echo -e "  -h, --help                Display this help message and exit."
  exit 1
}

# --- Helper Functions ---
get_file_md5() {
  if command -v md5sum &>/dev/null; then
    md5sum "$1" | awk '{print $1}'
  elif command -v md5 &>/dev/null; then
    md5 -q "$1"
  else
    echo "(md5 utility not found)"
  fi
}

# --- Script Start & Argument Parsing ---
start_time=$(date +%s)
input_file=""
output_file_path=""
log_file_path=""
passthrough_args=""
max_jobs=$(getconf _NPROCESSORS_ONLN)
force_overwrite=false
is_dry_run=false
output_bitrate_kbps="~130" # Default kbps string for metadata

# Set processing flags to be enabled by default
run_mastering_default=true
run_gate_default=true
run_polish_default=true

while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
  -i | --input)
    input_file="$2"
    shift
    shift
    ;;
  -o | --output)
    output_file_path="$2"
    shift
    shift
    ;;
  --temp-dir)
    temp_dir="$2"
    shift
    shift
    ;;
  --log-file)
    log_file_path="$2"
    shift
    shift
    ;;
  --no-cleanup)
    SHOULD_CLEANUP=false
    shift
    ;;
  --force)
    force_overwrite=true
    shift
    ;;
  --dry-run)
    is_dry_run=true
    shift
    ;;
  -p | --parallel)
    max_jobs="$2"
    shift
    shift
    ;;
  -d | --demucs)
    passthrough_args+=" -d"
    shift
    ;;
  --no-mastering)
    run_mastering_default=false
    shift
    ;;
  --no-gate)
    run_gate_default=false
    shift
    ;;
  --no-polish)
    run_polish_default=false
    shift
    ;;
  --loudness)
    passthrough_args+=" --loudness $2"
    shift
    shift
    ;;
  --quality-high)
    passthrough_args+=" --quality-high"
    output_bitrate_kbps="~130"
    shift
    ;;
  --quality-medium)
    passthrough_args+=" --quality-medium"
    output_bitrate_kbps="~100"
    shift
    ;;
  --quality-low)
    passthrough_args+=" --quality-low"
    output_bitrate_kbps="~65"
    shift
    ;;
  -h | --help) usage ;;
  *)
    echo -e "${C_RED}Error: Unknown option '$1'${C_RESET}"
    usage
    ;;
  esac
done

# --- Add default flags to passthrough_args if they weren't disabled ---
if [ "$run_mastering_default" = true ]; then passthrough_args+=" -m"; fi
if [ "$run_gate_default" = true ]; then passthrough_args+=" -g"; fi
if [ "$run_polish_default" = true ]; then passthrough_args+=" --polish"; fi
# If no quality flag was provided, default to high
if ! [[ $passthrough_args =~ --quality- ]]; then
  passthrough_args+=" --quality-high"
fi

# --- Validation, Path Standardization, and Hashing ---
if [[ -z "$input_file" ]]; then
  echo -e "${C_RED}Error: Input file is required.${C_RESET}"
  usage
fi
if [ ! -f "$input_file" ]; then
  echo -e "${C_RED}Error: Input file not found at '$input_file'${C_RESET}"
  exit 1
fi
if [ ! -f "$SCRIPT_DIR/lib/_process-chunk.sh" ]; then
  echo -e "${C_RED}Error: Worker script 'lib/_process-chunk.sh' not found.${C_RESET}"
  exit 1
fi
for cmd in ffmpeg ffprobe demucs bc jq realpath stat; do if ! command -v $cmd &>/dev/null; then
  echo -e "${C_RED}Error: Required command '$cmd' is not found. Please run an installer.${C_RESET}"
  exit 1
fi; done

input_file_abs=$(realpath "$input_file")
input_file_md5=$(get_file_md5 "$input_file_abs")
base_name=$(basename "${input_file%.*}")
timestamp=$(date -u +%Y-%m-%dT%H%M%SZ)

if [[ -z "$temp_dir" ]]; then temp_dir="/tmp/$input_file_md5"; fi
if [[ -z "$output_file_path" ]]; then output_file_path="$(dirname "$input_file_abs")/${base_name}_proc.mp3"; fi
if [[ -z "$log_file_path" ]]; then log_file_path="$temp_dir/processing_receipt_${timestamp}.log"; fi
output_file_path=$(realpath -m "$output_file_path")
temp_dir=$(realpath -m "$temp_dir")
log_file_path=$(realpath -m "$log_file_path")
mkdir -p "$temp_dir" "$(dirname "$output_file_path")" "$(dirname "$log_file_path")"

# --- Interactive Confirmation / Safety Check ---
if [ "$force_overwrite" = false ] && [ -f "$output_file_path" ] && [ "$is_dry_run" = false ]; then
  echo -e "${C_YELLOW}WARNING: Output file already exists:${C_RESET} $output_file_path"
  read -p "Do you want to overwrite it? (y/n): " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Operation cancelled by user."
    trap - EXIT
    exit 1
  fi
fi

# --- Metadata Preparation ---
echo -e "${C_YELLOW}Gathering metadata for MP3 tags...${C_RESET}"
duration_sec=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$input_file_abs")
duration_formatted=$(date -u -d @"${duration_sec%.*}" +'%Hh %Mm %Ss')
creation_date_iso=$(stat -c %y "$input_file_abs" 2>/dev/null || stat -f %SB -t %Y-%m-%d "$input_file_abs")
creation_date_iso=$(echo "$creation_date_iso" | awk '{print $1}')

mp3_title="${base_name} - ${duration_formatted} - ${output_bitrate_kbps}kbps - ${timestamp} - MD5:${input_file_md5}"
mp3_artist="Divort.io - Audio mutterToButter"
mp3_album="$creation_date_iso"

passthrough_args+=" --mp3-title \"$mp3_title\" --mp3-artist \"$mp3_artist\" --mp3-album \"$mp3_album\" --mp3-date \"$creation_date_iso\""

# --- Stage 1: Split ---
echo -e "\n${C_CYAN}--- Stage 1: Splitting audio... ---${C_RESET}"
chunk_base_path="$temp_dir/chunk"
processed_chunks_dir="${temp_dir}/processed"
mkdir -p "$processed_chunks_dir"

if [ -z "$(ls -A "$temp_dir" 2>/dev/null | grep 'chunk_.*.wav')" ]; then
  split_command="ffmpeg -hide_banner -i \"$input_file_abs\" -f segment -segment_time 300 -c pcm_s16le \"${chunk_base_path}_%04d.wav\""
  if [ "$is_dry_run" = false ]; then
    eval $split_command || {
      echo "${C_RED}Error: Failed to split audio file.${C_RESET}"
      exit 1
    }
    if [ -z "$(ls -A "$temp_dir" | grep 'chunk_.*.wav')" ]; then
      echo -e "${C_RED}Error: Splitting produced no chunk files.${C_RESET}"
      exit 1
    fi
  else
    echo "[DRY-RUN] Would execute: $split_command"
  fi
else
  echo -e "${C_YELLOW}Chunks found, skipping split.${C_RESET}"
fi

# --- Stage 2: Process ---
echo -e "\n${C_CYAN}--- Stage 2: Processing chunks... ---${C_RESET}"
chunks=("$chunk_base_path"_*.wav)
if [[ "$max_jobs" -le 1 ]]; then echo -e "${C_YELLOW}Mode: Serial (1 job at a time)...${C_RESET}"; else echo -e "${C_YELLOW}Mode: Parallel (up to $max_jobs concurrent jobs)...${C_RESET}"; fi

for chunk_file in "${chunks[@]}"; do
  chunk_basename=$(basename "$chunk_file")
  status_file="$processed_chunks_dir/${chunk_basename}.success"
  if [ -f "$status_file" ]; then
    echo -e "${C_GREEN}Skipping already completed chunk: $chunk_basename${C_RESET}"
    continue
  fi

  failure_file="$processed_chunks_dir/${chunk_basename}.failure"
  rm -f "$failure_file"

  (
    chunk_start_time=$(date +%s)
    chunk_log_file="$processed_chunks_dir/$chunk_basename.log"
    chunk_passthrough_args="$passthrough_args --log-file \"$chunk_log_file\""
    process_command="\"$SCRIPT_DIR/lib/_process-chunk.sh\" -i \"$chunk_file\" -o \"$processed_chunks_dir\" $chunk_passthrough_args"

    if [ "$is_dry_run" = true ]; then
      echo "[DRY-RUN] Would execute for $chunk_basename"
      touch "$status_file"
    else
      if eval $process_command; then
        touch "$status_file"
        chunk_end_time=$(date +%s)
        duration=$((chunk_end_time - chunk_start_time))
        echo -e "${C_GREEN}[SUCCESS]${C_RESET} Processed ${chunk_basename} in ${duration}s"
      else
        touch "$processed_chunks_dir/${chunk_basename}.failure"
        echo -e "${C_RED}[FAILURE]${C_RESET} Failed to process ${chunk_basename}. See details in ${chunk_log_file}"
      fi
    fi
  ) &

  if [[ "$max_jobs" -gt 1 ]] && [[ $(jobs -p | wc -l) -ge $max_jobs ]]; then wait -n; fi
done
wait
echo -e "${C_GREEN}All processing jobs have finished.${C_RESET}"

# --- Stage 2b: Verify Success ---
if find "$processed_chunks_dir" -name "*.failure" -print -quit | grep -q .; then
  echo -e "\n${C_RED}ERROR: One or more chunks failed. Artifacts left for debugging in $temp_dir${C_RESET}"
  SHOULD_CLEANUP=false
  exit 1
fi
if [ "$is_dry_run" = true ]; then
  echo "Dry run complete. Exiting."
  trap - EXIT
  cleanup
  exit 0
fi

# --- Stage 3: Reassemble ---
echo -e "\n${C_CYAN}--- Stage 3: Assembling final audio & log... ---${C_RESET}"
concat_list_file="$temp_dir/concat_list.txt"
find "$processed_chunks_dir" -type f -name '*.mp3' | sort | while read -r f; do echo "file '$f'" >>"$concat_list_file"; done
if [ ! -s "$concat_list_file" ]; then
  echo -e "${C_RED}Error: No processed files found to reassemble.${C_RESET}"
  SHOULD_CLEANUP=false
  exit 1
fi

# Determine the final bitrate flag to use for reassembly based on passthrough_args
final_bitrate_flag="-q:a 5" # Default to high quality
if [[ $passthrough_args =~ --quality-medium ]]; then final_bitrate_flag="-q:a 7"; fi
if [[ $passthrough_args =~ --quality-low ]]; then final_bitrate_flag="-q:a 9"; fi

reassemble_command="ffmpeg -hide_banner -f concat -safe 0 -i \"$concat_list_file\" -c:a libmp3lame $final_bitrate_flag \"$output_file_path\""
eval $reassemble_command || {
  echo "${C_RED}Error: Failed to reassemble chunks.${C_RESET}"
  SHOULD_CLEANUP=false
  exit 1
}
echo -e "${C_GREEN}Final audio file created successfully.${C_RESET}"

# --- Final Summary Report & Log Assembly ---
echo -e "\n${C_YELLOW}Assembling final processing receipt...${C_RESET}"
# Start the main log file with summary info
log_content=""
log_content+="Divortio Audio mutterToButter - Processing Receipt\n"
log_content+="============================================\n"
log_content+="Run Date: $(date)\n"
log_content+="Input File: $input_file_abs\n"
log_content+="Input MD5: $input_file_md5\n"
log_content+="Final Output: $output_file_path\n"
log_content+="============================================\n\n"
echo -e "$log_content" >"$log_file_path"

# Append all individual chunk logs into the main log
find "$processed_chunks_dir" -name "*.log" | sort | xargs -I {} cat {} >>"$log_file_path"

# Calculate final timings and metrics
end_time=$(date +%s)
total_seconds=$((end_time - start_time))
processing_time_formatted=$(date -u -d @"$total_seconds" +'%M minutes and %S seconds')
audio_duration_formatted=$(date -u -d @"${duration_sec%.*}" +'%H hours, %M minutes and %S seconds')

# Display the final summary report to the console
echo
echo -e "${C_GREEN}${C_BOLD}========================================${C_RESET}"
echo -e "${C_GREEN}${C_BOLD}      Processing Complete!              ${C_RESET}"
echo -e "${C_GREEN}${C_BOLD}========================================${C_RESET}"
echo -e "${C_CYAN}Input File:${C_RESET}\t\t $input_file_abs"
echo -e "${C_CYAN}Final Audio File:${C_RESET}\t $output_file_path"
echo -e "${C_CYAN}Processing Log:${C_RESET}\t\t $log_file_path"
echo -e "---"
echo -e "${C_CYAN}Input Audio Duration:${C_RESET}\t $audio_duration_formatted"
echo -e "${C_CYAN}Total Processing Time:${C_RESET}\t $processing_time_formatted"
if (($(echo "$duration_sec > 0" | bc -l))); then
  processing_factor=$(echo "scale=2; $total_seconds / $duration_sec" | bc)
  echo -e "${C_CYAN}Performance Metric:${C_RESET}\t ${processing_factor}x (Script Time / Audio Time)"
fi
echo -e "${C_GREEN}${C_BOLD}========================================${C_RESET}"
