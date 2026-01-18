# ShellSpec Spec Helper
# This file is sourced before each spec file

# Project root directory
PROJECT_ROOT="${SHELLSPEC_PROJECT_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"

# Helper to create a mock git repository for testing
create_mock_git_repo() {
  local repo_dir="$1"
  mkdir -p "$repo_dir"
  (
    cd "$repo_dir"
    git init --quiet
    git config user.email "test@example.com"
    git config user.name "Test User"
    echo "test" > README.md
    git add README.md
    git commit --quiet -m "Initial commit"
  )
}

# Helper to check if running in bash or zsh
current_shell() {
  if [ -n "${BASH_VERSION:-}" ]; then
    echo "bash"
  elif [ -n "${ZSH_VERSION:-}" ]; then
    echo "zsh"
  else
    echo "unknown"
  fi
}
