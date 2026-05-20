# CLAUDE.md — dotfiles
Personal dotfiles for a Linux (Ubuntu) development environment, managed via Oh My Zsh and bootstrapped with `bootstrap.sh`. Fork of jmicalizzi/dotfiles with plugin integration.

## Repo Structure
- `bootstrap.sh` — idempotent setup script, run with `./bootstrap.sh`
- `post-bootstrap.sh` — Wayne's personal extensions (plugin symlink, git identity, .zshrc.local)
- `workspace-health.sh` — diagnostic tool for validating the full setup
- `de.zshrc` — the main zshrc; copied to `~/.zshrc` by bootstrap
- `Brewfile` — Homebrew packages
- `plugins/` — custom Oh My Zsh plugins, each in their own subdirectory
- `configs/` — config files copied to their target locations by bootstrap
- `claude-plugins/` — Claude Code plugin submodules
  - `coding-development/` — git submodule -> WayneBanksy/wayneys_claude

## Bootstrap Flow
1. `bootstrap.sh` runs upstream setup (brew, zsh, oh-my-zsh, configs, claude code)
2. `bootstrap.sh` calls `post-bootstrap.sh` if present and executable
3. `post-bootstrap.sh` inits submodule, symlinks plugin to `~/.claude/plugins/coding-development`, creates git identity override, adds `.zshrc.local` sourcing

## Key Conventions
- **Upstream files** (avoid modifying): `de.zshrc`, `Brewfile`, `configs/.claude/commands/`, `plugins/`
- **Fork additions** (safe to modify): `post-bootstrap.sh`, `workspace-health.sh`, `claude-plugins/`
- Git identity override via `~/.gitconfig.local` (included by `configs/.gitconfig`)
- Env var overrides via `~/.zshrc.local` (sourced at end of `~/.zshrc` by post-bootstrap)
