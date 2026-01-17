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

  local cols
  if [ -t 1 ]; then
    cols=$(tput cols 2>/dev/null)
  fi
  : "${cols:=80}"


  awk -v term_width="$cols" -f /dev/stdin "${files_to_scan[@]}" <<'AWK'
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
            # Extract inline comment (BSD AWK compatible - no capture groups)
            if (match(command, /[[:space:]]#[[:space:]]+/)) {
                inline_comment = trim(substr(command, RSTART + RLENGTH));
                command = substr(command, 1, RSTART - 1);
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

        # Define spacing and padding
        left_padding = 2;
        middle_padding = 4;

        # Calculate column widths
        name_col_width = max_name_width;
        desc_col_start = left_padding + name_col_width + middle_padding;
        desc_col_width = term_width - desc_col_start;

        # Ensure description width is not negative
        if (desc_col_width < 10) desc_col_width = 10;

        for (i = 1; i <= entry_count; i++) {
            type = entry_type[i];
            text = entry_text[i];
            desc = entry_desc[i];

            if (type == "section") {
                if (i > 1) print "";
                print text;
            } else if (type == "heading") {
                printf "%*s%s\n", left_padding, "", text;
            } else if (type == "alias" || type == "function") {
                printf "%*s%-*s%*s", left_padding, "", name_col_width, text, middle_padding, "";

                n = split(desc, lines, "\n");
                for (j = 1; j <= n; j++) {
                    line = lines[j];
                    if (j > 1) {
                        printf "%*s", desc_col_start, "";
                    }

                    # Word wrapping logic
                    start = 1;
                    while (start <= length(line)) {
                        if (start > 1) {
                            printf "%*s", desc_col_start, "";
                        }

                        # Get a substring that fits
                        sub_str = substr(line, start, desc_col_width);

                        # If the substring fits perfectly or the original line is short
                        if (start + desc_col_width >= length(line)) {
                            print sub_str;
                            break;
                        }

                        # Find the last space to break on
                        last_space = -1;
                        for (k = length(sub_str); k > 0; k--) {
                            if (substr(sub_str, k, 1) == " ") {
                                last_space = k;
                                break;
                            }
                        }

                        # If no space was found, break the word
                        if (last_space == -1) {
                            print sub_str;
                            start += desc_col_width;
                        } else {
                            print substr(sub_str, 1, last_space - 1);
                            start += last_space;
                            # Skip any leading spaces in the remaining text
                            while (start <= length(line) && substr(line, start, 1) == " ") {
                                start++;
                            }
                        }
                    }
                }
            }
        }
    }
AWK
}

# ============================================================================
# General Functions
# ============================================================================

# List files in long format, including hidden files and human-readable sizes.
ll() { ls -lah "$@"; }
# List all files, including hidden ones, in a single column.
la() { ls -A "$@"; }
# List files in columns, marking directories with a trailing slash.
l() { ls -CF "$@"; }

# Navigate up one directory.
..() { cd ..; }
# Navigate up two directories.
...() { cd ../..; }
# Navigate up three directories.
....() { cd ../../..; }

# Grep with color highlighting for matches.
grep() { command grep --color=auto "$@"; }

# List files sorted by modification time, newest last.
lt() { ls -ltrh "$@"; }
# List files sorted by size, smallest first.
lsize() { ls -lSrh "$@"; }
# Count the total number of files in the current directory and subdirectories.
count() { find . -type f | wc -l; }

# Display the current date and time in 'YYYY-MM-DD HH:%M:%S' format.
now() { date +"%Y-%m-%d %H:%M:%S"; }
# Display the current week number of the year.
week() { date +%V; }

# Create a new temporary directory and navigate into it.
cdtemp() { cd "$(mktemp -d)"; }

# ============================================================================
# Git Functions
# ============================================================================

#-- Status & Info
# Show the working tree status, including changes and untracked files.
gis() { git status "$@"; }
# Show a brief status of the working tree (branch, staged, unstaged).
gisb() { git status -sb "$@"; }
# List all local branches.
gib() { git branch "$@"; }
# List all local and remote-tracking branches.
giba() { git branch -a "$@"; }
# Delete a local branch that has been fully merged.
gibd() { git branch -d "$@"; }
# Force delete a local branch, regardless of its merge status.
gibD() { git branch -D "$@"; }

#-- Log & History
# Show the commit history for the current branch.
gil() { git log "$@"; }
# Show a compact, graphical log of all branches, with decorations.
gilog() { git log --oneline --graph --decorate --all "$@"; }
# Show commit history with the patch (diff) for each commit.
gilp() { git log -p "$@"; }
# Show commit history with statistics on file changes.
gils() { git log --stat "$@"; }
# Show a compact, graphical log of all branches.
gilg() { git log --graph --oneline --all "$@"; }
# Show the most recent commit with statistics on file changes.
gilast() { git log -1 HEAD --stat "$@"; }

