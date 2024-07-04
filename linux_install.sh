#!/usr/bin/env sh

# Function to detect the Linux distribution
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo $ID
    else
        echo "unknown"
    fi
}

# Function to check if a package is installed
is_installed() {
    rpm -q $1 >/dev/null 2>&1
}

# Function to install a package if it is not installed
install_package() {
    if ! is_installed $1; then
        sudo dnf install -y $1
    fi
}

# Function to download and install fonts from a URL
install_font() {
    TEMP_DIR=$(mktemp -d)
    FONT_ZIP=$TEMP_DIR/font.zip
    curl -L -o $FONT_ZIP $1
    unzip -o $FONT_ZIP -d $TEMP_DIR
    sudo mv $TEMP_DIR/*.ttf /usr/share/fonts/
    sudo fc-cache -f -v
    rm -rf $TEMP_DIR
}

# Function to install oh-my-zsh if not installed
install_oh_my_zsh() {
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        sh -c "$(wget https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh -O -)"
        echo "Please restart the terminal and re-run the script to continue."
        exit 0
    fi
}

# Main script execution
DISTRO=$(detect_distro)
if [ "$DISTRO" = "fedora" ]; then
    # Task 1: Install zsh if not installed and make it the default shell
    install_package zsh
    if [ "$(basename $SHELL)" != "zsh" ]; then
        chsh -s $(which zsh)
    fi

    # Task 2: Install oh-my-zsh if not installed
    install_oh_my_zsh

    # Task 3: Install Cascadia Code NF fonts
    install_package cascadia-code-nf-fonts

    # Task 4: Download and install additional fonts
    install_font "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/CascadiaCode.zip"
    install_font "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/FiraCode.zip"
    install_font "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/Meslo.zip"

    # Task 5: Install Powerlevel10k theme and plugins
    ZSH_CUSTOM=${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}
    [ ! -d "$ZSH_CUSTOM/themes/powerlevel10k" ] && git clone --depth=1 https://github.com/romkatv/powerlevel10k.git $ZSH_CUSTOM/themes/powerlevel10k
    [ ! -d "$ZSH_CUSTOM/plugins/zsh-completions" ] && git clone --depth=1 https://github.com/zsh-users/zsh-completions $ZSH_CUSTOM/plugins/zsh-completions
    [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ] && git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions $ZSH_CUSTOM/plugins/zsh-autosuggestions
    [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ] && git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git $ZSH_CUSTOM/plugins/zsh-syntax-highlighting

    # Task 6: Edit ~/.zshrc
    sed -i 's/^ZSH_THEME=.*/ZSH_THEME="powerlevel10k\/powerlevel10k"/' ~/.zshrc
    sed -i 's/^plugins=.*/plugins=(git zsh-completions zsh-autosuggestions zsh-syntax-highlighting)/' ~/.zshrc

    echo "All tasks completed. Please restart your terminal."
else
    echo "This script only supports Fedora Linux."
fi
