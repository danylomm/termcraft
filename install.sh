#!/usr/bin/env bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load plugin URLs
source "$SCRIPT_DIR/scripts/plugin-urls.sh"

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."

    local missing=()

    if ! command_exists git; then
        missing+=("git")
    fi

    if ! command_exists curl; then
        missing+=("curl")
    fi

    if [ ${#missing[@]} -gt 0 ]; then
        log_error "Missing required tools: ${missing[*]}"
        log_info "Please install them using your package manager"
        exit 1
    fi

    log_success "All prerequisites met"
}

# Install zsh
install_zsh() {
    if command_exists zsh; then
        log_success "Zsh already installed"
        return 0
    fi

    log_info "Installing zsh..."

    if command_exists apt-get; then
        sudo apt-get update && sudo apt-get install -y zsh
    elif command_exists dnf; then
        sudo dnf install -y zsh
    elif command_exists yum; then
        sudo yum install -y zsh
    elif command_exists pacman; then
        sudo pacman -S --noconfirm zsh
    elif command_exists brew; then
        brew install zsh
    else
        log_error "Unknown package manager. Please install zsh manually"
        exit 1
    fi

    log_success "Zsh installed"
}

# Set zsh as default shell
set_zsh_default() {
    if [ "$SHELL" = "$(which zsh)" ]; then
        log_success "Zsh is already the default shell"
        return 0
    fi

    log_info "Setting zsh as default shell..."

    local zsh_path
    zsh_path=$(which zsh)

    # Add zsh to /etc/shells if not present
    if ! grep -q "$zsh_path" /etc/shells; then
        echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null
    fi

    # Change default shell
    chsh -s "$zsh_path"

    log_success "Zsh set as default shell (restart your terminal to take effect)"
}

# Install oh-my-zsh
install_oh_my_zsh() {
    if [ -d "$HOME/.oh-my-zsh" ]; then
        log_success "Oh-my-zsh already installed"
        return 0
    fi

    log_info "Installing oh-my-zsh..."

    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

    log_success "Oh-my-zsh installed"
}

# Install powerlevel10k
install_powerlevel10k() {
    local p10k_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"

    if [ -d "$p10k_dir" ]; then
        log_success "Powerlevel10k already installed"
        return 0
    fi

    log_info "Installing powerlevel10k theme..."

    git clone --depth=1 "$P10K_REPO" "$p10k_dir"

    log_success "Powerlevel10k installed"
}

# Install zsh plugins
install_plugins() {
    log_info "Installing zsh plugins..."

    local zsh_custom="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

    for plugin in "${!PLUGINS[@]}"; do
        local plugin_dir="$zsh_custom/plugins/$plugin"

        if [ -d "$plugin_dir" ]; then
            log_success "Plugin '$plugin' already installed"
        else
            log_info "Installing plugin: $plugin"
            git clone --depth=1 "${PLUGINS[$plugin]}" "$plugin_dir"
            log_success "Plugin '$plugin' installed"
        fi
    done
}

# Install fzf
install_fzf() {
    if [ -d "$HOME/.fzf" ]; then
        log_success "fzf already installed"
        return 0
    fi

    log_info "Installing fzf..."

    git clone --depth 1 https://github.com/junegunn/fzf.git "$HOME/.fzf"
    "$HOME/.fzf/install" --all --no-bash --no-fish

    log_success "fzf installed"
}

# Install modern CLI tools
install_modern_tools() {
    log_info "Installing modern CLI tools..."

    local tools=(
        "btop:system monitor"
        "ripgrep:fast search (rg)"
        "eza:better ls"
        "fd-find:better find"
        "bat:better cat"
        "zoxide:smart cd (z)"
        "dust:visual disk usage"
        "git-delta:beautiful git diffs"
        "sd:simpler sed"
        "xh:better curl"
        "tldr:quick cheat sheets"
        "procs:better ps"
    )

    local to_install=()

    # Check which tools are missing
    for tool_desc in "${tools[@]}"; do
        local tool="${tool_desc%%:*}"
        local desc="${tool_desc#*:}"

        # Special handling for different package names
        local check_cmd="$tool"
        case "$tool" in
            "ripgrep") check_cmd="rg" ;;
            "fd-find") check_cmd="fdfind" ;;
            "git-delta") check_cmd="delta" ;;
        esac

        if command_exists "$check_cmd"; then
            log_success "$desc already installed"
        else
            to_install+=("$tool")
        fi
    done

    # Install missing tools
    if [ ${#to_install[@]} -eq 0 ]; then
        log_success "All modern tools already installed"
        return 0
    fi

    log_info "Installing: ${to_install[*]}"

    if command_exists apt-get; then
        sudo apt-get update && sudo apt-get install -y "${to_install[@]}"
    elif command_exists dnf; then
        sudo dnf install -y "${to_install[@]}"
    elif command_exists yum; then
        sudo yum install -y "${to_install[@]}"
    elif command_exists pacman; then
        sudo pacman -S --noconfirm "${to_install[@]}"
    elif command_exists brew; then
        brew install "${to_install[@]}"
    else
        log_warning "Unknown package manager. Please install tools manually: ${to_install[*]}"
        return 0
    fi

    log_success "Modern CLI tools installed"
}

# Symlink dotfiles
symlink_dotfiles() {
    log_info "Symlinking dotfiles..."

    local dotfiles_dir="$SCRIPT_DIR/dotfiles"

    for dotfile in "$dotfiles_dir"/.??*; do
        local filename=$(basename "$dotfile")
        local target="$HOME/$filename"

        if [ -L "$target" ]; then
            log_success "$filename already symlinked"
        elif [ -f "$target" ]; then
            log_warning "$filename exists, backing up to ${filename}.backup"
            mv "$target" "${target}.backup"
            ln -s "$dotfile" "$target"
            log_success "$filename symlinked (backup created)"
        else
            ln -s "$dotfile" "$target"
            log_success "$filename symlinked"
        fi
    done
}

# Setup terminal colors (256 color support)
setup_terminal_colors() {
    log_info "Verifying terminal color support..."

    if [ -z "$TERM" ]; then
        export TERM=xterm-256color
        log_info "Set TERM to xterm-256color"
    fi

    # Test color support
    if command_exists tput && [ "$(tput colors)" -ge 256 ]; then
        log_success "Terminal supports 256 colors"
    else
        log_warning "Terminal may not support 256 colors. Consider setting TERM=xterm-256color"
    fi
}

# Main installation
main() {
    echo ""
    log_info "Starting terminal setup..."
    echo ""

    check_prerequisites
    install_zsh
    set_zsh_default
    install_oh_my_zsh
    install_powerlevel10k
    install_plugins
    install_fzf
    install_modern_tools
    symlink_dotfiles
    setup_terminal_colors

    echo ""
    log_success "Installation complete!"
    echo ""
    log_info "Next steps:"
    echo "  1. Restart your terminal (or run: exec zsh)"
    echo "  2. If this is your first time, run 'p10k configure' to customize your prompt"
    echo "  3. Enjoy your new terminal setup!"
    echo ""
}

main "$@"
