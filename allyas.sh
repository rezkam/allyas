# allyas - Personal shell aliases
# Compatible with both bash and zsh
# Installed via Homebrew: brew install rezkam/allyas/allyas
#
# To use these aliases, add this line to your shell configuration:
#   [ -f $(brew --prefix)/etc/allyas.sh ] && . $(brew --prefix)/etc/allyas.sh

# Determine helpers directory location
# Resolve symlinks to find the actual installation directory
if [ -n "${BASH_SOURCE:-}" ]; then
  _allyas_source="${BASH_SOURCE[0]}"
elif [ -n "${ZSH_VERSION:-}" ]; then
  eval '_allyas_source="${(%):-%x}"'
else
  _allyas_source="$0"
fi

# Resolve symlink to real path
if [ -L "$_allyas_source" ]; then
  _allyas_source="$(readlink "$_allyas_source")"
fi

HELPERS_DIR="$(dirname "$_allyas_source")/helpers"
unset _allyas_source

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

      if (line ~ /^[[:space:]]*[A-Za-z0-9_-]+[[:space:]]*\(\)[[:space:]]*{/) {
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
# Remove untracked files and directories with confirmation
unalias gclean 2>/dev/null || true
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

# Show all listening TCP ports (requires sudo to see all processes)
unalias ports 2>/dev/null || true
ports() {
  echo "Requesting sudo access to view all listening TCP ports..."
  sudo lsof -iTCP -sTCP:LISTEN -n -P
}

# Analyze listening ports with LLM to identify suspicious processes
portswhy() {
  echo "Requesting sudo access to analyze all listening TCP ports..."
  echo "This is needed to collect process information for security analysis."
  echo ""
  echo "🔍 Scanning listening ports..."
  LSOF_FILE="$(mktemp /tmp/portswhy.lsof.XXXXXX)" || return 1
  PIDS_FILE="$(mktemp /tmp/portswhy.pids.XXXXXX)" || return 1
  PS_FILE="$(mktemp /tmp/portswhy.ps.XXXXXX)" || return 1
  DATA_FILE="$(mktemp /tmp/portswhy.data.XXXXXX)" || return 1
  SIG_FILE="$(mktemp /tmp/portswhy.sig.XXXXXX)" || return 1
  OUT_MD="$(mktemp /tmp/portswhy.out.XXXXXX).md" || return 1

  FAIL=0
  cleanup() {
    if [ "$FAIL" -eq 0 ]; then
      rm -f "$LSOF_FILE" "$PIDS_FILE" "$PS_FILE" "$DATA_FILE" "$SIG_FILE" "$OUT_MD"
    else
      echo "Kept debug files:"
      echo "  lsof  : $LSOF_FILE"
      echo "  pids  : $PIDS_FILE"
      echo "  ps    : $PS_FILE"
      echo "  data  : $DATA_FILE"
      echo "  sig   : $SIG_FILE"
      echo "  out   : $OUT_MD"
    fi
  }
  trap cleanup EXIT

  if ! sudo lsof -iTCP -sTCP:LISTEN -n -P >"$LSOF_FILE" 2>&1; then
    FAIL=1
    echo "Error: Failed to run 'sudo lsof'. Check sudo access and that lsof is installed."
    return 1
  fi

  if [ ! -s "$LSOF_FILE" ]; then
    echo "No listening TCP ports found."
    return 0
  fi

  awk 'NR>1 && $2 ~ /^[0-9]+$/ {print $2}' "$LSOF_FILE" | sort -n | uniq >"$PIDS_FILE"
  if [ ! -s "$PIDS_FILE" ]; then
    FAIL=1
    echo "Failed to extract numeric PIDs from lsof."
    sed -n '1,25p' "$LSOF_FILE"
    return 1
  fi

  PID_CSV="$(tr -d '\r' <"$PIDS_FILE" | tr '\n' ',' | sed 's/,$//')"
  if ! printf "%s" "$PID_CSV" | grep -Eq '^[0-9]+(,[0-9]+)*$'; then
    FAIL=1
    echo "PID list corrupted: $PID_CSV"
    echo "Inspect: $PIDS_FILE"
    return 1
  fi

  ps -p "$PID_CSV" -o pid=,ppid=,user=,start=,etime=,%cpu=,%mem=,comm=,command= 2>/dev/null \
    | awk '
        {
          pid=$1; ppid=$2; user=$3; start=$4; etime=$5; cpu=$6; mem=$7; comm=$8
          $1=$2=$3=$4=$5=$6=$7=$8=""
          sub(/^[ \t]+/, "")
          cmd=$0
          printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n", pid, ppid, user, start, etime, cpu, mem, comm, cmd
        }
      ' >"$PS_FILE"

  if [ ! -s "$PS_FILE" ]; then
    FAIL=1
    echo "ps output empty."
    echo "PID_CSV was: $PID_CSV"
    return 1
  fi

  awk -F'\t' -v PIDS_FILE="$PIDS_FILE" '
    FNR==NR {
      pid=$1
      ppid[pid]=$2; user[pid]=$3; start[pid]=$4; etime[pid]=$5; cpu[pid]=$6; mem[pid]=$7
      comm[pid]=$8; cmd[pid]=$9

      exec=cmd[pid]; sub(/[[:space:]].*$/, "", exec); exe[pid]=exec

      app="(none)"
      if (match(cmd[pid], /\/Applications\/[^\/]+\.app/)) app=substr(cmd[pid], RSTART, RLENGTH)
      appb[pid]=app
      next
    }
    FNR==1 { next }
    {
      n = split($0, f, /[ \t]+/)
      if (f[2] !~ /^[0-9]+$/) next

      pid = f[2]
      addr = f[9]

      gsub(/^TCP:/, "", addr)
      gsub(/^UDP:/, "", addr)
      gsub(/[[:space:]]+/, "", addr)

      if (addr != "" && addr != "TCP" && addr != "UDP" && addr != "(LISTEN)") {
        listen[pid]=(listen[pid]?listen[pid]","addr:addr)
      }
    }
    END {
      print "MACOS_LISTENERS|src=lsof+ps"
      while ((getline p < PIDS_FILE) > 0) {
        if (p ~ /^[0-9]+$/) {
          lp = (listen[p]?listen[p]:"unknown")
          printf "### pid=%s ppid=%s user=%s start=%s etime=%s cpu=%s mem=%s comm=%s exec=%s app=%s listen=%s cmd=%s\n",
            p,
            (ppid[p]?ppid[p]:"unknown"),
            (user[p]?user[p]:"unknown"),
            (start[p]?start[p]:"unknown"),
            (etime[p]?etime[p]:"unknown"),
            (cpu[p]?cpu[p]:"unknown"),
            (mem[p]?mem[p]:"unknown"),
            (comm[p]?comm[p]:"unknown"),
            (exe[p]?exe[p]:"unknown"),
            (appb[p]?appb[p]:"(none)"),
            lp,
            (cmd[p]?cmd[p]:"unknown")
        }
      }
      close(PIDS_FILE)
    }
  ' "$PS_FILE" "$LSOF_FILE" >"$DATA_FILE"

  if ! grep -q '^### pid=' "$DATA_FILE"; then
    FAIL=1
    echo "DATA build failed."
    echo "First 30 lines of lsof:"
    sed -n '1,30p' "$LSOF_FILE"
    echo "First 30 lines of ps:"
    sed -n '1,30p' "$PS_FILE"
    echo "First 30 lines of data:"
    sed -n '1,30p' "$DATA_FILE"
    return 1
  fi

  echo "🔐 Checking code signatures..."
  : >"$SIG_FILE"
  awk '
    /^### / {
      app=""; exec=""

      if (match($0, /app=(\/[^ ]+( [^ ]+)*\.app)( |$)/, arr)) {
        app = arr[1]
      } else if (match($0, / app=([^ ]+)/, arr)) {
        app = arr[1]
      }

      if (match($0, /exec=(\/[^ ]+( [^ ]+)*\.app)( |$)/, arr)) {
        exec = arr[1]
      } else if (match($0, / exec=([^ ]+)/, arr)) {
        exec = arr[1]
      }

      t=app
      if (t=="" || t=="(none)") t=exec
      if (t ~ /^\//) print t
    }
  ' "$DATA_FILE" | sort -u | head -n 30 | while IFS= read -r target; do
    ident="$(codesign -dv --verbose=4 "$target" 2>&1 | awk -F= "/^Identifier=/ {print \$2; exit}")"
    team="$(codesign -dv --verbose=4 "$target" 2>&1 | awk -F= "/^TeamIdentifier=/ {print \$2; exit}")"
    auth="$(codesign -dv --verbose=4 "$target" 2>&1 | awk -F= "/^Authority=/ {print \$2; exit}")"
    [ -z "$ident" ] && ident="unknown"
    [ -z "$team" ] && team="unknown"
    [ -z "$auth" ] && auth="unknown"
    printf "SIG target=%s identifier=%s team=%s authority=%s\n" "$target" "$ident" "$team" "$auth" >>"$SIG_FILE"
  done

  local instructions='Output Markdown only.
Do not repeat the prompt. Do not explain methodology.
Do not run, suggest running, or simulate any shell commands.

Use only DATA + SIGNATURE_INFO + general knowledge.

When legitimacy cannot be determined from signature data alone (unknown signatures, unfamiliar vendors, suspicious patterns),
you SHOULD use web search to validate the TeamIdentifier, Authority, and bundle identifier.
State "verified via web search: [brief finding]" when you use it, or "legitimacy unclear - recommend investigation" if web search is unavailable or inconclusive.

Important:
- Start with suspicious or unusual listeners first, then normal ones.
- If listen=unknown for a PID, you MUST NOT claim it is "not suspicious" based on ports, because ports are missing.
  Instead say "listen address cannot be determined from provided data" and base suspicion only on app/cmd/signature context.
- Do not be short. Be concrete and cite fields (app, exec, cmd, ppid, user, listen, signature lines).

Output format (no tables):
## 🚨 Suspicious or Unusual Listening Processes
For each suspicious PID:
### PID <pid> <app-or-exec>
- Listen: <listen>
- Category: <category>
- What it is:
- Evidence (from fields):
- Legitimacy (from signatures and optionally web):
- Notes:

If none are suspicious, write exactly: "No suspicious listeners detected." (but only if listen values are present and nothing looks odd)

## ✅ Normal / Expected Listening Processes
Same per-PID blocks, shorter than suspicious blocks but still specific.

Categories: system | third-party | dev-tool | suspicious
Rules:
- Use listen= exactly (no invented ranges)
- Prefer app= for the displayed name when present, else exec=
- If you cannot prove something, say "cannot be determined from provided data"'

  local data
  data="$(cat "$DATA_FILE")"
  data="$data

SIGNATURE_INFO:
$(cat "$SIG_FILE")"

  echo "🤖 Analyzing with LLM (${ALLYAS_LLM:-codex})..."
  # Run LLM analysis
  # Note: stdout (markdown) goes to $OUT_MD, stderr (errors) goes to terminal
  if ! llm_analyze "$instructions" "$data" >"$OUT_MD"; then
    FAIL=1
    return 1
  fi

  # Check if we got actual content
  if [ ! -s "$OUT_MD" ]; then
    FAIL=1
    echo ""
    echo "❌ No analysis output received from LLM"
    return 1
  fi

  echo ""
  if command -v glow >/dev/null 2>&1; then
    glow -p "$OUT_MD"
  else
    cat "$OUT_MD"
    echo ""
    echo "Tip: Install glow for better markdown rendering: brew install glow"
  fi
}

# ============================================================================
# LLM Utilities
# ============================================================================
# Implementations in helpers/llm.sh

# Switch between different LLM providers (codex, claude, gemini)
# Implemented in: helpers/llm.sh
llm-use() { :; }

# List all available LLM providers and show which one is active
# Implemented in: helpers/llm.sh
llm-list() { :; }

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

# Copy file contents to clipboard
ccopy() {
  if [ -z "$1" ]; then
    echo "Usage: ccopy <file>"
    echo "Copies the contents of the file to clipboard"
    return 1
  fi

  if [ ! -f "$1" ]; then
    echo "Error: '$1' is not a file or does not exist"
    return 1
  fi

  cat "$1" | pbcopy
  echo "Copied contents of: $1"
}

# Finder shortcuts
alias o='open .'  # Open current directory in Finder

# Show/hide hidden files in Finder
alias showfiles='defaults write com.apple.finder AppleShowAllFiles YES; killall Finder'
alias hidefiles='defaults write com.apple.finder AppleShowAllFiles NO; killall Finder'

# Flush DNS cache
alias flushdns='sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder'

# ============================================================================
# Load Helper Functions
# ============================================================================
# Source helpers AFTER stub definitions so real implementations override stubs
[ -f "$HELPERS_DIR/git.sh" ] && . "$HELPERS_DIR/git.sh"
[ -f "$HELPERS_DIR/llm.sh" ] && . "$HELPERS_DIR/llm.sh"
