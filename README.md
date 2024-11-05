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

```bash
docker run \
  --name fief-server \
  -p 8000:8000 \
  -d \
  -e "SECRET=yFgadJP1ExedXNVxqVOQjKwsmqebUpaQRE9wvJ_duZPdtldOxcZG5ED2IpfGAItMSbn7Tb-rx4SzFo3eX9-i_A" \
  -e "FIEF_CLIENT_ID=8Yla4JSXUjqW3UA1ZUp0zSpceGeYU7xCuqSCJUBjfDg" \
  -e "FIEF_CLIENT_SECRET=6Jv76jkTL8boUcBgx58yaL5PfHn-Q_MGUcrx0EYmBvs" \
  -e "ENCRYPTION_KEY=Q5PeehTtcsd1feCOgNWZx_MCHAL354WWxEhzorvSUGI=" \
  -e "PORT=8000" \
  -e "FIEF_DOMAIN=localhost:8000" \
  -e "FIEF_MAIN_USER_EMAIL=nazrul@care-box.com" \
  -e "FIEF_MAIN_USER_PASSWORD=verysecurepassword" \
  -e "CSRF_COOKIE_SECURE=False" \
  -e "SESSION_DATA_COOKIE_SECURE=False" \
  -e "USER_LOCALE_COOKIE_SECURE=False" \
  -e "LOGIN_HINT_COOKIE_SECURE=False" \
  -e "LOGIN_SESSION_COOKIE_SECURE=False" \
  -e "REGISTRATION_SESSION_COOKIE_SECURE=False" \
  -e "SESSION_COOKIE_SECURE=False" \
  -e "FIEF_ADMIN_SESSION_COOKIE_SECURE=False" \
  ghcr.io/fief-dev/fief:latest
```