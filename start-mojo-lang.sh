#!/usr/bin/env sh

# Build New Ubuntu Image
docker build -t ubuntu-local:24-zsh -f dev_env/Dockerfile.devenv.ubuntu .

# Run New Ubuntu Image
docker run -it --name ubuntu-24 ubuntu-local:24-zsh /bin/zsh
 