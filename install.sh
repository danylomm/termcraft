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

# Detect system architecture (returns both variants for pattern matching)
get_arch() {
    local arch
    arch=$(uname -m)
    case "$arch" in
        x86_64) echo "x86_64" ;;
        aarch64|arm64) echo "aarch64" ;;
        *) echo "$arch" ;;
    esac
}

# Get arm64 variant name (some projects use arm64, others use aarch64)
get_arch_alt() {
    local arch
    arch=$(uname -m)
    case "$arch" in
        x86_64) echo "x86_64" ;;
        aarch64|arm64) echo "arm64" ;;
        *) echo "$arch" ;;
    esac
}

# Install a tool from GitHub releases
install_from_github() {
    local repo="$1"
    local binary_name="$2"
    local asset_pattern="$3"
    local extract_path="$4"  # Path inside archive to the binary (optional)

    if command_exists "$binary_name"; then
        log_success "$binary_name already installed"
        return 0
    fi

    log_info "Installing $binary_name from GitHub..."

    local tmp_dir
    tmp_dir=$(mktemp -d)
    local arch
    arch=$(get_arch)

    # Get latest release asset URL
    local release_url="https://api.github.com/repos/$repo/releases/latest"
    local asset_url
    asset_url=$(curl -fsSL "$release_url" | grep -oP "\"browser_download_url\": \"\K[^\"]*${asset_pattern}[^\"]*" | head -1)

    if [ -z "$asset_url" ]; then
        log_warning "Could not find release for $binary_name (pattern: $asset_pattern)"
        rm -rf "$tmp_dir"
        return 1
    fi

    local filename
    filename=$(basename "$asset_url")

    # Download
    if ! curl -fsSL -o "$tmp_dir/$filename" "$asset_url"; then
        log_warning "Failed to download $binary_name"
        rm -rf "$tmp_dir"
        return 1
    fi

    # Extract and install
    cd "$tmp_dir"
    case "$filename" in
        *.tar.gz|*.tgz)
            tar -xzf "$filename"
            ;;
        *.tar.xz)
            tar -xJf "$filename"
            ;;
        *.zip)
            unzip -q "$filename"
            ;;
        *)
            # Assume it's a raw binary
            chmod +x "$filename"
            sudo mv "$filename" "/usr/local/bin/$binary_name"
            rm -rf "$tmp_dir"
            log_success "$binary_name installed"
            return 0
            ;;
    esac

    # Find and install the binary
    local binary_path
    if [ -n "$extract_path" ]; then
        binary_path="$extract_path"
    else
        binary_path=$(find . -name "$binary_name" -type f -executable 2>/dev/null | head -1)
        if [ -z "$binary_path" ]; then
            binary_path=$(find . -name "$binary_name" -type f 2>/dev/null | head -1)
        fi
    fi

    if [ -n "$binary_path" ] && [ -f "$binary_path" ]; then
        chmod +x "$binary_path"
        sudo mv "$binary_path" "/usr/local/bin/$binary_name"
        log_success "$binary_name installed"
    else
        log_warning "Could not find $binary_name binary in archive"
        rm -rf "$tmp_dir"
        return 1
    fi

    cd - >/dev/null
    rm -rf "$tmp_dir"
    return 0
}

# Install modern CLI tools
install_modern_tools() {
    log_info "Installing modern CLI tools..."

    local arch
    arch=$(get_arch)
    local arch_alt
    arch_alt=$(get_arch_alt)

    # Tools available via apt on Ubuntu
    local apt_tools=(
        "btop:btop:system monitor"
        "ripgrep:rg:fast search"
        "eza:eza:better ls"
        "fd-find:fdfind:better find"
        "bat:batcat:better cat"
        "zoxide:zoxide:smart cd"
        "git-delta:delta:beautiful git diffs"
        "tldr:tldr:quick cheat sheets"
    )

    # Tools that need GitHub binary installation on Ubuntu
    # Format: "repo:binary_name:asset_pattern:description"
    # Note: Some projects use aarch64, others use arm64 for ARM architecture
    local github_tools=()
    if command_exists apt-get; then
        github_tools=(
            "bootandy/dust:dust:dust-.*${arch}.*linux.*gnu.*tar.gz:visual disk usage"
            "chmln/sd:sd:sd-.*${arch}.*linux.*musl:simpler sed"
            "ducaale/xh:xh:xh-.*${arch}.*linux.*musl.*tar.gz:better curl"
            "dalance/procs:procs:procs-.*-${arch}-linux\\.zip:better ps"
            "sxyazi/yazi:yazi:yazi-${arch}.*linux.*musl.*zip:terminal file manager"
            "charmbracelet/glow:glow:glow_.*_Linux_${arch_alt}\\.tar\\.gz:markdown renderer"
        )
    fi

    local apt_to_install=()

    # Check apt tools
    for tool_desc in "${apt_tools[@]}"; do
        local pkg="${tool_desc%%:*}"
        local rest="${tool_desc#*:}"
        local check_cmd="${rest%%:*}"
        local desc="${rest#*:}"

        if command_exists "$check_cmd"; then
            log_success "$desc ($check_cmd) already installed"
        else
            apt_to_install+=("$pkg")
        fi
    done

    # Install apt packages
    if [ ${#apt_to_install[@]} -gt 0 ]; then
        log_info "Installing from apt: ${apt_to_install[*]}"

        if command_exists apt-get; then
            local apt_update_output
            if ! apt_update_output=$(sudo apt-get update 2>&1); then
                log_warning "apt-get update encountered errors (continuing anyway):"
                echo "$apt_update_output" | grep -E "^(E:|W:)" | head -5
            elif echo "$apt_update_output" | grep -qE "^E:"; then
                log_warning "apt-get update reported errors (some repositories may be unavailable):"
                echo "$apt_update_output" | grep -E "^E:" | head -3
                log_info "Continuing with package installation..."
            fi

            if ! sudo apt-get install -y "${apt_to_install[@]}"; then
                log_warning "Some apt packages failed to install"
            fi
        elif command_exists dnf; then
            sudo dnf install -y "${apt_to_install[@]}" || log_warning "Some packages failed to install"
        elif command_exists pacman; then
            sudo pacman -S --noconfirm "${apt_to_install[@]}" || log_warning "Some packages failed to install"
        elif command_exists brew; then
            brew install "${apt_to_install[@]}" || log_warning "Some packages failed to install"
        fi
    fi

    # Install GitHub-release tools (for apt-based systems)
    if [ ${#github_tools[@]} -gt 0 ]; then
        log_info "Installing tools from GitHub releases..."
        for tool_desc in "${github_tools[@]}"; do
            local repo="${tool_desc%%:*}"
            local rest="${tool_desc#*:}"
            local binary="${rest%%:*}"
            rest="${rest#*:}"
            local pattern="${rest%%:*}"
            local desc="${rest#*:}"

            if command_exists "$binary"; then
                log_success "$desc ($binary) already installed"
            else
                install_from_github "$repo" "$binary" "$pattern" || log_warning "Failed to install $binary"
            fi
        done
    fi

    log_success "Modern CLI tools installation complete"
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
