#!/bin/bash

################################################################################
#
# Divortio Audio mutterToButter - Docker Build Script
#
# Builds the main application Docker image from the docker/Dockerfile.
#
################################################################################

# --- Configuration ---
IMAGE_NAME="divortio-mutterToButter"
IMAGE_TAG="full"

echo "Building Docker image: ${IMAGE_NAME}:${IMAGE_TAG}..."

# The '-f' flag points to our specific Dockerfile.
# The final '.' specifies the build context (the project's root directory).
docker build -t "${IMAGE_NAME}:${IMAGE_TAG}" -f ./docker/Dockerfile .

if [ $? -eq 0 ]; then
  echo "✅ Docker image built successfully."
else
  echo "❌ Error: Docker image build failed."
  exit 1
fi
