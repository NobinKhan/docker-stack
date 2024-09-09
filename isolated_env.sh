#!/usr/bin/env sh

# Default values
IMAGE="ubuntu:24.04"
NAME="isolated-container"
VOLUME="/run/media/nobin/Files/project:/home/nonroot/project"
WORKDIR=""
HOSTDIR=""
CONTAINERDIR=""
HOSTNAME="isolated-env"
TEMP=""
USER="nonroot"

# Help function
show_help() {
    echo "Usage: $0 --image IMAGE --name NAME [--volume HOSTDIR:CONTAINERDIR] [--workdir WORKDIR] [--hostname HOSTNAME] [--temp]"
    echo
    echo "  --image         Specify the container image (default: ubuntu:24.04)"
    echo "  --name          Set the name of the container (default: isolated-container)"
    echo "  --volume        Mount a host directory into the container in format HOSTDIR:CONTAINERDIR"
    echo "  --workdir       Set the working directory inside the container"
    echo "  --hostname      Set the container hostname (default: isolated-env)"
    echo "  --temp          Automatically remove the container after it stops"
    echo "  --help          Display this help message"
}

# Parse command-line arguments
while [ $# -gt 0 ]; do
    case "$1" in
        --image)
            IMAGE="$2"
            shift 2
            ;;
        --name)
            NAME="$2"
            shift 2
            ;;
        --volume)
            VOLUME="$2"
            HOSTDIR=$(echo "$VOLUME" | cut -d: -f1)
            CONTAINERDIR=$(echo "$VOLUME" | cut -d: -f2)
            shift 2
            ;;
        --workdir)
            WORKDIR="$2"
            shift 2
            ;;
        --hostname)
            HOSTNAME="$2"
            shift 2
            ;;
        --temp)
            TEMP="--rm"
            shift 1
            ;;
        --help)
            show_help
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Check if the required arguments are provided
if [ -z "$IMAGE" ] || [ -z "$NAME" ]; then
    echo "Error: --image and --name are required."
    show_help
    exit 1
fi

# Ensure valid volume format if provided
if [ -n "$VOLUME" ] && ([ -z "$HOSTDIR" ] || [ -z "$CONTAINERDIR" ]); then
    echo "Error: Invalid --volume format. Use HOSTDIR:CONTAINERDIR."
    exit 1
fi

# Build Podman run command
CMD="podman run -it \
  --name $NAME \
  --userns=keep-id \
  --security-opt label=disable \
  --env-file /dev/null \
  --hostname $HOSTNAME \
  --user $USER $TEMP"

# If volume is specified, add it to the command
if [ -n "$VOLUME" ]; then
    CMD="$CMD --volume $HOSTDIR:$CONTAINERDIR:Z"
fi

# If working directory is specified, add it to the command
if [ -n "$WORKDIR" ]; then
    CMD="$CMD --workdir $WORKDIR"
fi

# Append the image to the command
CMD="$CMD $IMAGE"

# Run the Podman container in the background
echo "Running command: $CMD"
eval "$CMD" /bin/sh -c '

# Function to detect the distro inside the container
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo $ID
    else
        echo "unknown"
    fi
}

DISTRO=$(detect_distro)

# Run commands based on the detected distro
case "$DISTRO" in
    ubuntu)
        echo "Running commands for Ubuntu..."
        sudo apt update && sudo apt install -y curl
        ;;
    fedora)
        echo "Running commands for Fedora..."
        sudo dnf update -y && sudo dnf install -y curl
        ;;
    alpine)
        echo "Running commands for Alpine..."
        sudo apk update && sudo apk add curl
        ;;
    *)
        echo "Unknown distro: $DISTRO"
        ;;
esac

# Keeping the container interactive
exec /bin/sh
'
"""
podman run -it \
  --name mojoenv \
  --userns=keep-id \
  --security-opt label=disable \
  --env-file /dev/null \
  --hostname mojoenv \  
  --user nonroot
"""