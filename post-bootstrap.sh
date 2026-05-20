#!/bin/bash
# post-bootstrap.sh — Wayne's personal extensions to the BBR dotfiles bootstrap.
# Called at the end of bootstrap.sh. Safe to run multiple times (idempotent).

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_SRC="$DOTFILES_DIR/claude-plugins/coding-development"
PLUGIN_TARGET="$HOME/.claude/plugins/coding-development"

# --- Git submodule init/update ---
echo "[post-bootstrap] Syncing git submodules..."
cd "$DOTFILES_DIR"
git submodule update --init --recursive

# --- Symlink coding-development plugin ---
mkdir -p "$HOME/.claude/plugins"

if [ -L "$PLUGIN_TARGET" ]; then
    CURRENT_LINK="$(readlink "$PLUGIN_TARGET")"
    if [ "$CURRENT_LINK" = "$PLUGIN_SRC" ]; then
        echo "[post-bootstrap] Plugin symlink already correct."
    else
        echo "[post-bootstrap] Updating plugin symlink (was: $CURRENT_LINK)..."
        ln -sfn "$PLUGIN_SRC" "$PLUGIN_TARGET"
    fi
elif [ -d "$PLUGIN_TARGET" ]; then
    echo "[post-bootstrap] WARNING: $PLUGIN_TARGET is a directory, not a symlink. Skipping."
else
    echo "[post-bootstrap] Symlinking plugin..."
    ln -sfn "$PLUGIN_SRC" "$PLUGIN_TARGET"
fi

# --- Git identity override ---
GITCONFIG_LOCAL="$HOME/.gitconfig.local"
if [ ! -f "$GITCONFIG_LOCAL" ]; then
    echo "[post-bootstrap] Creating $GITCONFIG_LOCAL..."
    cat > "$GITCONFIG_LOCAL" <<'EOF'
[user]
    name = Wayne Banks II
    email = wbanks@bbrpartners.com
EOF
else
    echo "[post-bootstrap] $GITCONFIG_LOCAL already exists, skipping."
fi

# --- Override GIT_COMMIT_AUTHOR env var from de.zshrc ---
ZSH_OVERRIDE="$HOME/.zshrc.local"
if [ ! -f "$ZSH_OVERRIDE" ]; then
    echo "[post-bootstrap] Creating $ZSH_OVERRIDE..."
    cat > "$ZSH_OVERRIDE" <<'ZSHEOF'
# Wayne's overrides — sourced after .zshrc
export GIT_COMMIT_AUTHOR="Wayne Banks II <wbanks@bbrpartners.com>"
ZSHEOF
else
    echo "[post-bootstrap] $ZSH_OVERRIDE already exists, skipping."
fi

# Ensure .zshrc sources the local overrides (idempotent)
if ! grep -qF '.zshrc.local' "$HOME/.zshrc" 2>/dev/null; then
    echo '[post-bootstrap] Adding .zshrc.local source to .zshrc...'
    printf '\n# Personal overrides\n[ -f "$HOME/.zshrc.local" ] && source "$HOME/.zshrc.local"\n' >> "$HOME/.zshrc"
fi

# --- Validate environment ---
echo "[post-bootstrap] Validating setup..."
ERRORS=0

if [ ! -d "$PLUGIN_TARGET/skills" ]; then
    echo "  ERROR: Plugin skills directory missing at $PLUGIN_TARGET/skills"
    ERRORS=$((ERRORS + 1))
fi

if [ ! -f "$PLUGIN_TARGET/.claude-plugin/plugin.json" ]; then
    echo "  ERROR: plugin.json missing"
    ERRORS=$((ERRORS + 1))
fi

if [ -z "${ANTHROPIC_API_KEY:-}" ]; then
    echo "  WARNING: ANTHROPIC_API_KEY not set. Set via Coder env vars."
fi

if [ "$ERRORS" -eq 0 ]; then
    echo "[post-bootstrap] All checks passed."
else
    echo "[post-bootstrap] $ERRORS error(s). Run workspace-health.sh for details."
fi
