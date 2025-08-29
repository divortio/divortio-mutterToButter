#!/bin/bash

################################################################################
#
# Divortio Audio mutterToButter - Docker Save Script
#
# Saves the Docker image to a compressed .tar.gz archive suitable for storage.
#
################################################################################

# --- Configuration ---
IMAGE_NAME="divortio-mutterToButter"
IMAGE_TAG="lite"
OUTPUT_DIR="./docker"
OUTPUT_FILENAME="${IMAGE_NAME}-${IMAGE_TAG}.tar.gz"
OUTPUT_PATH="${OUTPUT_DIR}/${OUTPUT_FILENAME}"

echo "Saving image ${IMAGE_NAME}:${IMAGE_TAG} to ${OUTPUT_PATH}..."

# Create the output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# 'docker save' creates a tar archive, which we then pipe to 'gzip' for compression.
docker save "${IMAGE_NAME}:${IMAGE_TAG}" | gzip >"$OUTPUT_PATH"

if [ $? -eq 0 ]; then
  echo "✅ Docker image saved successfully."
  echo "File created: ${OUTPUT_PATH}"
else
  echo "❌ Error: Failed to save Docker image."
  exit 1
fi
