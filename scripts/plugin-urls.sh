#!/usr/bin/env bash

# External oh-my-zsh plugins
# These will be cloned into $ZSH_CUSTOM/plugins/

declare -A PLUGINS=(
    ["zsh-autosuggestions"]="https://github.com/zsh-users/zsh-autosuggestions"
    ["fast-syntax-highlighting"]="https://github.com/zdharma-continuum/fast-syntax-highlighting"
    ["zsh-completions"]="https://github.com/zsh-users/zsh-completions"
    ["fzf-tab"]="https://github.com/Aloxaf/fzf-tab"
    ["alias-tips"]="https://github.com/djui/alias-tips"
)

# Powerlevel10k theme
P10K_REPO="https://github.com/romkatv/powerlevel10k.git"
