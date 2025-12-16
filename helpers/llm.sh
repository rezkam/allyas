# LLM Helper Functions
# Provides reusable functions for LLM-based analysis commands

# Default LLM (can be overridden by ALLYAS_LLM env var)
: "${ALLYAS_LLM_DEFAULT:=codex}"

# allyas:ignore Map LLM name to actual command with flags
_llm_get_command() {
  local llm_name="$1"

  case "$llm_name" in
    codex)
      echo "codex exec --skip-git-repo-check"
      ;;
    claude)
      echo "claude -p"
      ;;
    gemini)
      echo "gemini -p"
      ;;
    *)
      echo "Error: Unknown LLM '$llm_name'. Supported: codex, claude, gemini" >&2
      return 1
      ;;
  esac
}

# allyas:ignore Check if LLM is installed
_llm_check_installed() {
  local llm_name="$1"

  case "$llm_name" in
    codex|claude|gemini)
      if ! command -v "$llm_name" >/dev/null 2>&1; then
        echo "Error: '$llm_name' is not installed or not in PATH" >&2
        echo "Install it first before using llm-use" >&2
        return 1
      fi
      ;;
    *)
      return 1
      ;;
  esac
  return 0
}

# allyas:ignore Helper function to run LLM analysis with instructions and data
# Usage: result=$(llm_analyze "$instructions" "$data")
# Returns: LLM output as stdout
llm_analyze() {
  local instructions="$1"
  local data="$2"

  if [ -z "$instructions" ]; then
    echo "Error: llm_analyze requires instructions argument" >&2
    return 1
  fi

  # Get LLM name (priority: env override, default, fallback)
  local llm_name="${ALLYAS_LLM:-${ALLYAS_LLM_DEFAULT:-codex}}"

  # Map name to command
  local llm_cmd
  llm_cmd="$(_llm_get_command "$llm_name")" || return 1

  # Create temp files
  local prompt_file="$(mktemp /tmp/llm_analyze.XXXXXX)" || return 1
  local output_file="$(mktemp /tmp/llm_analyze.out.XXXXXX)" || return 1

  # Build prompt
  cat >"$prompt_file" <<EOF
INSTRUCTIONS:
$instructions

DATA:
$data
EOF

  # Run LLM
  $llm_cmd "$(cat "$prompt_file")" >"$output_file" 2>&1
  local exit_code=$?

  # Check if command failed
  if [ $exit_code -ne 0 ]; then
    echo "Error: LLM command failed with exit code $exit_code" >&2
    cat "$output_file" >&2
    rm -f "$prompt_file" "$output_file"
    return $exit_code
  fi

  # Output result
  cat "$output_file"

  # Cleanup
  rm -f "$prompt_file" "$output_file"

  return 0
}

# Switch the active LLM for the current shell session
# Usage: llm-use codex | llm-use claude | llm-use gemini
llm-use() {
  if [ -z "$1" ]; then
    echo "Current LLM: ${ALLYAS_LLM:-${ALLYAS_LLM_DEFAULT:-codex}}"
    echo ""
    echo "Usage: llm-use <llm-name>"
    echo "Supported LLMs: codex, claude, gemini"
    echo ""
    echo "Examples:"
    echo "  llm-use codex"
    echo "  llm-use claude"
    echo "  llm-use gemini"
    return 0
  fi

  local llm_name="$1"

  # Validate LLM name
  if ! _llm_get_command "$llm_name" >/dev/null 2>&1; then
    echo "Error: Unknown LLM '$llm_name'" >&2
    echo "Supported: codex, claude, gemini" >&2
    return 1
  fi

  # Check if installed
  if ! _llm_check_installed "$llm_name"; then
    return 1
  fi

  export ALLYAS_LLM="$llm_name"
  echo "✓ LLM switched to: $llm_name"
}

# List available LLM commands
llm-list() {
  echo "Available LLMs:"
  echo ""

  local current="${ALLYAS_LLM:-${ALLYAS_LLM_DEFAULT:-codex}}"

  # Check for codex
  if command -v codex >/dev/null 2>&1; then
    if [ "$current" = "codex" ]; then
      echo "  ✓ codex    (active)"
    else
      echo "  ✓ codex    (installed)"
    fi
  else
    echo "  ✗ codex    (not installed)"
  fi

  # Check for claude
  if command -v claude >/dev/null 2>&1; then
    if [ "$current" = "claude" ]; then
      echo "  ✓ claude   (active)"
    else
      echo "  ✓ claude   (installed)"
    fi
  else
    echo "  ✗ claude   (not installed)"
  fi

  # Check for gemini
  if command -v gemini >/dev/null 2>&1; then
    if [ "$current" = "gemini" ]; then
      echo "  ✓ gemini   (active)"
    else
      echo "  ✓ gemini   (installed)"
    fi
  else
    echo "  ✗ gemini   (not installed)"
  fi

  echo ""
  echo "To switch: llm-use <name>"
}
