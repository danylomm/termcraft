# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Termcraft is a cross-platform terminal setup tool that installs and configures zsh, oh-my-zsh, powerlevel10k, and modern CLI tools on Linux and macOS.

## Important: Public Repository

This is a **public dotfiles repository**. Never commit:
- API keys, tokens, or secrets
- Machine-specific paths or usernames
- Private SSH configs or credentials
- Any personally identifiable information

Machine-specific configurations belong in `~/.zshrc.local` (sourced automatically, not tracked in git).

## Running the Install Script

```bash
./install.sh
```

The script is idempotent - safe to run multiple times. It skips already-installed components.

## Architecture

### Cross-Platform Package Management

The `install_modern_tools()` function in `install.sh` handles platform differences:

- **Tool format**: `"apt_pkg:brew_pkg:apt_check:brew_check:description"`
- **Package manager detection order**: brew → apt → dnf → pacman
- **Binary name differences**: Some tools have different binary names per platform:
  - `fd-find` (apt) installs as `fdfind`, `fd` (brew) installs as `fd`
  - `bat` (apt) installs as `batcat`, `bat` (brew) installs as `bat`

On Linux, tools not in package managers are downloaded from GitHub releases via `install_from_github()`.

### Plugin System

`scripts/plugin-urls.sh` uses parallel arrays (not associative arrays) for bash 3.x compatibility on macOS:
```bash
PLUGIN_NAMES=("plugin1" "plugin2")
PLUGIN_URLS=("url1" "url2")
```

### Dotfiles

- `dotfiles/.zshrc` - Main zsh config, symlinked to `~/.zshrc`
- `dotfiles/.p10k.zsh` - Powerlevel10k theme, symlinked to `~/.p10k.zsh`
- `~/.zshrc.local` - Machine-specific config (not in repo, sourced if exists)

### Platform Compatibility Patterns

Use conditional checks that are no-ops on unsupported platforms:
```bash
[[ -d "/opt/homebrew/bin" ]] && export PATH="/opt/homebrew/bin:$PATH"
command -v fdfind >/dev/null 2>&1 && alias fd='fdfind'
```

## Adding New Tools

1. Add to the `tools` array in `install_modern_tools()`:
   ```bash
   "apt-package:brew-package:apt-binary:brew-binary:description"
   ```

2. For Linux-only GitHub releases, add to `github_tools` array with asset pattern regex.

## Adding New Plugins

1. Add plugin name to `PLUGIN_NAMES` array in `scripts/plugin-urls.sh`
2. Add corresponding URL to `PLUGIN_URLS` array (same index)
3. Add plugin name to `plugins=()` array in `dotfiles/.zshrc`
