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

# Helper function to get the default branch (main/master)
rootbranch() {
  local branch=$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null | sed 's|^origin/||')
  if [ -n "$branch" ]; then
    echo "$branch"
  elif git show-ref --verify --quiet refs/heads/main; then
    echo "main"
  elif git show-ref --verify --quiet refs/heads/master; then
    echo "master"
  else
    echo "main"
  fi
}

# Status & Info
alias gis='git status'
alias gisb='git status -sb'                    # Short branch status
alias gib='git branch'
alias giba='git branch -a'                     # Show all branches (local + remote)
alias gibd='git branch -d'                     # Delete branch (safe)
alias gibD='git branch -D'                     # Force delete branch

# Log & History
alias gil='git log'
alias gilog='git log --oneline --graph --decorate --all'
alias gilp='git log -p'                        # Log with patches
alias gils='git log --stat'                    # Log with file stats
alias gilg='git log --graph --oneline --all'   # Visual branch graph
alias gilast='git log -1 HEAD --stat'          # Show last commit

# Add & Commit
alias gia='git add .'
alias giaa='git add --all'
alias giap='git add -p'                        # Interactive staging
alias gim='git commit -m'
alias gima='git commit -am'                    # Add all and commit
alias gimend='git commit --amend'              # Amend last commit
alias gimendn='git commit --amend --no-edit'   # Amend without changing message

# Diff
alias gif='git diff'
alias giff='git diff --cached'                 # Diff of staged changes
alias gifw='git diff --word-diff'              # Word-level diff
alias gifn='git diff --name-only'              # Show only file names

# Push & Pull
alias gush='git push origin "$(git branch --show-current)"'
alias gushf='git push --force-with-lease'      # Safer force push
alias gull='git pull'
alias gullm='git fetch origin && git rebase "$(rootbranch)"'
alias gullr='git pull --rebase'                # Pull with rebase

# Fetch
alias gifa='git fetch --all'
alias gifap='git fetch --all --prune'          # Fetch and prune deleted branches

# Checkout & Branch
alias gco='git checkout'
alias gcb='git checkout -b'                    # Create and checkout new branch
alias gcm='git checkout "$(rootbranch)"'       # Checkout main/master
alias gc-='git checkout -'                     # Checkout previous branch

# Reset & Undo
alias girha='git reset --hard'
alias girhah='git reset --hard HEAD'           # Reset to HEAD
alias girh='git reset HEAD'                    # Unstage all
alias girh1='git reset HEAD~1'                 # Undo last commit (keep changes)
alias girhu='git reset --hard @{u}'            # Reset to upstream

# Stash
alias gist='git stash'
alias gistp='git stash pop'
alias gistl='git stash list'
alias gistd='git stash drop'
alias gists='git stash show -p'                # Show stash contents

# Clone & Remote
alias glone='git clone'
alias gloned='git clone --depth=1'             # Shallow clone (faster)
alias gir='git remote -v'
alias gira='git remote add'
alias girr='git remote remove'

# Merge & Rebase
alias gimnf='git merge --no-ff'                # Merge with merge commit
alias gire='git rebase'
alias girei='git rebase -i'                    # Interactive rebase
alias girec='git rebase --continue'
alias girea='git rebase --abort'

# Tags
alias gtag='git tag'
alias gta='git tag -a'                         # Annotated tag
alias gtd='git tag -d'                         # Delete tag
alias gtl='git tag -l'                         # List tags

# Worktree (manage multiple working directories)
alias gwt='git worktree'
alias gwta='git worktree add'
alias gwtl='git worktree list'
alias gwtr='git worktree remove'

# Cleanup & Maintenance
alias gclean='git clean -fd'                   # Remove untracked files/dirs
alias gprune='git remote prune origin'         # Clean up deleted remote branches
alias ggc='git gc --aggressive'                # Garbage collection

# Shortcuts for common workflows
alias gasave='git add -A && git commit -m "WIP: work in progress"'
alias gaundo='git reset --soft HEAD~1'         # Undo last commit, keep changes staged
alias gawip='git add -A && git commit -m "WIP" --no-verify'
alias gamend='git commit --amend --no-edit'    # Quick amend without editor

# ============================================================================
# Development Aliases
# ============================================================================

# Quick directory listing
alias lsd='ls -d */'

# Find processes
psg() {
  if [ -z "$1" ]; then
    echo "Usage: psg <process_name>"
    return 1
  fi
  ps aux | grep -i "$1" | grep -v grep
}

# Disk usage
alias duh='du -h -d 1'  # Works on macOS (and GNU with coreutils)
alias dfs='df -h'

# Network
alias myip='curl -s ifconfig.me'
alias ports='sudo lsof -iTCP -sTCP:LISTEN -n -P'

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
