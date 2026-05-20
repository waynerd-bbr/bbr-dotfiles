# dotfiles
This repository contains my personal dotfiles and setup scripts for configuring a Linux (Ubuntu) development environment. It automates the installation of essential tools, custom configurations, and shell enhancements, including `zsh` and `Oh My Zsh`.

## Purpose
The goal of this repository is to provide a streamlined way to set up a new development environment with my preferred tools and configurations. The `bootstrap.sh` script handles the installation of dependencies, configuration files, and custom plugins.

## Features
- Installs essential system libraries for Debian-based systems.
- Installs and configures [Homebrew](https://brew.sh/) for managing packages.
- Installs and sets up `zsh` as the default shell.
- Installs [Oh My Zsh](https://ohmyz.sh/) and custom plugins.
- Copies `.zshrc` and other configuration files to the appropriate locations.
- Installs Python using `pyenv` and sets the latest version as the default.
- Installs additional tools and utilities via Homebrew (e.g., `starship`, `fzf`, `poetry`).
- Configures the `starship` prompt and other customizations.

## Installation

### Prerequistes
You might need to create an ssh key. Look [here](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent?platform=linux) for how to do that.

### Using Git and the Bootstrap Script
Clone this repository to your preferred location (e.g., `~/.dotfiles`) and run the bootstrap script:

```shell
git clone https://github.com/jmicaliz/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
source bootstrap.sh
```

The `bootstrap.sh` script will:
1. Pull the latest changes from the repository.
2. Install required tools and libraries.
3. Configure `zsh` as the default shell.
4. Install and configure Python using `pyenv`.
5. Set up custom plugins and configurations.

### Updating
To update your dotfiles and reapply the configurations, navigate to the repository and run the bootstrap script again:

```shell
cd ~/.dotfiles
source bootstrap.sh
```

## Customizations
- **Shell Prompt**: Configured using [Starship](https://starship.rs/). The configuration is stored in `starship.toml`.
- **Custom Plugins**: Includes custom `zsh` plugins located in the `plugins/` directory.
- **Python Management**: Uses `pyenv` and `pyenv-virtualenv` for managing Python versions and virtual environments.

## Tools Installed via Homebrew
The following tools are installed via the `Brewfile`:
- Development tools: `gcc`, `openssl`, `readline`, `sqlite3`, `zlib`, `tcl-tk@8`
- Shell enhancements: `starship`, `fzf`, `ripgrep`
- Python tools: `pyenv`, `pyenv-virtualenv`, `poetry`
- Utilities: `jq`, `httpie`, `pgcli`, `tlrc`
- Additional tools: `kona`, `rlwrap`

## How To Update Fork
1. Ensure the upstream remote exists:

   ```git remote -v```

   Should see the `origin` and the `upstream` git URLs. If not, add with:

   ```git remote add upstream https://<repo clone url>```
2. `git fetch upstream`
3. `git checkout main`
4. `git rebase -i upstream/main`
5. `git push origin main --force-with-lease`

## Fork Additions (Wayne Banks II)

This fork adds Claude Code plugin integration via git submodule. The `post-bootstrap.sh` script runs automatically at the end of `bootstrap.sh` and:

- Initializes the `claude-plugins/coding-development` submodule
- Symlinks the plugin to `~/.claude/plugins/coding-development`
- Creates `~/.gitconfig.local` with your git identity (overrides the upstream `.gitconfig`)
- Creates `~/.zshrc.local` with `GIT_COMMIT_AUTHOR` override
- Appends `.zshrc.local` sourcing to `~/.zshrc` (idempotent)

### Updating the Plugin

```shell
cd claude-plugins/coding-development
git pull origin main
cd ../..
git add claude-plugins/coding-development
git commit -m "chore: update coding-development plugin"
```

Or in one step:
```shell
git submodule update --remote claude-plugins/coding-development
```

### Workspace Health Check

```shell
./workspace-health.sh
```

Validates: Claude Code install, plugin symlink, plugin.json, skills directory, submodule status, git identity, API key, .zshrc.local sourcing, cron job.

### Troubleshooting

- **Submodule empty after clone**: Run `git submodule update --init --recursive`
- **Symlink broken**: Delete `~/.claude/plugins/coding-development` and re-run `./post-bootstrap.sh`
- **Git identity wrong**: Check `~/.gitconfig.local` exists and has your name/email
- **ANTHROPIC_API_KEY missing**: Set via Coder workspace env vars, not in dotfiles

## Notes
- This setup assumes you are running Linux (Ubuntu). Some steps may need to be adjusted for other operating systems.
- Also, need to install a [Nerd Font](https://www.nerdfonts.com/font-downloads) to see all the cool icons.
