#!/bin/bash
# allyas - Personal shell aliases
# Compatible with both bash and zsh
# Installed via Homebrew: brew install rezkam/allyas/allyas
#
# To use these aliases, add this line to your shell configuration:
#   [ -f $(brew --prefix)/etc/allyas.sh ] && . $(brew --prefix)/etc/allyas.sh

# ============================================================================
# General Aliases
# ============================================================================

# List files with details
alias ll='ls -lah'
alias la='ls -A'
alias l='ls -CF'

# Navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# Safety nets
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# ============================================================================
# Git Aliases
# ============================================================================

alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git pull'
alias gd='git diff'
alias gco='git checkout'
alias gb='git branch'
alias glog='git log --oneline --graph --decorate'

# ============================================================================
# Development Aliases
# ============================================================================

# Quick directory listing
alias lsd='ls -d */'

# Find processes
alias psg='ps aux | grep -v grep | grep -i -e VSZ -e'

# Disk usage
alias duh='du -h --max-depth=1'
alias dfs='df -h'

# Network
alias myip='curl -s ifconfig.me'
alias ports='netstat -tulanp'

# ============================================================================
# macOS Specific Aliases
# ============================================================================

# Show/hide hidden files in Finder
alias showfiles='defaults write com.apple.finder AppleShowAllFiles YES; killall Finder'
alias hidefiles='defaults write com.apple.finder AppleShowAllFiles NO; killall Finder'

# Flush DNS cache
alias flushdns='sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder'

# ============================================================================
# Custom Aliases - Add your own below
# ============================================================================

# Add your personal aliases here
