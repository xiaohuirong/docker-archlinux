#!/bin/bash

if [ $# -eq 0 ]; then
    echo "Usage:   $0 <image name>"
    echo "Example: $0 archlinux:latest"
    exit 1
fi

IMAGE_NAME=$1

docker run --rm -it \
    --runtime=nvidia \
    --ipc=host \
    -p 2022:22 \
    -v $HOME:/workspace \
    -e USER_ID=$(id -u) \
    -e GROUP_ID=$(id -g) \
    $IMAGE_NAME

# --userns=keep-id: map host user uid to guest same uid
# without this will map to guest 0(root)

# podman run --rm -it \
#     --gpus all \
#     --ipc=host \
#     -p 2022:22 \
#     -v $HOME:/workspace \
#     -e USER_ID=$(id -u) \
#     -e GROUP_ID=$(id -g) \
#     --userns=keep-id \
#     $IMAGE_NAME
