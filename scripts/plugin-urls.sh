#!/usr/bin/env bash

# External oh-my-zsh plugins
# These will be cloned into $ZSH_CUSTOM/plugins/
# Parallel arrays (not associative) for bash 3.x compatibility on macOS — keep indexes aligned

PLUGIN_NAMES=(
    "zsh-autosuggestions"
    "fast-syntax-highlighting"
    "zsh-completions"
    "fzf-tab"
)

PLUGIN_URLS=(
    "https://github.com/zsh-users/zsh-autosuggestions"
    "https://github.com/zdharma-continuum/fast-syntax-highlighting"
    "https://github.com/zsh-users/zsh-completions"
    "https://github.com/Aloxaf/fzf-tab"
)

# Powerlevel10k theme
P10K_REPO="https://github.com/romkatv/powerlevel10k.git"
