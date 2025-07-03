# docker-stack

*** Concourse
https://github.com/concourse/concourse
https://concourse-ci.org

*** Dagger
https://github.com/dagger/dagger
https://dagger.io

*** Woodpecker
https://github.com/woodpecker-ci/woodpecker
https://woodpecker-ci.org/docs/usage/intro

*** Agola
https://github.com/agola-io/agola
https://agola.io/

*** Jaypore CI
https://github.com/theSage21/jaypore_ci
https://www.jayporeci.in

### Linux Command To Install zsh themes and tools
```sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/NobinKhan/docker-stack/main/linux_install.sh)"
```

### Linux version-2 Command To Install zsh themes and tools
```sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/NobinKhan/docker-stack/main/terminal_config.sh)"
```

### MacOS Command To Install zsh themes and tools
```sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/NobinKhan/docker-stack/main/mac_install.sh)"
```

### SSH Setup In New Ubuntu Server
```sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/NobinKhan/docker-stack/main/server/ssh_setup.sh)"
```

## Build Multiarch Image With Docker Buildx

### Docker Buildx Setup
```bash
docker buildx create --driver-opt network=host --use --name multi-arch
```

### Login To Docker Hub
```bash
docker login -u nobinkhan
```

### Build Multiarch Image & Push to Docker Hub
```bash
docker buildx build --platform linux/amd64,linux/arm64 -t nobinkhan/python:3.12.4-slim . --push
```

https://powersj.io/posts/ubuntu-qemu-cli/
https://cloud-images.ubuntu.com/minimal/

### Isolated Environment
```bash
podman run -it \
  --name mojoenv \
  --userns=keep-id \
  --security-opt label=disable \
  --env-file /dev/null \
  --hostname mojoenv \
  --volume /run/media/nobin/Files/project:/home/nonroot/project \
  ubuntu:24.04
```
