# allyas - Personal shell aliases
# Compatible with both bash and zsh
# Installed via Homebrew: brew install rezkam/allyas/allyas
#
# To use these aliases, add this line to your shell configuration:
#   [ -f $(brew --prefix)/etc/allyas.sh ] && . $(brew --prefix)/etc/allyas.sh

# Display all aliases and functions defined in this file
allyas() {
  local source_file=""

  if [ -n "${ALLYAS_SOURCE_FILE:-}" ] && [ -f "${ALLYAS_SOURCE_FILE}" ]; then
    source_file="${ALLYAS_SOURCE_FILE}"
  elif [ -n "${BASH_SOURCE:-}" ]; then
    source_file="${BASH_SOURCE[0]}"
  elif [ -n "${ZSH_VERSION:-}" ]; then
    eval 'source_file="${(%):-%x}"'
  else
    source_file="$0"
  fi

  if [ -z "$source_file" ] || [ ! -f "$source_file" ]; then
    echo "allyas: unable to locate the definitions file (${source_file:-unknown})"
    return 1
  fi

  awk -f /dev/stdin "$source_file" <<'AWK'
    function trim(s) {
      sub(/^[[:space:]]+/, "", s)
      sub(/[[:space:]]+$/, "", s)
      return s
    }

    function strip_quotes(s) {
      s = trim(s)
      if (length(s) >= 2) {
        first = substr(s, 1, 1)
        last = substr(s, length(s), 1)
        if ((first == "\"" && last == "\"") || (first == "'" && last == "'")) {
          s = substr(s, 2, length(s) - 2)
        }
      }
      return s
    }

    function add_entry(type, text, desc, extra) {
      entry_count++
      entry_type[entry_count] = type
      entry_text[entry_count] = text
      entry_desc[entry_count] = desc
      entry_extra[entry_count] = extra
      if (type == "alias" || type == "function") {
        current_length = length(text)
        if (current_length > max_name_width) {
          max_name_width = current_length
        }
      }
    }

    function flush_heading() {
      if (pending_heading == "") {
        return
      }
      n = split(pending_heading, lines, "\n")
      for (i = 1; i <= n; i++) {
        add_entry("heading", lines[i], "", "")
      }
      pending_heading = ""
    }

    function show_alias(name, command, desc) {
      add_entry("alias", name, desc, command)
    }

    function show_function(name, desc) {
      add_entry("function", name, desc, "")
    }

    BEGIN {
      section = ""
      pending_heading = ""
      next_section = 0
      started = 0
      in_heredoc = 0
      heredoc_end = ""
      skip_next_function = 0
      skip_separator = 0
      entry_count = 0
      max_name_width = 0
      function_depth = 0
    }

    {
      line = $0
      trimmed = line
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", trimmed)

      if (in_heredoc) {
        if (trimmed == heredoc_end) {
          in_heredoc = 0
        }
        next
      }

      if (!in_heredoc && line ~ /<<'AWK'/) {
        in_heredoc = 1
        heredoc_end = "AWK"
        next
      }

      if (!in_heredoc && line ~ /^[[:space:]]*}[[:space:]]*$/) {
        if (function_depth > 0) {
          function_depth--
        }
        pending_heading = ""
        next
      }

      if (function_depth > 0) {
        next
      }

      if (line ~ /^#[[:space:]]*=+/) {
        if (skip_separator) {
          skip_separator = 0
          next
        }
        next_section = 1
        pending_heading = ""
        next
      }

      if (next_section && line ~ /^#[[:space:]]*/) {
        section = line
        sub(/^#[[:space:]]*/, "", section)
        section = trim(section)
        if (section != "") {
          add_entry("section", section, "", "")
          started = 1
          skip_separator = 1
        }
        next_section = 0
        pending_heading = ""
        next
      }

      if (!started) {
        next
      }

      if (trimmed == "") {
        pending_heading = ""
        next
      }

      if (line ~ /^[[:space:]]*#/) {
        comment = line
        sub(/^#[[:space:]]*/, "", comment)
        comment = trim(comment)
        if (comment ~ /allyas:ignore/) {
          skip_next_function = 1
          next
        }
        if (comment != "") {
          if (pending_heading != "") {
            flush_heading()
          }
          pending_heading = comment
        }
        next
      }

      if (line ~ /^[[:space:]]*alias[[:space:]]+/) {
        alias_line = line
        sub(/^[[:space:]]*alias[[:space:]]+/, "", alias_line)
        eq = index(alias_line, "=")
        if (eq <= 0) {
          next
        }
        name = trim(substr(alias_line, 1, eq - 1))
        rest = substr(alias_line, eq + 1)
        desc = ""
        hash = index(rest, "#")
        if (hash > 0) {
          desc = trim(substr(rest, hash + 1))
          rest = substr(rest, 1, hash - 1)
        }
        command = strip_quotes(rest)
        command = trim(command)
        show_alias(name, command, desc)
        next
      }

      if (line ~ /^[[:space:]]*[A-Za-z0-9_]+[[:space:]]*\(\)[[:space:]]*{/) {
        func_line = line
        sub(/^[[:space:]]*/, "", func_line)
        sub(/\(.*/, "", func_line)
        name = trim(func_line)
        desc = pending_heading
        if (desc == "") {
          desc = "Shell function"
        }
        if (!(name ~ /^_/ || skip_next_function)) {
          show_function(name, desc)
        }
        pending_heading = ""
        skip_next_function = 0
        function_depth++
        next
      }
    }

    END {
      if (max_name_width < 1) {
        max_name_width = 1
      }
      item_format = sprintf("  %%-%ds  %%s", max_name_width)
      spaced = 0
      for (i = 1; i <= entry_count; i++) {
        type = entry_type[i]
        text = entry_text[i]
        desc = entry_desc[i]
        extra = entry_extra[i]
        if (type == "section") {
          if (spaced) {
            print ""
          }
          print text
          spaced = 1
        } else if (type == "heading") {
          print "  " text
        } else if (type == "alias") {
          display = extra
          if (desc != "") {
            display = desc
          }
          print sprintf(item_format, text, display)
        } else if (type == "function") {
          print sprintf(item_format, text, desc)
        }
      }
    }

AWK
}

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

# Grep
alias grep='grep --color=auto'  # Colorize grep output

# File listing variants
alias lt='ls -ltrh'  # Sort by time, newest last
alias lsize='ls -lSrh'  # Sort by size, smallest first
alias count='find . -type f | wc -l'  # Count files in directory

# Time & Date
alias now='date +"%Y-%m-%d %H:%M:%S"'  # Current date and time
alias week='date +%V'  # Current week number

# Quick navigation
alias cdtemp='cd $(mktemp -d)'  # Create and cd to temp directory

# ============================================================================
# Git Aliases
# ============================================================================

# allyas:ignore Helper function to get the current branch name
get_current_branch() {
  git branch --show-current 2>/dev/null
}

# allyas:ignore Helper function to get the remote for a branch
get_remote() {
  local branch="${1:-$(get_current_branch)}"
  local remote
  remote=$(git config --get branch."$branch".remote 2>/dev/null)
  echo "${remote:-origin}"
}

# allyas:ignore Helper function to get the remote used for pushes
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

# allyas:ignore Helper function to get the default branch
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

# allyas:ignore Helper to push the current branch with optional git push flags
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

# allyas:ignore Portable confirmation prompt for both bash and zsh
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
# Push current branch to its configured remote
gush() {
  push_current_branch
}

# Force push with lease (with same safety checks)
gushf() {
  push_current_branch --force-with-lease
}

alias gull='git pull'

# Pull and rebase from the default branch (main/master)
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
# Hard reset with confirmation (discards all uncommitted changes)
girha() {
  echo "⚠️  WARNING: This will discard ALL uncommitted changes!"
  if confirm_action "Are you sure? [y/N] "; then
    git reset --hard "$@"
  fi
}

# Hard reset to HEAD with confirmation (discards all uncommitted changes)
girhah() {
  echo "⚠️  WARNING: This will reset to HEAD and discard all changes!"
  if confirm_action "Are you sure? [y/N] "; then
    git reset --hard HEAD
  fi
}

alias girh='git reset HEAD'                    # Unstage all
alias girh1='git reset HEAD~1'                 # Undo last commit (keep changes)

# Hard reset to upstream with confirmation (discards all local changes)
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
# Remove untracked files and directories with confirmation
gclean() {
  echo "⚠️  WARNING: This will permanently delete all untracked files and directories!"
  git clean -fd --dry-run
  if confirm_action "Proceed with deletion? [y/N] "; then
    git clean -fd
  fi
}

# Prune deleted remote branches from local repository
gprune() {
  local remote
  remote=$(get_remote)
  git remote prune "$remote"
}

# Run aggressive garbage collection to optimize repository
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

# Find files and directories
# Find files by name (usage: findf '*.txt')
findf() {
  if [ -z "$1" ]; then
    echo "Usage: findf <filename_pattern>"
    return 1
  fi
  find . -type f -name "$1"
}

# Find directories by name (usage: findd 'dirname')
findd() {
  if [ -z "$1" ]; then
    echo "Usage: findd <dirname_pattern>"
    return 1
  fi
  find . -type d -name "$1"
}

# Find processes
# Search for running processes by name
psg() {
  if [ -z "$1" ]; then
    echo "Usage: psg <process_name>"
    return 1
  fi
  ps aux | grep -i -- "$1" | grep -v grep
}

# Config file editing
alias zshrc='nano ~/.zshrc'  # Edit zsh config
alias bashrc='nano ~/.bashrc'  # Edit bash config

# Disk usage
alias duh='du -h -d 1'  # Works on macOS (and GNU with coreutils)
alias dfs='df -h'

# Network
alias myip='curl -s ifconfig.me'
alias ports='sudo lsof -iTCP -sTCP:LISTEN -n -P'

# ============================================================================
# macOS Specific Aliases
# ============================================================================

# Clipboard shortcuts
alias copy='pbcopy'  # Copy to clipboard
alias paste='pbpaste'  # Paste from clipboard
alias cpwd='pwd | pbcopy'  # Copy current directory path

# Copy full path of a file to clipboard
cpf() {
  if [ -z "$1" ]; then
    echo "Usage: cpf <file>"
    echo "Copies the absolute path of the file to clipboard"
    return 1
  fi

  if [ ! -e "$1" ]; then
    echo "Error: '$1' does not exist"
    return 1
  fi

  readlink -f "$1" | pbcopy
  echo "Copied: $(pbpaste)"
}

# Finder shortcuts
alias o='open .'  # Open current directory in Finder

# Show/hide hidden files in Finder
alias showfiles='defaults write com.apple.finder AppleShowAllFiles YES; killall Finder'
alias hidefiles='defaults write com.apple.finder AppleShowAllFiles NO; killall Finder'

# Flush DNS cache
alias flushdns='sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder'
