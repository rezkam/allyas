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

# Safety nets (only in interactive shells to avoid breaking automation)
case $- in
  *i*)
    alias rm='rm -i'
    alias cp='cp -i'
    alias mv='mv -i'
    ;;
esac

# ============================================================================
# Git Aliases
# ============================================================================

# Helper function to get the current branch name
get_current_branch() {
  git branch --show-current 2>/dev/null
}

# Helper function to get the remote for a branch
get_remote() {
  local branch="${1:-$(get_current_branch)}"
  local remote
  remote=$(git config --get branch."$branch".remote 2>/dev/null)
  echo "${remote:-origin}"
}

# Helper function to get the remote used for pushes
get_push_remote() {
  local branch="${1:-$(get_current_branch)}"
  local remote=""

  if [ -n "$branch" ]; then
    remote=$(git config --get branch."$branch".pushRemote 2>/dev/null)
  fi

  if [ -z "$remote" ]; then
    remote=$(git config --get remote.pushDefault 2>/dev/null)
  fi

  if [ -z "$remote" ] && [ -n "$branch" ]; then
    remote=$(git config --get branch."$branch".remote 2>/dev/null)
  fi

  echo "${remote:-origin}"
}

# Helper function to get the default branch
default_branch() {
  local branch remote

  # Get the remote for the current branch
  remote=$(get_remote)

  # Try remote HEAD
  branch=$(git symbolic-ref --short refs/remotes/"$remote"/HEAD 2>/dev/null | sed "s|^$remote/||")

  # Try git remote show (slower but more reliable)
  if [ -z "$branch" ]; then
    branch=$(git remote show "$remote" 2>/dev/null | grep "HEAD branch" | sed 's/.*: //')
    # Treat "(unknown)" as not found
    if [ "$branch" = "(unknown)" ]; then
      branch=""
    fi
  fi

  # Fall back to checking for common default branches
  if [ -z "$branch" ]; then
    if git show-ref --verify --quiet refs/heads/main 2>/dev/null; then
      branch="main"
    elif git show-ref --verify --quiet refs/heads/master 2>/dev/null; then
      branch="master"
    elif git show-ref --verify --quiet refs/heads/develop 2>/dev/null; then
      branch="develop"
    else
      branch=$(git symbolic-ref --short HEAD 2>/dev/null)
    fi
  fi

  # Final fallback if everything else failed
  if [ -z "$branch" ]; then
    if git show-ref --verify --quiet refs/heads/main 2>/dev/null; then
      branch="main"
    elif git show-ref --verify --quiet refs/heads/master 2>/dev/null; then
      branch="master"
    elif git show-ref --verify --quiet refs/heads/develop 2>/dev/null; then
      branch="develop"
    else
      branch="main"
    fi
  fi

  echo "$branch"
}

# Helper to push the current branch with optional git push flags
push_current_branch() {
  local branch remote
  branch=$(get_current_branch)
  if [ -z "$branch" ]; then
    echo "❌ Cannot push: detached HEAD state (not on any branch)"
    echo "Use 'git push <remote> HEAD:<branch-name>' to push explicitly"
    return 1
  fi

  remote=$(get_push_remote "$branch")

  if ! git push "$@" "$remote" "$branch"; then
    echo "❌ Push failed"
    return 1
  fi
}

# Portable confirmation prompt for both bash and zsh
confirm_action() {
  local prompt="${1:-Are you sure? [y/N] }"
  local reply
  printf "%s" "$prompt"
  read -r reply
  echo
  case "$reply" in
    [Yy]*) return 0 ;;
    *) return 1 ;;
  esac
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
gush() {
  push_current_branch
}

# Force push with lease (with same safety checks)
gushf() {
  push_current_branch --force-with-lease
}

alias gull='git pull'

gullm() {
  local remote branch
  remote=$(get_remote)
  branch=$(default_branch)

  if ! git fetch "$remote"; then
    echo "❌ Fetch failed"
    return 1
  fi

  if ! git rebase "$remote/$branch"; then
    echo "❌ Rebase failed - you may need to resolve conflicts"
    return 1
  fi
}

alias gullr='git pull --rebase'                # Pull with rebase

# Fetch
alias gifa='git fetch --all'
alias gifap='git fetch --all --prune'          # Fetch and prune deleted branches

# Checkout & Branch
alias gco='git checkout'
alias gcb='git checkout -b'                    # Create and checkout new branch
alias gcm='git checkout "$(default_branch)"'       # Checkout main/master
alias gc-='git checkout -'                     # Checkout previous branch

# Reset & Undo
girha() {
  echo "⚠️  WARNING: This will discard ALL uncommitted changes!"
  if confirm_action "Are you sure? [y/N] "; then
    git reset --hard "$@"
  fi
}

girhah() {
  echo "⚠️  WARNING: This will reset to HEAD and discard all changes!"
  if confirm_action "Are you sure? [y/N] "; then
    git reset --hard HEAD
  fi
}

alias girh='git reset HEAD'                    # Unstage all
alias girh1='git reset HEAD~1'                 # Undo last commit (keep changes)

girhu() {
  if ! git rev-parse --abbrev-ref @{u} >/dev/null 2>&1; then
    echo "❌ No upstream configured for current branch"
    return 1
  fi
  echo "⚠️  WARNING: This will reset to upstream and discard all local changes!"
  if confirm_action "Are you sure? [y/N] "; then
    git reset --hard @{u}
  fi
}

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
unalias gclean 2>/dev/null || true
gclean() {
  echo "⚠️  WARNING: This will permanently delete all untracked files and directories!"
  git clean -fd --dry-run
  if confirm_action "Proceed with deletion? [y/N] "; then
    git clean -fd
  fi
}

gprune() {
  local remote
  remote=$(get_remote)
  git remote prune "$remote"
}

ggc() {
  echo "⚠️  WARNING: Aggressive garbage collection can take a long time!"
  if confirm_action "Continue? [y/N] "; then
    git gc --aggressive
  fi
}

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
  ps aux | grep -i -- "$1" | grep -v grep
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
