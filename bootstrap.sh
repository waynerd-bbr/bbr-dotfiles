#!/bin/bash

# Change to the directory of the script
cd "$(dirname "${BASH_SOURCE}")";

# If debian-based system, install some necessary libraries
if [ -f /etc/debian_version ]; then
    echo "Installing necessary libraries for Debian-based systems..."
    sudo apt update && sudo apt install -y build-essential procps curl file git zip
fi

# Clone the repository
git pull origin main;

# Install Homebrew
if ! command -v brew &>/dev/null; then
    echo "Installing Homebrew..."
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    if [ "$(uname)" = "Darwin" ]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    else
        eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    fi
else
    echo "Homebrew is already installed."
fi

# Install zsh
if ! command -v zsh &>/dev/null; then
    echo "Installing zsh..."
    if [ "$(uname)" = "Darwin" ]; then
        brew install zsh
    elif [ -f /etc/debian_version ]; then
        sudo apt update && sudo apt install -y zsh
    elif [ -f /etc/redhat-release ]; then
        sudo yum install -y zsh
    else
        echo "Unsupported OS. Please install zsh manually."
        exit 1
    fi
fi

# Change default shell to zsh
if [ "$SHELL" != "$(which zsh)" ]; then
    echo "Changing default shell to zsh..."
    chsh -s "$(which zsh)"
else
    echo "Default shell is already zsh."
fi

# Install Oh My Zsh
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
    echo "Oh My Zsh is already installed."
fi

# Install custom_commands
for plugin_dir in plugins/*; do
    if [ -d "$plugin_dir" ]; then
        cp -r "$plugin_dir" "$HOME/.oh-my-zsh/custom/plugins"
    fi
done

# Add .zshrc
cp -f de.zshrc $HOME/.zshrc

# Add homebrew installs
brew update
brew bundle --file ./Brewfile

# Install Claude Code
if ! command -v claude &> /dev/null; then
    echo "Installing Claude Code..."
    npm install -g @anthropic-ai/claude-code
else
    echo "Updating Claude Code..."
    claude update
fi

# Add starship toml
mkdir -p $HOME/.config 
cp -f ./configs/starship.toml $HOME/.config/starship.toml

# Add direnv toml
mkdir -p $HOME/.config/direnv
cp -f ./configs/direnv.toml $HOME/.config/direnv/direnv.toml

# Add tlrc toml
mkdir -p $HOME/.config/tlrc
cp -f ./configs/tlrc.toml $HOME/.config/tlrc/config.toml

# Add snowflake toml
mkdir -p $HOME/.snowflake
cp -f ./configs/snowflake.toml $HOME/.snowflake/config.toml
chmod 0600 $HOME/.snowflake/config.toml
snow --install-completion

# Add .gitconfig
cp -f ./configs/.gitconfig $HOME/.gitconfig

# Add .gitignore_global
cp -f ./configs/.gitignore_global $HOME/.gitignore_global

# Add Claude Code settings
mkdir -p $HOME/.claude
cp -rf ./configs/.claude/* $HOME/.claude/

# Make repos directory
mkdir -p $HOME/repos

# Add daily cron job to run bootstrap at 1am (idempotent)
DOTFILES_DIR_CRON="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CRON_CMD="0 1 * * * $DOTFILES_DIR_CRON/bootstrap.sh >> /tmp/bootstrap-cron.log 2>&1"
if ! crontab -l 2>/dev/null | grep -qF "bootstrap.sh"; then
    (crontab -l 2>/dev/null; echo "$CRON_CMD") | crontab -
    echo "Cron job added for daily bootstrap at 1am."
else
    echo "Cron job for daily bootstrap already exists."
fi

# Run personal extensions if present
POST_BOOTSTRAP="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/post-bootstrap.sh"
if [ -x "$POST_BOOTSTRAP" ]; then
    echo "Running post-bootstrap..."
    "$POST_BOOTSTRAP"
fi

echo "Bootstrap completed!"