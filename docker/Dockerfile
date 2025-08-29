#
# Divortio Audio mutterToButter - Optimized Dockerfile
#
# This multi-stage Dockerfile compiles a custom, lightweight version of FFmpeg
# with only the specific audio features required by the application.
# The final image is significantly smaller and more secure.
#

# --- Stage 1: The "Builder" ---
# This stage downloads the FFmpeg source and compiles it.
# It's a large stage, but it gets discarded at the end.
FROM alpine:3.20 AS builder

# Define FFmpeg version for reproducible builds
ENV FFMPEG_VERSION 7.0

# Install all build-time dependencies
RUN apk add --no-cache \
    build-base \
    nasm \
    yasm \
    lame-dev \
    curl \
    tar

# Download and extract FFmpeg source code
WORKDIR /usr/src
RUN curl -sSL "https://ffmpeg.org/releases/ffmpeg-${FFMPEG_VERSION}.tar.bz2" | tar -xj --strip-components=1

# Configure and compile FFmpeg with a minimal set of features
# This is the most important step for optimization.
RUN ./configure \
    --prefix=/usr/local \
    --disable-everything \
    --enable-gpl \
    --enable-nonfree \
    --enable-libmp3lame \
    --enable-encoder=libmp3lame \
    --enable-encoder=pcm_s16le \
    --enable-decoder=aac \
    --enable-decoder=mp3 \
    --enable-decoder=pcm_s16le \
    --enable-demuxer=aac \
    --enable-demuxer=mov \
    --enable-demuxer=mp3 \
    --enable-demuxer=wav \
    --enable-muxer=mp3 \
    --enable-muxer=segment \
    --enable-protocol=file \
    --enable-filter=highpass \
    --enable-filter=afftdn \
    --enable-filter=deesser \
    --enable-filter=loudnorm \
    --enable-filter=agate \
    --enable-filter=adynamiceq \
    --enable-filter=alimiter \
    --enable-filter=superequalizer \
    --enable-filter=asoftclip \
    --enable-filter=astats \
    --enable-filter=ametadata \
    --disable-programs \
    --enable-ffmpeg \
    --enable-ffprobe \
    --disable-doc \
    --disable-htmlpages \
    --disable-manpages \
    --disable-podpages \
    --disable-txtpages \
    --disable-network \
    --disable-autodetect && \
    make -j$(nproc) && \
    make install


# --- Stage 2: The Final "Runner" Image ---
# This is the final, production-ready image. It's extremely small.
FROM alpine:3.20

WORKDIR /app

# Install only the essential RUNTIME dependencies.
# Note that 'lame-dev' is not needed, only 'lame-libs'.
RUN apk add --no-cache \
    lame-libs \
    jq \
    bc \
    coreutils \
    inotify-tools

# Copy our custom-compiled ffmpeg and ffprobe from the builder stage
COPY --from=builder /usr/local/bin/ffmpeg /usr/bin/
COPY --from=builder /usr/local/bin/ffprobe /usr/bin/

# Set default environment variables for configuration
ENV QUALITY_PRESET="low"
ENV MASTERING_FLAGS="-m -g"
ENV CLEANUP_MODE="--no-cleanup"

# Copy our application scripts from the project root
COPY ./bin/mutterToButter.sh .
COPY ./watch-and-process.sh .
COPY ./lib ./lib

# Make scripts executable
RUN chmod +x ./*.sh ./lib/*.sh

# Set the entrypoint to our watch script
ENTRYPOINT [ "./watch-and-process.sh" ]