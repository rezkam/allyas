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
  _allyas_link_target="$(readlink "$_allyas_source")"
  # If readlink returns a relative path, make it absolute
  case "$_allyas_link_target" in
    /*) _allyas_source="$_allyas_link_target" ;;
    *)  _allyas_source="$(dirname "$_allyas_source")/$_allyas_link_target" ;;
  esac
  unset _allyas_link_target
fi

HELPERS_DIR="$(cd "$(dirname "$_allyas_source")" && pwd)/helpers"
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

  local files_to_scan=("$source_file")
  if [ -d "$HELPERS_DIR" ]; then
    for helper_file in "$HELPERS_DIR"/*.sh; do
      if [ -f "$helper_file" ]; then
        files_to_scan+=("$helper_file")
      fi
    done
  fi

  awk -f /dev/stdin "${files_to_scan[@]}" <<'AWK'
    function trim(s) { sub(/^[[:space:]]+/, "", s); sub(/[[:space:]]+$/, "", s); return s }
    function strip_quotes(s) { s = trim(s); if (length(s) >= 2 && ((substr(s, 1, 1) == "'" && substr(s, length(s)) == "'") || (substr(s, 1, 1) == "\"" && substr(s, length(s)) == "\""))) { s = substr(s, 2, length(s) - 2) }; return s }
    function add_entry(type, text, desc, extra) {
        if (text ~ /^_/) return;
        entry_count++;
        entry_type[entry_count] = type;
        entry_text[entry_count] = text;
        entry_desc[entry_count] = desc;
        entry_extra[entry_count] = extra;
        if (type == "alias" || type == "function") {
            if (length(text) > max_name_width) max_name_width = length(text);
        }
    }
    BEGIN { max_name_width = 0; entry_count = 0; pending_comment = ""; next_is_section = 0; function_depth = 0; in_heredoc = 0; skip_next = 0; }
    {
        if (in_heredoc) {
            if ($0 == "AWK") {
                in_heredoc = 0;
            }
            next;
        }
        if ($0 ~ /<<'AWK'/) {
            in_heredoc = 1;
            next;
        }

        if (function_depth > 0) {
            function_depth += gsub(/{/, "{", $0) - gsub(/}/, "}", $0);
            if (function_depth <= 0) function_depth = 0;
            next;
        }

        if (next_is_section) {
            next_is_section = 0;
            if ($0 ~ /^#[[:space:]]*/ && !($0 ~ /^#[[:space:]]*=+/)) {
                section = $0;
                sub(/^#[[:space:]]*/, "", section);
                section = trim(section);
                if (section != "") { add_entry("section", section) }
            }
        }
        if ($0 ~ /^#[[:space:]]*=+/) {
            next_is_section = 1;
            pending_comment = "";
            next;
        }

        if (trim($0) == "") { pending_comment = ""; next }

        if ($0 ~ /^[[:space:]]*#/) {
            comment = $0;
            sub(/^#[[:space:]]*/, "", comment);
            comment = trim(comment);
            if (comment ~ /allyas:ignore/) {
                skip_next = 1;
                pending_comment = "";
                next;
            }
            if (comment ~ /^--/) {
                sub(/^--[[:space:]]*/, "", comment);
                add_entry("heading", trim(comment));
                pending_comment = "";
                next;
            }
            pending_comment = (pending_comment == "") ? comment : pending_comment "\n" comment;
            next;
        }

        if (skip_next) {
            skip_next = 0;
            pending_comment = "";
            next;
        }

        is_alias = ($0 ~ /^[[:space:]]*alias[[:space:]]+/);
        is_function = ($0 ~ /^[[:space:]]*[a-zA-Z0-9_-]+[[:space:]]*\(\)[[:space:]]*{/);

        if (is_alias) {
            name = $0; sub(/.*alias[[:space:]]+/, "", name); sub(/=.*/, "", name); name = trim(name);
            command = $0; sub(/.*=/, "", command);
            inline_comment = "";
            if (match(command, /[[:space:]]#[[:space:]]+(.+)/, m)) {
                inline_comment = trim(m[1]);
                sub(/[[:space:]]#[[:space:]]+.*/, "", command);
            }
            command = strip_quotes(trim(command));
            desc = pending_comment != "" ? pending_comment : (inline_comment != "" ? inline_comment : command);
            add_entry("alias", name, desc, command);
        } else if (is_function) {
            name = $0; sub(/[[:space:]]*\(\).*/, "", name); name = trim(name);
            desc = pending_comment != "" ? pending_comment : "Shell function";
            add_entry("function", name, desc);

            local_depth = gsub(/{/, "{", $0) - gsub(/}/, "}", $0);
            if (local_depth > 0) {
                function_depth = local_depth;
            }
        }
        pending_comment = "";
    }
    END {
        if (max_name_width < 1) max_name_width = 1;
        item_format = sprintf("  %%-%ds  ", max_name_width);
        for (i = 1; i <= entry_count; i++) {
            type = entry_type[i]; text = entry_text[i]; desc = entry_desc[i];
            if (type == "section") {
                if (i > 1) print "";
                print text;
            } else if (type == "heading") {
                print "  " text;
            } else if (type == "alias" || type == "function") {
                n = split(desc, lines, "\n");
                printf item_format, text; print lines[1];
                for (j = 2; j <= n; j++) { printf item_format, ""; print lines[j]; }
            }
        }
    }
AWK
}

# ============================================================================
# General Aliases
# ============================================================================

# List files in long format, including hidden files and human-readable sizes.
alias ll='ls -lah'
# List all files, including hidden ones, in a single column.
alias la='ls -A'
# List files in columns, marking directories with a trailing slash.
alias l='ls -CF'

# Navigate up one directory.
alias ..='cd ..'
# Navigate up two directories.
alias ...='cd ../..'
# Navigate up three directories.
alias ....='cd ../../..'

# Grep with color highlighting for matches.
alias grep='grep --color=auto'

# List files sorted by modification time, newest last.
alias lt='ls -ltrh'
# List files sorted by size, smallest first.
alias lsize='ls -lSrh'
# Count the total number of files in the current directory and subdirectories.
alias count='find . -type f | wc -l'

# Display the current date and time in 'YYYY-MM-DD HH:MM:SS' format.
alias now='date +"%Y-%m-%d %H:%M:%S"'
# Display the current week number of the year.
alias week='date +%V'

# Create a new temporary directory and navigate into it.
alias cdtemp='cd $(mktemp -d)'

# ============================================================================
# Git Aliases
# ============================================================================

#-- Status & Info
# Show the working tree status, including changes and untracked files.
alias gis='git status'
# Show a brief status of the working tree (branch, staged, unstaged).
alias gisb='git status -sb'
# List all local branches.
alias gib='git branch'
# List all local and remote-tracking branches.
alias giba='git branch -a'
# Delete a local branch that has been fully merged.
alias gibd='git branch -d'
# Force delete a local branch, regardless of its merge status.
alias gibD='git branch -D'

#-- Log & History
# Show the commit history for the current branch.
alias gil='git log'
# Show a compact, graphical log of all branches, with decorations.
alias gilog='git log --oneline --graph --decorate --all'
# Show commit history with the patch (diff) for each commit.
alias gilp='git log -p'
# Show commit history with statistics on file changes.
alias gils='git log --stat'
# Show a compact, graphical log of all branches.
alias gilg='git log --graph --oneline --all'
# Show the most recent commit with statistics on file changes.
alias gilast='git log -1 HEAD --stat'

#-- Add & Commit
# Stage all changes in the current directory for the next commit.
alias gia='git add .'
# Stage all changes in the entire repository for the next commit.
alias giaa='git add --all'
# Interactively stage parts of files for the next commit.
alias giap='git add -p'
# Commit staged changes with an inline message.
alias gim='git commit -m'
# Stage all tracked files and commit them in one step.
alias gima='git commit -am'
# Modify the last commit, allowing changes to the commit message and files.
alias gimend='git commit --amend'
# Modify the last commit without changing the commit message.
alias gimendn='git commit --amend --no-edit'

#-- Diff
# Show changes between the working directory and the index.
alias gif='git diff'
# Show changes between the index (staged files) and the last commit.
alias giff='git diff --cached'
# Show a word-level diff instead of a line-level diff.
alias gifw='git diff --word-diff'
# Show only the names of files that have changed.
alias gifn='git diff --name-only'

#-- Push & Pull
# Pushes the current branch to its configured upstream remote.
# Handles detached HEAD states gracefully.
gush() {
  push_current_branch
}

# Force-pushes the current branch using --force-with-lease.
# This is a safer alternative to a standard force push.
gushf() {
  push_current_branch --force-with-lease
}

# Fetch changes from a remote and merge them into the current branch.
alias gull='git pull'

# Fetches changes and rebases the current branch on top of the default remote branch (main/master).
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

# Fetch changes and rebase the current branch on top of the upstream branch.
alias gullr='git pull --rebase'

# Fetch updates from all configured remote repositories.
alias gifa='git fetch --all'
# Fetch from all remotes and remove any remote-tracking branches that no longer exist.
alias gifap='git fetch --all --prune'

#-- Checkout & Branch
# Switch branches or restore working tree files.
alias gco='git checkout'
# Create a new branch and switch to it.
alias gcb='git checkout -b'
# Switch to the default branch (main or master).
alias gcm='git checkout "$(default_branch)"'
# Switch to the previously checked out branch.
alias gc-='git checkout -'

#-- Reset & Undo
# Performs a hard reset on a given commit with confirmation.
# This will discard all uncommitted changes in the working directory.
girha() {
  echo "⚠️  WARNING: This will discard ALL uncommitted changes!"
  if confirm_action "Are you sure? [y/N] "; then
    git reset --hard "$@"
  fi
}

# Performs a hard reset to HEAD with confirmation.
# This will discard all uncommitted changes in the working directory.
girhah() {
  echo "⚠️  WARNING: This will reset to HEAD and discard all changes!"
  if confirm_action "Are you sure? [y/N] "; then
    git reset --hard HEAD
  fi
}

# Unstage all changes from the staging area.
alias girh='git reset HEAD'
# Undo the last commit but keep the changes in the working directory.
alias girh1='git reset HEAD~1'

# Performs a hard reset to the upstream branch with confirmation.
# This will discard all local changes and commits.
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

#-- Stash
# Stash local changes in a temporary area.
alias gist='git stash'
# Apply the most recent stash and remove it from the stash list.
alias gistp='git stash pop'
# List all stashed changes.
alias gistl='git stash list'
# Discard the most recent stash.
alias gistd='git stash drop'
# Show the changes recorded in a stash as a patch.
alias gists='git stash show -p'

#-- Clone & Remote
# Clone a repository into a new directory.
alias glone='git clone'
# Perform a shallow clone, which is faster for large repositories.
alias gloned='git clone --depth=1'
# List all remote repositories with their URLs.
alias gir='git remote -v'
# Add a new remote repository.
alias gira='git remote add'
# Remove a remote repository.
alias girr='git remote remove'

#-- Merge & Rebase
# Merge a branch, always creating a new merge commit.
alias gimnf='git merge --no-ff'
# Reapply commits on top of another base tip.
alias gire='git rebase'
# Start an interactive rebase to edit, squash, or reorder commits.
alias girei='git rebase -i'
# Continue a rebase that was paused due to conflicts.
alias girec='git rebase --continue'
# Abort a rebase and return to the original state.
alias girea='git rebase --abort'

#-- Tags
# List, create, or delete tags.
alias gtag='git tag'
# Create an annotated tag.
alias gta='git tag -a'
# Delete a tag.
alias gtd='git tag -d'
# List all tags.
alias gtl='git tag -l'

#-- Worktree
# Manage multiple working trees attached to the same repository.
alias gwt='git worktree'
# Add a new worktree.
alias gwta='git worktree add'
# List all worktrees.
alias gwtl='git worktree list'
# Remove a worktree.
alias gwtr='git worktree remove'

#-- Cleanup & Maintenance
unalias gclean 2>/dev/null || true
# Removes untracked files and directories with confirmation.
gclean() {
  echo "⚠️  WARNING: This will permanently delete all untracked files and directories!"
  git clean -fd --dry-run
  if confirm_action "Proceed with deletion? [y/N] "; then
    git clean -fd
  fi
}

# Prunes all stale remote-tracking branches from the local repository.
gprune() {
  local remote
  remote=$(get_remote)
  git remote prune "$remote"
}

# Runs aggressive garbage collection to optimize the repository.
# This can take a long time on large repositories.
ggc() {
  echo "⚠️  WARNING: Aggressive garbage collection can take a long time!"
  if confirm_action "Continue? [y/N] "; then
    git gc --aggressive
  fi
}

#-- Shortcuts
# Stage all changes and commit with a 'WIP' (Work In Progress) message.
alias gasave='git add -A && git commit -m "WIP: work in progress"'
# Undo the last commit but keep the changes staged.
alias gaundo='git reset --soft HEAD~1'
# Stage all changes and commit with a 'WIP' message, skipping pre-commit hooks.
alias gawip='git add -A && git commit -m "WIP" --no-verify'
# Amend the last commit without opening an editor.
alias gamend='git commit --amend --no-edit'

# ============================================================================
# Development Aliases
# ============================================================================

# List only directories in the current path.
alias lsd='ls -d */'

# Find files by name in the current directory and subdirectories.
# Usage: findf '*.txt'
findf() {
  if [ -z "$1" ]; then
    echo "Usage: findf <filename_pattern>"
    return 1
  fi
  find . -type f -name "$1"
}

# Find directories by name in the current directory and subdirectories.
# Usage: findd 'dirname'
findd() {
  if [ -z "$1" ]; then
    echo "Usage: findd <dirname_pattern>"
    return 1
  fi
  find . -type d -name "$1"
}

# Search for running processes by name.
# Usage: psg <process_name>
psg() {
  if [ -z "$1" ]; then
    echo "Usage: psg <process_name>"
    return 1
  fi
  ps aux | grep -i -- "$1" | grep -v grep
}

# Open the Zsh configuration file in the nano editor.
alias zshrc='nano ~/.zshrc'
# Open the Bash configuration file in the nano editor.
alias bashrc='nano ~/.bashrc'

# Show disk usage of the current directory, one level deep, in human-readable format.
alias duh='du -h -d 1'
# Show disk usage of all mounted file systems in human-readable format.
alias dfs='df -h'

# Get your public IP address.
alias myip='curl -s ifconfig.me'

unalias ports 2>/dev/null || true
# Show all listening TCP ports (requires sudo).
ports() {
  echo "Requesting sudo access to view all listening TCP ports..."
  sudo lsof -iTCP -sTCP:LISTEN -n -P
}

# Analyze listening ports with an LLM to identify suspicious processes.
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

# Switch between different LLM providers (codex, claude, gemini).
# Usage: llm-use <provider>
llm-use() { :; }

# List all available LLM providers and show which one is active.
llm-list() { :; }

# ============================================================================
# macOS Specific Aliases
# ============================================================================

# Copy standard input to the macOS clipboard.
alias copy='pbcopy'
# Paste the contents of the macOS clipboard to standard output.
alias paste='pbpaste'
# Copy the current working directory path to the macOS clipboard.
alias cpwd='pwd | pbcopy'

# Copy the absolute path of a file to the clipboard.
# Usage: cpf <file>
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

# Copy the contents of a file to the clipboard.
# Usage: ccopy <file>
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

# Open the current directory in the macOS Finder.
alias o='open .'

# Show hidden files in the macOS Finder.
alias showfiles='defaults write com.apple.finder AppleShowAllFiles YES; killall Finder'
# Hide hidden files in the macOS Finder.
alias hidefiles='defaults write com.apple.finder AppleShowAllFiles NO; killall Finder'

# Flush the DNS cache on macOS.
alias flushdns='sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder'

# Source helpers AFTER stub definitions so real implementations override stubs
[ -f "$HELPERS_DIR/git.sh" ] && . "$HELPERS_DIR/git.sh"
[ -f "$HELPERS_DIR/llm.sh" ] && . "$HELPERS_DIR/llm.sh"