#-- Add & Commit
# Stage all changes in the current directory for the next commit.
gia() { git add . "$@"; }
# Stage all changes in the entire repository for the next commit.
giaa() { git add --all "$@"; }
# Interactively stage parts of files for the next commit.
giap() { git add -p "$@"; }
# Commit staged changes with an inline message.
gim() { git commit -m "$@"; }
# Stage all tracked files and commit them in one step.
gima() { git commit -am "$@"; }
# Modify the last commit, allowing changes to the commit message and files.
gimend() { git commit --amend "$@"; }
# Modify the last commit without changing the commit message.
gimendn() { git commit --amend --no-edit "$@"; }

#-- Diff
# Show changes between the working directory and the index.
gif() { git diff "$@"; }
# Show changes between the index (staged files) and the last commit.
giff() { git diff --cached "$@"; }
# Show a word-level diff instead of a line-level diff.
gifw() { git diff --word-diff "$@"; }
# Show only the names of files that have changed.
gifn() { git diff --name-only "$@"; }

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
gull() { git pull "$@"; }

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
gullr() { git pull --rebase "$@"; }

# Fetch updates from all configured remote repositories.
gifa() { git fetch --all "$@"; }
# Fetch from all remotes and remove any remote-tracking branches that no longer exist.
gifap() { git fetch --all --prune "$@"; }

#-- Checkout & Branch
# Switch branches or restore working tree files.
gco() { git checkout "$@"; }
# Create a new branch and switch to it.
gcb() { git checkout -b "$@"; }
# Switch to the default branch (main or master).
gcm() { git checkout "$(default_branch)"; }
# Switch to the previously checked out branch.
gc-() { git checkout -; }

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
girh() { git reset HEAD "$@"; }
# Undo the last commit but keep the changes in the working directory.
girh1() { git reset HEAD~1 "$@"; }

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
gist() { git stash "$@"; }
# Apply the most recent stash and remove it from the stash list.
gistp() { git stash pop "$@"; }
# List all stashed changes.
gistl() { git stash list "$@"; }
# Discard the most recent stash.
gistd() { git stash drop "$@"; }
# Show the changes recorded in a stash as a patch.
gists() { git stash show -p "$@"; }

#-- Clone & Remote
# Clone a repository into a new directory.
glone() { git clone "$@"; }
# Perform a shallow clone, which is faster for large repositories.
gloned() { git clone --depth=1 "$@"; }
# List all remote repositories with their URLs.
gir() { git remote -v "$@"; }
# Add a new remote repository.
gira() { git remote add "$@"; }
# Remove a remote repository.
girr() { git remote remove "$@"; }

#-- Merge & Rebase
# Merge a branch, always creating a new merge commit.
gimnf() { git merge --no-ff "$@"; }
# Reapply commits on top of another base tip.
gire() { git rebase "$@"; }
# Start an interactive rebase to edit, squash, or reorder commits.
girei() { git rebase -i "$@"; }
# Continue a rebase that was paused due to conflicts.
girec() { git rebase --continue "$@"; }
# Abort a rebase and return to the original state.
girea() { git rebase --abort "$@"; }

#-- Tags
# List, create, or delete tags.
gtag() { git tag "$@"; }
# Create an annotated tag.
gta() { git tag -a "$@"; }
# Delete a tag.
gtd() { git tag -d "$@"; }
# List all tags.
gtl() { git tag -l "$@"; }

#-- Worktree
# Manage multiple working trees attached to the same repository.
gwt() { git worktree "$@"; }
# Add a new worktree.
gwta() { git worktree add "$@"; }
# List all worktrees.
gwtl() { git worktree list "$@"; }
# Remove a worktree.
gwtr() { git worktree remove "$@"; }

#-- Cleanup & Maintenance
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
gasave() { git add -A && git commit -m "WIP: work in progress"; }
# Undo the last commit but keep the changes staged.
gaundo() { git reset --soft HEAD~1; }
# Stage all changes and commit with a 'WIP' message, skipping pre-commit hooks.
gawip() { git add -A && git commit -m "WIP" --no-verify; }
# Amend the last commit without opening an editor.
gamend() { git commit --amend --no-edit "$@"; }

# ============================================================================
# Development Functions
# ============================================================================

# List only directories in the current path.
lsd() { ls -d */ "$@"; }

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
  ps aux | command grep -i -- "$1" | command grep -v grep
}

