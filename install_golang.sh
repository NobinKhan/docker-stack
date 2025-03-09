#!/bin/bash

set -e

# Define installation variables
GO_INSTALL_DIR="/usr/local"
PROFILE_PATH="$HOME/.zshrc"

# Get latest Go version (extract only the first line)
LATEST_VERSION=$(curl -s https://go.dev/VERSION?m=text | head -n1)
GO_TARBALL="$LATEST_VERSION.linux-amd64.tar.gz"
GO_URL="https://go.dev/dl/$GO_TARBALL"
CHECKSUMS_URL="https://go.dev/dl/$GO_TARBALL.sha256"

# Download Go tarball
curl -OL "$GO_URL"

# Attempt to download checksum file
# if curl -fOL "$CHECKSUMS_URL"; then
#     # Verify checksum if available
#     EXPECTED_CHECKSUM=$(awk '{print $1}' "$GO_TARBALL.sha256")
#     ACTUAL_CHECKSUM=$(sha256sum "$GO_TARBALL" | awk '{print $1}')

#     if [ "$EXPECTED_CHECKSUM" != "$ACTUAL_CHECKSUM" ]; then
#         echo "Checksum verification failed!"
#         exit 1
#     fi
#     echo "Checksum verified. Proceeding with installation."
#     rm "$GO_TARBALL.sha256"
# else
#     echo "Checksum file not available. Skipping verification."
# fi

# Remove previous Go installation if exists
sudo rm -rf "$GO_INSTALL_DIR/go"

# Extract Go tarball
sudo tar -C "$GO_INSTALL_DIR" -xzf "$GO_TARBALL"

# Cleanup downloaded files
rm "$GO_TARBALL"

# Add Go binary path to profile
if ! grep -q "export PATH=\$GO_INSTALL_DIR/go/bin:\$PATH" "$PROFILE_PATH"; then
    echo "export PATH=$GO_INSTALL_DIR/go/bin:\$PATH" >> "$PROFILE_PATH"
fi

# Reload profile
source "$PROFILE_PATH"

echo "Go $LATEST_VERSION installed successfully!"
go version
