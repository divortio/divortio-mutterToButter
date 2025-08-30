#
# Divortio Audio mutterToButter - APPLICATION IMAGE
#
# This Dockerfile builds the fast-changing application layer.
# It uses the pre-built base image and simply copies the latest
# scripts on top. This build should complete in seconds.
#
# Replace 'ghcr.io/your-username/divortio-muttertobutter:base' with your actual image path
FROM ghcr.io/your-username/divortio-muttertobutter:base

# The WORKDIR is inherited from the base image (/app)

# Set default environment variables for configuration
ENV QUALITY_PRESET="low"
ENV MASTERING_FLAGS="-m -g"
ENV CLEANUP_MODE="--no-cleanup"

# Copy your application scripts from the project root
# This is the layer that will change most often.
COPY ./src/mutterToButter.sh .
COPY ./docker/watch-and-process.sh .
COPY ./src/lib ./lib

# Make scripts executable
RUN chmod +x ./*.sh ./lib/*.sh

# Set the entrypoint to our watch script
ENTRYPOINT [ "./watch-and-process.sh" ]