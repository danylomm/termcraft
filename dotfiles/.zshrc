# Fix for Ghostty and other terminals - ensure 256 color support
export TERM=xterm-256color

# PATH configuration
# Homebrew (macOS) - puts newer bash and other tools first
[[ -d "/opt/homebrew/bin" ]] && export PATH="/opt/homebrew/bin:$PATH"
# UV tools and other user binaries
[[ -d "$HOME/.local/bin" ]] && export PATH="$HOME/.local/bin:$PATH"

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time Oh My Zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="powerlevel10k/powerlevel10k"

# Uncomment the following line to enable command auto-correction.
ENABLE_CORRECTION="true"

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(
	z
	git
	zsh-autosuggestions
	sudo
	fast-syntax-highlighting
	zsh-completions
	fzf-tab
	docker
	extract
	copypath
	copyfile
	alias-tips
	colored-man-pages
	pip
)

source $ZSH/oh-my-zsh.sh

# fzf keybindings/completion if present
[ -f "$HOME/.fzf.zsh" ] && source "$HOME/.fzf.zsh"

# fzf-tab completion (guarded so it won't error if missing)
_fzf_tab="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/fzf-tab/fzf-tab.plugin.zsh"
[[ -r "$_fzf_tab" ]] && source "$_fzf_tab"
unset _fzf_tab

# Add local bin to PATH
export PATH="$HOME/.local/bin:$PATH"

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Aliases
alias view='feh'

# Interactive alias browser with fzf
fzf-alias() {
  local sel
  sel=$(alias | fzf --height 40% --reverse --preview 'echo {}' | cut -d= -f1)
  [[ -n "$sel" ]] && print -z "$sel"
}
alias als='fzf-alias'

# Modern CLI tool aliases (Ubuntu uses different binary names)
command -v fdfind >/dev/null 2>&1 && alias fd='fdfind'
command -v batcat >/dev/null 2>&1 && alias bat='batcat'

# Source machine-specific configurations (if exists)
# Use this file for GPU configs, secrets, and other machine-specific settings
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
