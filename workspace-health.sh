#!/bin/bash
# workspace-health.sh — Diagnostic tool for BBR dotfiles + plugin setup.

set -uo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_TARGET="$HOME/.claude/plugins/coding-development"
PLUGIN_SRC="$DOTFILES_DIR/claude-plugins/coding-development"

PASS=0
WARN=0
FAIL=0

check_pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
check_warn() { echo "  WARN: $1"; WARN=$((WARN + 1)); }
check_fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }

echo "=== Workspace Health Check ==="
echo ""

# 1. Claude Code installed
if command -v claude &>/dev/null; then
    check_pass "Claude Code installed ($(claude --version 2>/dev/null || echo 'unknown version'))"
else
    check_fail "Claude Code not installed"
fi

# 2. Plugin symlink
if [ -L "$PLUGIN_TARGET" ]; then
    LINK="$(readlink "$PLUGIN_TARGET")"
    if [ "$LINK" = "$PLUGIN_SRC" ]; then
        check_pass "Plugin symlink correct"
    else
        check_warn "Plugin symlink points to $LINK (expected $PLUGIN_SRC)"
    fi
elif [ -d "$PLUGIN_TARGET" ]; then
    check_warn "Plugin target is a directory, not a symlink"
else
    check_fail "Plugin symlink missing at $PLUGIN_TARGET"
fi

# 3. plugin.json
if [ -f "$PLUGIN_TARGET/.claude-plugin/plugin.json" ]; then
    check_pass "plugin.json exists"
else
    check_fail "plugin.json missing at $PLUGIN_TARGET/.claude-plugin/plugin.json"
fi

# 4. Skills count
if [ -d "$PLUGIN_TARGET/skills" ]; then
    SKILL_COUNT=$(find "$PLUGIN_TARGET/skills" -name "SKILL.md" 2>/dev/null | wc -l | tr -d ' ')
    check_pass "Skills directory exists ($SKILL_COUNT skills found)"
else
    check_fail "Skills directory missing"
fi

# 5. Git submodule status
cd "$DOTFILES_DIR"
SUB_STATUS=$(git submodule status claude-plugins/coding-development 2>/dev/null)
if [ -n "$SUB_STATUS" ]; then
    if echo "$SUB_STATUS" | grep -q '^-'; then
        check_fail "Submodule not initialized"
    elif echo "$SUB_STATUS" | grep -q '^+'; then
        check_warn "Submodule has local changes (out of sync with index)"
    else
        check_pass "Submodule in sync"
    fi
else
    check_fail "Submodule not found in .gitmodules"
fi

# 6. Git identity
GIT_NAME=$(git config user.name 2>/dev/null || echo "")
GIT_EMAIL=$(git config user.email 2>/dev/null || echo "")
if [ -n "$GIT_NAME" ] && [ -n "$GIT_EMAIL" ]; then
    check_pass "Git identity: $GIT_NAME <$GIT_EMAIL>"
else
    check_warn "Git identity not fully configured (name='$GIT_NAME', email='$GIT_EMAIL')"
fi

# 7. .gitconfig.local
if [ -f "$HOME/.gitconfig.local" ]; then
    check_pass ".gitconfig.local exists"
else
    check_warn ".gitconfig.local missing (git identity override not set)"
fi

# 8. ANTHROPIC_API_KEY
if [ -n "${ANTHROPIC_API_KEY:-}" ]; then
    check_pass "ANTHROPIC_API_KEY is set"
else
    check_warn "ANTHROPIC_API_KEY not set"
fi

# 9. .zshrc.local sourced
if grep -qF '.zshrc.local' "$HOME/.zshrc" 2>/dev/null; then
    check_pass ".zshrc sources .zshrc.local"
else
    check_warn ".zshrc does not source .zshrc.local"
fi

# 10. Cron job
if crontab -l 2>/dev/null | grep -qF "bootstrap.sh"; then
    check_pass "Daily bootstrap cron job exists"
else
    check_warn "No bootstrap cron job found"
fi

echo ""
echo "=== Summary: $PASS passed, $WARN warnings, $FAIL failures ==="

if [ "$FAIL" -gt 0 ]; then
    exit 1
elif [ "$WARN" -gt 0 ]; then
    exit 0
else
    exit 0
fi
