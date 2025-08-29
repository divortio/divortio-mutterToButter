#!/bin/bash

################################################################################
#
# Divortio Audio mutterToButter - Watch and Process Service
#
# Version: 1.4 - Final Configurable Edition
#
# Description:
# This script is the entrypoint for the Docker container. It processes existing
# files on startup and then watches for new files. It is now configured with
# more flexible environment variables to pass any desired flags to the core
# processing engine.
#
################################################################################

# --- Configuration ---
INPUT_DIR="/input"
OUTPUT_DIR="/output"

# Read configuration from environment variables, with sensible defaults
# The default is now HIGH quality.
QUALITY_FLAG="--quality-${QUALITY_PRESET:-high}"
# Default processing now includes mastering, gating, and polish. Demucs (-d) is off by default.
PROCESSING_FLAGS="${PROCESSING_FLAGS:---no-demucs}" # Using a placeholder to avoid empty string issues
# Cleanup should always be disabled in the container to preserve state.
CLEANUP_FLAG="--no-cleanup"


echo ">>> Divortio Audio mutterToButter Watch Service is running..."
echo ">>> Watching for new files in: $INPUT_DIR"
echo ">>> --- Runtime Configuration ---"
echo "    Quality Preset: $QUALITY_FLAG"
echo "    Processing Flags: $PROCESSING_FLAGS"
echo "---------------------------------"

# --- Reusable Processing Function ---
process_single_file() {
    local full_path="$1"
    local filename=$(basename "$full_path")

    if [ ! -f "$full_path" ]; then return; fi

    echo "--------------------------------------------------------"
    echo ">>> Processing file: $filename"

    local base_name="${filename%.*}"
    local output_file="$OUTPUT_DIR/${base_name}.mp3"

    # Call the main 'mutterToButter.sh' script with flags from environment variables
    # The --force flag is always added to ensure non-interactive execution.
    ./mutterToButter.sh -i "$full_path" \
                     -o "$output_file" \
                     $QUALITY_FLAG \
                     $PROCESSING_FLAGS \
                     $CLEANUP_FLAG \
                     --force

    if [ $? -eq 0 ]; then
        echo ">>> Successfully processed: $filename"
    else
        echo ">>> ERROR: Failed to process $filename"
    fi
    echo "--------------------------------------------------------"
}

# --- Main Logic ---
# Stage 1: Process all existing files on startup using the batch script
# We'll use mutterToButterDir for a more robust initial scan
echo ">>> Performing initial scan of existing files..."
./mutterToButterDir.sh -i "$INPUT_DIR" -o "$OUTPUT_DIR" $QUALITY_FLAG $PROCESSING_FLAGS $CLEANUP_FLAG --force

# Stage 2: Watch for new files
echo ">>> Initial scan complete. Now watching for new files..."
inotifywait -m -e create -e moved_to --format '%f' "$INPUT_DIR" | while read FILENAME
do
    sleep 2 # Add a small delay to ensure the file is fully written
    process_single_file "$INPUT_DIR/$FILENAME"
    echo ">>> Waiting for next file..."
done