# Open the Zsh configuration file in the nano editor.
zshrc() { nano ~/.zshrc; }
# Open the Bash configuration file in the nano editor.
bashrc() { nano ~/.bashrc; }

# Show disk usage of the current directory, one level deep, in human-readable format.
duh() { du -h -d 1 "$@"; }
# Show disk usage of all mounted file systems in human-readable format.
dfs() { df -h "$@"; }

# Get your public IP address.
myip() { curl -s ifconfig.me; }

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
  # BSD AWK compatible - no capture groups in match()
  awk '
    /^### / {
      app=""; exec=""

      # Extract app= value (handles paths with spaces ending in .app)
      if (match($0, /app=\/[^ ]+\.app/)) {
        app = substr($0, RSTART + 4, RLENGTH - 4)
      } else if (match($0, / app=[^ ]+/)) {
        app = substr($0, RSTART + 5, RLENGTH - 5)
      }

      # Extract exec= value (handles paths with spaces ending in .app)
      if (match($0, /exec=\/[^ ]+\.app/)) {
        exec = substr($0, RSTART + 5, RLENGTH - 5)
      } else if (match($0, / exec=[^ ]+/)) {
        exec = substr($0, RSTART + 6, RLENGTH - 6)
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
# macOS Specific Functions
# ============================================================================

# Copy standard input to the macOS clipboard.
copy() { pbcopy "$@"; }
# Paste the contents of the macOS clipboard to standard output.
paste() { pbpaste "$@"; }
# Copy the current working directory path to the macOS clipboard.
cpwd() { pwd | pbcopy; }

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
o() { open . "$@"; }

# Show hidden files in the macOS Finder.
showfiles() { defaults write com.apple.finder AppleShowAllFiles YES; killall Finder; }
# Hide hidden files in the macOS Finder.
hidefiles() { defaults write com.apple.finder AppleShowAllFiles NO; killall Finder; }

# Flush the DNS cache on macOS.
flushdns() { sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder; }

# Source helpers AFTER stub definitions so real implementations override stubs
[ -f "$HELPERS_DIR/git.sh" ] && . "$HELPERS_DIR/git.sh"
[ -f "$HELPERS_DIR/llm.sh" ] && . "$HELPERS_DIR/llm.sh"

# ============================================================================
# Version Check (runs entirely in background, zero shell startup impact)
# ============================================================================

ALLYAS_VERSION="0.0.15"

# Check for updates entirely in background (once per day)
# Notification is shown on NEXT shell start from cache, never blocks current shell
_allyas_check_update() {
  # Skip if disabled
  [ "${ALLYAS_DISABLE_UPDATE_CHECK:-}" = "1" ] && return

  local cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/allyas"
  local notify_file="$cache_dir/update_notify"

  # Show notification from previous check (if any) - just a file read, very fast
  if [ -f "$notify_file" ]; then
    cat "$notify_file"
    rm -f "$notify_file" 2>/dev/null
  fi

  # Everything else runs in background - zero blocking
  # Double fork pattern: ( ( ... ) & ) ensures no job notification in zsh/bash
  # Variables must be defined inside since subshell doesn't inherit locals
  ( (
    _cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/allyas"
    _cache_file="$_cache_dir/update_check"
    _notify_file="$_cache_dir/update_notify"
    _version="$ALLYAS_VERSION"
    _current_time=$(date +%s)

    # Create cache directory if needed
    mkdir -p "$_cache_dir" 2>/dev/null || exit 0

    # Check if we already checked today (86400 seconds = 24 hours)
    if [ -f "$_cache_file" ]; then
      _last_check=$(head -1 "$_cache_file" 2>/dev/null || echo "0")
      [ $((_current_time - _last_check)) -lt 86400 ] && exit 0
    fi

    # Fetch latest version from GitHub API (5 second timeout)
    _latest=$(curl -sf --max-time 5 "https://api.github.com/repos/rezkam/allyas/releases/latest" 2>/dev/null | \
      sed -n 's/.*"tag_name"[[:space:]]*:[[:space:]]*"v\{0,1\}\([^"]*\)".*/\1/p')

    # Save timestamp (even if fetch failed, to avoid hammering)
    echo "$_current_time" > "$_cache_file"

    # If we got a version and it's newer, prepare notification for next shell
    if [ -n "$_latest" ] && [ "$_latest" != "$_version" ]; then
      cat > "$_notify_file" <<EOF

📦 allyas update available: v$_version → v$_latest
   Run: brew upgrade allyas

EOF
    else
      # No update or same version, clear any old notification
      rm -f "$_notify_file" 2>/dev/null
    fi
  ) & )
}

# Only run in interactive shells
case $- in
  *i*) _allyas_check_update ;;
esac
