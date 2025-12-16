# Git Helper Functions
# Internal helpers used by git aliases and functions

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
