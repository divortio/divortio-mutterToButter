# Divortio Audio - mutterToButter

---
## Docker Guide


This directory contains the necessary files to build and run the Divortio Audio mutterToButter as a lightweight, automated
Docker container.

The container is designed to be a "set it and forget it" service. Once running, it will automatically process any audio
files you drop into a specified input folder.

## Prerequisites

- [Docker](https://www.docker.com/products/docker-desktop/) must be installed and running on your system.

## Building the Images

This project uses a two-image system to provide flexibility. You first build the small `lite` image, and then can
optionally build the larger `full` image which adds the AI features.

To build the images, navigate to the **root of the project directory** (the parent of this `docker/` folder) to use it
as the build context.

### 1. Build the Lightweight Base Image (`:lite`)

This image contains all the core processing tools without the heavy AI dependencies.

```bash
docker build -t divortio-mutterToButter:lite -f ./docker/Dockerfile .
```

### 2. Build the Full AI-Powered Image (`:full`) (Optional)

This image uses the `:lite` version as a base and adds the Demucs/PyTorch AI layer.

```bash
docker build -t divortio-mutterToButter:full -f ./docker/Dockerfile.demucs .
```

## Running the Container

The container is configured using environment variables (`-e`) and requires volume mounts (`-v`) to connect to your
local input and output folders.

### Example: Running the `:full` Image

```bash
# Example: Run the full AI version, but disable the gate and polish passes.
docker run -d \
  --name mutterToButter-ai \
  --restart always \
  -v /path/to/your/input/folder:/input \
  -v /path/to/your/output/folder:/output \
  -e "QUALITY_PRESET=high" \
  -e "PROCESSING_FLAGS=-d --no-gate --no-polish" \
  divortio-mutterToButter:ai
```

**Command Breakdown:**

- `docker run -d`: Runs the container in detached (background) mode.
- `--name mutterToButter`: Gives your container a friendly, predictable name.
- `--restart always`: Ensures the container will automatically restart if it ever stops.
- `-v ...:/input`: Mounts your local input folder to the `/input` directory inside the container. **Replace the path
  with your own.**
- `-v ...:/output`: Mounts your local output folder to the `/output` directory inside the container. **Replace the path
  with your own.**
- `-e ...`: Sets an environment variable to configure the script's behavior.

To run the lightweight version, simply change `divortio-mutterToButter:full` to `divortio-mutterToButter:lite`.

### Configuration via Environment Variables

| Variable          | Description                                                                     | Default                                | Example Alternative Values                               |
| ----------------- | ------------------------------------------------------------------------------- | -------------------------------------- | -------------------------------------------------------- |
| `QUALITY_PRESET`  | Sets the final MP3 quality.                                                     | `low`                                  | `medium`, `high`                                         |
| `MASTERING_FLAGS` | The mastering flags to pass to the script. The `:lite` image will ignore `-d`.   | `-m -g`                                | `"-m -g -c"` (enables clarity boost), `""` (disables all) |
| `CLEANUP_MODE`    | Determines if temporary chunk files are deleted. Should be `--no-cleanup` for this service. | `--no-cleanup`                         | `""` (enables cleanup, not recommended)                  |

## Accessing Logs

You can view the real-time processing log of the container at any time with the following command:

```bash
docker logs -f mutterToButter
```