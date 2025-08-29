# Divortio Audio - mutterToButter

---
Churn your muttered recordings into Butter...Audio & Recording post-processing scripts designed to clean, normalize, and re-master recordings of speech in the most challenging of environments. 

## Overview

 **Divortio - mutterToButter** is a command-line workflow designed to rescue audio captured in suboptimal conditions. 
 It automates the entire restoration process, from initial cleanup to final mastering, using a resilient and auditable workflow. By default, it applies a full suite of mastering and polishing filters to achieve the best possible quality.

### Goals

- **Clarity:** Isolate speech from noise and artifacts.
- **Consistency:** Normalize perceived loudness to professional standards.
- **Efficiency:** Process multi-hour files in parallel to maximize speed.
- **Resilience:** Automatically resume interrupted jobs without losing progress.
- **Auditability:** Provide detailed logs for every run with full transparency.

## Requirements

- **System:** `bash`, `ffmpeg`, `ffprobe`, `jq`, `bc`, `realpath`, `stat`
- **AI Extension (Optional):** `python3`, `pip`, and the `demucs` package.

## Installation

1. Clone the repository:
   ```bash
   git clone [https://github.com/divortio/divortio-mutterToButter.git](https://github.com/divortio/divortio-mutterToButter.git)
   cd divortio-mutterToButter
   ```

2. Make all scripts executable:
   ```bash
   chmod +x mutterToButter.sh mutterToButterDir.sh lib/*.sh installers/*.sh
   ```

3. Run the core installer for your system. For example, on Debian/Ubuntu:
   ```bash
   sudo ./installers/install_core_deps.sh
   ```
   For AI features, see the "Optional AI Extension (Demucs)" section below.

## Usage

The primary script is `mutterToButter.sh` for single files and `mutterToButterDir.sh` for directories. All standard
enhancements are enabled by default.

```bash
# Example 1: Process a single file with default (high quality) settings.
./mutterToButter.sh -i ./audio/recording.m4a -o ./processed/recording.mp3

# Example 2: Process an entire directory with a lower quality output.
./mutterToButterDir.sh -i ./audio_to_process/ -o ./processed_audio/ --quality-low
```

## Command-Line API Reference

| Flag | Argument | Default | Description |
| :--- | :--- | :--- | :--- |
| `-i`, `--input` | `<path>` | **Required** | Path to the input audio file or directory. |
| `-o`, `--output` | `<path>` | `[input_dir]/[filename]_proc.mp3` | Full filepath for the final output MP3 or directory. |
| `-d`, `--demucs` | | Disabled | **AI Extension.** Enable AI-powered vocal separation. |
| `--quality-high` | | **Active** | Set output to HIGH quality VBR (~130 kbps, `-q:a 5`). |
| `--quality-medium` | | | Set output to MEDIUM quality VBR (~100 kbps, `-q:a 7`). |
| `--quality-low` | | | Set output to LOW quality VBR (~65 kbps, `-q:a 9`). |
| `--loudness` | `<LUFS>` | `-19` | Target perceived loudness in LUFS. |
| `-p`, `--parallel` | `<jobs>` | All CPU cores | Number of parallel jobs for chunk processing. |
| `--no-mastering` | | | **Disable** the default mastering pass. |
| `--no-gate` | | | **Disable** the default dynamic noise gate. |
| `--no-polish` | | | **Disable** the default final polish pass. |
| `--no-cleanup` | | | Prevent deletion of temporary files. |

---

## Optional AI Extension (Demucs)

For recordings with very challenging background noise (music, street noise, etc.), you can enable the AI-powered
separation feature.

**⚠️ Warning:** This extension requires installing the `demucs` Python library and its dependencies, including PyTorch.
This will download **over 2 GB** of files and will significantly increase processing time and memory usage.

### AI Extension Installation

After running the core installer, run the Demucs installer for your system:

```bash
# On Debian/Ubuntu
sudo ./installers/install_demucs_extension.sh
```

### AI Extension Usage

To use the feature, add the `-d` or `--demucs` flag to your command:

```bash
# Process a single file using the AI extension
./mutterToButter.sh -i ./noisy_recording.wav -o ./processed/clean.mp3 -d
```

### AI Docker Instructions

The project provides two Dockerfiles to separate the lightweight core tool from the heavy AI extension.

1. **Build the Base Image (`:base`)**
   This image is small (~200MB) and contains all core features.
   ```bash
   docker build -t divortio-mutterToButter:base -f ./docker/Dockerfile .
   ```

2. **Build the AI Image (`:ai`)**
   This image uses the `:base` version and adds the multi-gigabyte Demucs/PyTorch layer.
   ```bash
   docker build -t divortio-mutterToButter:ai -f ./docker/Dockerfile.ai .
   ```

3. **Run the AI Container**
   To use the AI features, simply run the `:ai` image.
   ```bash
   docker run -d --name mutterToButter-ai \
     -v /path/to/input:/input \
     -v /path/to/output:/output \
     -e "MASTERING_FLAGS=-d -m -g --polish" \
     divortio-mutterToButter:ai
   ```
   

