#!/bin/bash
cd "$(dirname "${BASH_SOURCE}")";

MARKER_DIR="$HOME/.config/coderv2"
mkdir -p "$MARKER_DIR"

# ---------- Debian packages (run once) ----------
if [ -f /etc/debian_version ] && [ ! -f "$MARKER_DIR/.apt_done" ]; then
    echo "Installing necessary libraries for Debian-based systems..."
    sudo apt update && sudo apt install -y build-essential procps curl file git zip
    touch "$MARKER_DIR/.apt_done"
fi

git pull origin main;

# ---------- Homebrew (run once) ----------
if ! command -v brew &>/dev/null && [ ! -x /home/linuxbrew/.linuxbrew/bin/brew ]; then
    echo "Installing Homebrew..."
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
    echo "Homebrew is already installed."
fi

# Always ensure brew is on PATH for the rest of the script
if [ "$(uname)" = "Darwin" ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
else
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

# ---------- zsh ----------
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

if [ "$SHELL" != "$(which zsh)" ]; then
    echo "Changing default shell to zsh..."
    chsh -s "$(which zsh)" || true   # CHANGED: don't fail on PAM auth error
else
    echo "Default shell is already zsh."
fi

# ---------- Oh My Zsh ----------
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
    echo "Oh My Zsh is already installed."
fi

# ---------- Plugins & zshrc ----------
for plugin_dir in plugins/*; do
    if [ -d "$plugin_dir" ]; then
        cp -r "$plugin_dir" "$HOME/.oh-my-zsh/custom/plugins"
    fi
done
cp -f de.zshrc $HOME/.zshrc

# ---------- Brew bundle (run once, re-run on Brewfile change) ----------
BREWFILE_HASH=$(md5sum ./Brewfile 2>/dev/null | awk '{print $1}')
BREW_MARKER="$MARKER_DIR/.brew_bundle_hash"

if [ ! -f "$BREW_MARKER" ] || [ "$(cat "$BREW_MARKER")" != "$BREWFILE_HASH" ]; then
    echo "Running brew bundle..."
    brew update
    brew bundle --file ./Brewfile || true   # CHANGED: don't fail the script on partial errors
    echo "$BREWFILE_HASH" > "$BREW_MARKER"
else
    echo "brew bundle already up to date, skipping."
fi

# ---------- Claude Code ----------
if ! command -v claude &> /dev/null; then
    echo "Installing Claude Code..."
    npm install -g @anthropic-ai/claude-code
else
    echo "Updating Claude Code..."
    claude update || true   # CHANGED: don't fail on update errors
fi

# ---------- Config files (cheap, always copy) ----------
mkdir -p $HOME/.config
cp -f ./configs/starship.toml $HOME/.config/starship.toml

mkdir -p $HOME/.config/direnv
cp -f ./configs/direnv.toml $HOME/.config/direnv/direnv.toml

mkdir -p $HOME/.config/tlrc
cp -f ./configs/tlrc.toml $HOME/.config/tlrc/config.toml

mkdir -p $HOME/.snowflake
cp -f ./configs/snowflake.toml $HOME/.snowflake/config.toml
chmod 0600 $HOME/.snowflake/config.toml
snow --install-completion 2>/dev/null || true

cp -f ./configs/.gitconfig $HOME/.gitconfig
cp -f ./configs/.gitignore_global $HOME/.gitignore_global

mkdir -p $HOME/.claude
cp -rf ./configs/.claude/* $HOME/.claude/

mkdir -p $HOME/repos

# ---------- Cron (idempotent, unchanged) ----------
DOTFILES_DIR_CRON="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CRON_CMD="0 1 * * * $DOTFILES_DIR_CRON/bootstrap.sh >> /tmp/bootstrap-cron.log 2>&1"
if ! crontab -l 2>/dev/null | grep -qF "bootstrap.sh"; then
    (crontab -l 2>/dev/null; echo "$CRON_CMD") | crontab -
    echo "Cron job added for daily bootstrap at 1am."
else
    echo "Cron job for daily bootstrap already exists."
fi

# ---------- Post-bootstrap hook ----------
POST_BOOTSTRAP="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/post-bootstrap.sh"
if [ -x "$POST_BOOTSTRAP" ]; then
    echo "Running post-bootstrap..."
    "$POST_BOOTSTRAP"
fi

echo "Bootstrap completed!"
