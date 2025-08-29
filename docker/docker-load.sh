#!/bin/bash

################################################################################
#
# Divortio Audio mutterToButter - Docker Load Script
#
# Loads a Docker image from a compressed .tar.gz archive.
#
################################################################################

# --- Configuration ---
IMAGE_ARCHIVE="./docker/divortio-mutterToButter-lite.tar.gz"

echo "Loading Docker image from ${IMAGE_ARCHIVE}..."

if [ ! -f "$IMAGE_ARCHIVE" ]; then
  echo "❌ Error: Image archive not found at ${IMAGE_ARCHIVE}"
  exit 1
fi

# 'gunzip' decompresses the archive, which is then piped to 'docker load'.
gunzip -c "$IMAGE_ARCHIVE" | docker load

if [ $? -eq 0 ]; then
  echo "✅ Docker image loaded successfully."
  echo "Run 'docker images' to see it in your library."
else
  echo "❌ Error: Failed to load Docker image."
  exit 1
fi
