# Termcraft

Automated setup for a modern, powerful terminal environment with zsh, oh-my-zsh, powerlevel10k, and essential CLI tools. Works on Linux and macOS.

## Features

### Core Shell Setup
- **Zsh** - Modern shell with powerful features
- **Oh-My-Zsh** - Framework for managing zsh configuration
- **Powerlevel10k** - Beautiful and fast zsh theme

### Zsh Plugins
- **zsh-autosuggestions** - Fish-like autosuggestions
- **fast-syntax-highlighting** - Real-time syntax highlighting
- **zsh-completions** - Additional completion definitions
- **fzf-tab** - Replace zsh's default completion with fzf
- **git** - Git aliases and functions
- **sudo** - Easily prefix commands with sudo (press ESC twice)
- **extract** - Universal archive extractor
- **copypath** / **copyfile** - Copy file paths and contents
- **colored-man-pages** - Colorized man pages
- **z** - Jump to frequently used directories (only loaded as a fallback when zoxide isn't installed)

### fzf Keybindings
- `Ctrl-R` - Fuzzy search command history
- `Ctrl-T` - Fuzzy pick a file
- `Alt-C` - Fuzzy cd into a directory

### Python Tools
- **uv** - Extremely fast Python package manager (installs Python CLI tools)
- **nvitop** - Interactive NVIDIA GPU monitor (installed via uv)

### Modern CLI Tools
- **btop** - System monitor (better htop)
- **ripgrep (rg)** - Fast file search
- **eza** - Better ls with git status (replaces `ls`, see aliases below)
- **fd** - Better find, respects .gitignore
- **bat** - Better cat with syntax highlighting
- **zoxide** - Smart cd that learns your habits (`z foo` to jump, `zi` to pick with fzf)
- **dust** - Visual disk usage
- **delta** - Beautiful git diffs (configured as git's pager by the install script)
- **sd** - Simpler sed replacement
- **xh** - Better curl for APIs
- **tldr** - Quick command cheat sheets
- **procs** - Better ps
- **yazi** - Terminal file manager
- **glow** - Markdown renderer
- **lazygit** - Terminal UI for git

### Custom Aliases & Functions
- `view` - Quick image viewer using feh
- `als` - Interactive alias browser with fzf
- `ls` / `ll` / `la` / `lt` - eza listing, long + git status, long incl. hidden, 2-level tree (when eza is installed)
- `fd` / `bat` - Aliases for `fdfind` / `batcat` (Debian/Ubuntu binary names)

### Shell Behavior
- **Locale fallback** - Uses `C.UTF-8` when the configured locale (default `en_US.UTF-8`) isn't generated, e.g. on fresh Ubuntu/DGX installs
- **Fast prompt** - Powerlevel10k instant prompt, git untracked-file check disabled for large repos
- **No auto-correction** - zsh's "did you mean" prompts are off

## Recommended Terminal

This setup works with any modern terminal emulator. That said, I personally recommend [Ghostty](https://ghostty.org/) - a fast, feature-rich, and cross-platform terminal that I used while creating this config. It handles true colors, ligatures, and GPU acceleration beautifully out of the box.

## Quick Start

```bash
git clone git@github.com:danylomm/termcraft.git
cd termcraft
./install.sh
```

After installation:
1. Restart your terminal (or run `exec zsh`)
2. If first time using Powerlevel10k, run `p10k configure` to customize your prompt
3. Enjoy your new terminal!

## What the Install Script Does

1. **Checks prerequisites** - Ensures git and curl are installed
2. **Installs zsh** - If not already present
3. **Sets zsh as default shell** - Changes your default shell
4. **Installs oh-my-zsh** - Framework for zsh configuration
5. **Installs powerlevel10k** - Beautiful theme
6. **Installs external plugins** - All custom zsh plugins
7. **Installs fzf** - Fuzzy finder for command line
8. **Installs uv** - Fast Python package manager
9. **Installs modern CLI tools** - All the productivity tools
10. **Installs Python CLI tools** - nvitop and other tools via uv
11. **Configures delta** - Sets delta as git's pager (skipped if you already have a pager configured)
12. **Symlinks dotfiles** - Links .zshrc and .p10k.zsh to your home directory
13. **Verifies terminal colors** - Ensures 256 color support

## Installation Details

### Idempotent
The script can be run multiple times safely. It checks for existing installations and skips them.

### Backup
If you have existing `.zshrc` or `.p10k.zsh` files, they will be backed up with a `.backup` extension.

### Package Managers
The script automatically detects and uses your system's package manager:
- apt-get (Debian/Ubuntu)
- dnf (Fedora)
- yum (RHEL/CentOS)
- pacman (Arch)
- brew (macOS)

## File Structure

```
termcraft/
├── README.md              # This file
├── install.sh             # Main installation script
├── dotfiles/
│   ├── .zshrc            # Zsh configuration
│   └── .p10k.zsh         # Powerlevel10k theme config
└── scripts/
    └── plugin-urls.sh    # Plugin repository URLs
```

## Customization

### Adding More Plugins

1. Edit `scripts/plugin-urls.sh` and append your plugin to both arrays, at the same position:
   ```bash
   PLUGIN_NAMES=( ... "plugin-name" )
   PLUGIN_URLS=( ... "https://github.com/user/plugin-repo" )
   ```

2. Edit `dotfiles/.zshrc` and add the plugin name to the `plugins` array

3. Run `./install.sh` again to install the new plugin

### Modifying .zshrc

Edit `dotfiles/.zshrc` to add your own:
- Aliases
- Functions
- Environment variables
- Path modifications

After making changes, either:
- Run `./install.sh` again (will symlink the updated file)
- Or manually reload: `source ~/.zshrc`

### Customizing Powerlevel10k

Run the configuration wizard anytime:
```bash
p10k configure
```

This will update your `~/.p10k.zsh` file. To save these changes to the repo:
```bash
cp ~/.p10k.zsh /path/to/termcraft/dotfiles/.p10k.zsh
```

## Machine-Specific Configurations

This repository contains **only portable configurations**. For machine-specific settings (GPU configs, laptop-specific tweaks, etc.), add them to:
- `~/.zshrc.local` - Sourced automatically if it exists
- Or append to your local `~/.zshrc` after symlinking

Example `~/.zshrc.local`:
```bash
# Add this line to the end of dotfiles/.zshrc first:
# [[ -f ~/.zshrc.local ]] && source ~/.zshrc.local

# Machine-specific GPU settings
export __NV_PRIME_RENDER_OFFLOAD=0
alias chrome="__GLX_VENDOR_LIBRARY_NAME=mesa /opt/google/chrome/chrome"

# Machine-specific secrets
export MY_SECRET_KEY="..."
```

## Troubleshooting

### Zsh not set as default
Run manually:
```bash
chsh -s $(which zsh)
```
Then restart your terminal.

### Colors not working
Add to your terminal emulator settings or `~/.zshrc.local`:
```bash
export TERM=xterm-256color
```

### Plugins not loading
Ensure the plugin is:
1. Installed in `~/.oh-my-zsh/custom/plugins/`
2. Listed in the `plugins=()` array in `.zshrc`
3. Reload with `source ~/.zshrc`

### fdfind vs fd
On Debian/Ubuntu systems, `fd` is installed as `fdfind` to avoid conflicts. The .zshrc automatically creates an alias for this.

## Tested Platforms

This repository has been tested and verified on:
- Ubuntu 24.04 LTS (ARM64)
- Fedora 43 (x86_64)
- macOS 15 Sequoia (ARM64/Apple Silicon)

It should work on other Linux distributions and macOS versions, but these are the platforms where it's been thoroughly tested.

## Requirements

- Git
- Curl
- Internet connection
- Unix-like OS (Linux, macOS, WSL)

## License

Free to use and modify for your own setup.

## Contributing

This is a personal dotfiles repository, but feel free to fork and adapt for your needs!
