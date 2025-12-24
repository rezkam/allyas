# ============================================================================
# LLM Utilities
# ============================================================================

# Provides reusable functions for LLM-based analysis commands
#
# Architecture:
# - This file contains ALL LLM-related logic (both internal helpers and user-facing functions)
# - allyas.sh defines stub versions of user-facing functions (llm-use, llm-list) for introspection
# - This file is sourced at the END of allyas.sh, overriding the stubs with real implementations
# - Internal helpers (prefixed with _) are marked with "# allyas:ignore" to hide from introspection

# Default LLM (can be overridden by ALLYAS_LLM env var)
: "${ALLYAS_LLM_DEFAULT:=codex}"

# Model overrides (can be set via environment variables)
# Examples:
#   export ALLYAS_CODEX_MODEL="gpt-4o"
#   export ALLYAS_CLAUDE_MODEL="sonnet"
#   export ALLYAS_GEMINI_MODEL="gemini-2.0-flash-exp"
: "${ALLYAS_CODEX_MODEL:=gpt-5-codex}"
: "${ALLYAS_CLAUDE_MODEL:=haiku}"
: "${ALLYAS_GEMINI_MODEL:=gemini-2.5-flash}"

# allyas:ignore Map LLM name to actual command with flags
# Arguments:
#   $1 - llm_name (codex, claude, gemini)
#   $2 - (optional) output_file for raw response extraction (only used by codex)
_llm_get_command() {
  local llm_name="$1"
  local output_file="$2"

  case "$llm_name" in
    codex)
      # Codex supports --output-last-message to extract clean response
      # Model can be overridden with ALLYAS_CODEX_MODEL env var
      local model="${ALLYAS_CODEX_MODEL}"
      if [ -n "$output_file" ]; then
        echo "codex exec --skip-git-repo-check -m \"$model\" --output-last-message \"$output_file\" --color never"
      else
        echo "codex exec --skip-git-repo-check -m \"$model\""
      fi
      ;;
    claude)
      # Claude's -p mode outputs just the response (no session markers)
      # Model can be overridden with ALLYAS_CLAUDE_MODEL env var (haiku, sonnet, opus)
      local model="${ALLYAS_CLAUDE_MODEL}"
      echo "claude --model \"$model\" -p"
      ;;
    gemini)
      # Gemini with JSON output for clean response extraction
      # Model can be overridden with ALLYAS_GEMINI_MODEL env var
      # Note: -o must come before -p, and -p must be last before the prompt
      local model="${ALLYAS_GEMINI_MODEL}"
      echo "gemini -m \"$model\" -o json -p"
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

# allyas:ignore Show available LLMs with their installation status
# Arguments: 
#   $1 - (optional) "error" to output to stderr and show error context, or empty for normal output
_llm_show_status() {
  local mode="${1:-normal}"
  local current="${ALLYAS_LLM:-${ALLYAS_LLM_DEFAULT:-codex}}"
  local out_stream=1  # stdout by default
  
  # If in error mode, output to stderr
  if [ "$mode" = "error" ]; then
    out_stream=2
  fi
  
  {
    echo ""
    echo "Available LLMs:"
    echo ""

    # Check for codex
    if command -v codex >/dev/null 2>&1; then
      if [ "$current" = "codex" ]; then
        if [ "$mode" = "error" ]; then
          echo "  ✓ codex    (active, but not working) - model: ${ALLYAS_CODEX_MODEL}"
        else
          echo "  ✓ codex    (active) - model: ${ALLYAS_CODEX_MODEL}"
        fi
      else
        echo "  ✓ codex    (installed, use: llm-use codex) - model: ${ALLYAS_CODEX_MODEL}"
      fi
    else
      echo "  ✗ codex    (not installed)"
    fi

    # Check for claude
    if command -v claude >/dev/null 2>&1; then
      if [ "$current" = "claude" ]; then
        if [ "$mode" = "error" ]; then
          echo "  ✓ claude   (active, but not working) - model: ${ALLYAS_CLAUDE_MODEL}"
        else
          echo "  ✓ claude   (active) - model: ${ALLYAS_CLAUDE_MODEL}"
        fi
      else
        echo "  ✓ claude   (installed, use: llm-use claude) - model: ${ALLYAS_CLAUDE_MODEL}"
      fi
    else
      echo "  ✗ claude   (not installed)"
    fi

    # Check for gemini
    if command -v gemini >/dev/null 2>&1; then
      if [ "$current" = "gemini" ]; then
        if [ "$mode" = "error" ]; then
          echo "  ✓ gemini   (active, but not working) - model: ${ALLYAS_GEMINI_MODEL}"
        else
          echo "  ✓ gemini   (active) - model: ${ALLYAS_GEMINI_MODEL}"
        fi
      else
        echo "  ✓ gemini   (installed, use: llm-use gemini) - model: ${ALLYAS_GEMINI_MODEL}"
      fi
    else
      echo "  ✗ gemini   (not installed)"
    fi

    echo ""
    if [ "$mode" != "error" ]; then
      echo "To switch LLM: llm-use <name>"
      echo ""
      echo "To change models, set environment variables:"
      echo "  export ALLYAS_CODEX_MODEL=\"gpt-4o\""
      echo "  export ALLYAS_CLAUDE_MODEL=\"sonnet\""
      echo "  export ALLYAS_GEMINI_MODEL=\"gemini-2.0-flash-exp\""
    fi
  } >&"$out_stream"
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

  # Check if the selected LLM is installed
  if ! command -v "$llm_name" >/dev/null 2>&1; then
    echo "Error: LLM tool '$llm_name' is not installed or not in PATH" >&2
    echo "" >&2
    echo "Please install an LLM CLI tool or switch to an installed one using 'llm-use'." >&2
    _llm_show_status "error"
    return 1
  fi

  # Create temp files
  local prompt_file="$(mktemp /tmp/llm_analyze.XXXXXX)" || return 1
  local output_file="$(mktemp /tmp/llm_analyze.out.XXXXXX)" || return 1
  local stderr_file="$(mktemp /tmp/llm_analyze.stderr.XXXXXX)" || return 1
  local response_file="$(mktemp /tmp/llm_analyze.response.XXXXXX)" || return 1

  # Build prompt
  cat >"$prompt_file" <<EOF
INSTRUCTIONS:
$instructions

DATA:
$data
EOF

  # Map name to command with response extraction support
  local llm_cmd
  llm_cmd="$(_llm_get_command "$llm_name" "$response_file")" || return 1

  # Run LLM
  # Separate stdout and stderr to properly handle different LLM output formats
  eval "$llm_cmd" '"$(cat "$prompt_file")"' >"$output_file" 2>"$stderr_file"
  local exit_code=$?

  # Check if command failed
  if [ $exit_code -ne 0 ]; then
    echo "" >&2
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
    echo "❌ LLM Analysis Failed" >&2
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
    echo "" >&2
    echo "Tool: $llm_name" >&2
    echo "Exit code: $exit_code" >&2
    echo "" >&2
    
    # Show stderr content (usually contains the actual error message)
    if [ -s "$stderr_file" ]; then
      echo "Error details:" >&2
      # Filter out excessive debug logs but keep error messages
      grep -v "^\[STARTUP\]" "$stderr_file" | head -50 >&2
    fi
    
    # Show stdout if it has error info and stderr was empty
    if [ ! -s "$stderr_file" ] && [ -s "$output_file" ]; then
      echo "Error details:" >&2
      head -50 "$output_file" >&2
    fi
    
    echo "" >&2
    echo "Suggestions:" >&2
    echo "  • Check if '$llm_name' is properly configured" >&2
    echo "  • Verify API credentials and rate limits" >&2
    echo "  • Try switching to another LLM: llm-list" >&2
    echo "" >&2
    
    rm -f "$prompt_file" "$output_file" "$stderr_file" "$response_file"
    return $exit_code
  fi

  # Extract response based on LLM type
  local final_response=""
  local temp_response_file="$(mktemp /tmp/llm_analyze.final.XXXXXX)" || return 1
  
  if [ -s "$response_file" ]; then
    # Codex: uses --output-last-message, response is in response_file
    cat "$response_file" >"$temp_response_file"
  elif [ "$llm_name" = "gemini" ]; then
    # Gemini: uses JSON output format, extract the "response" field
    if command -v jq >/dev/null 2>&1; then
      jq -r '.response // empty' "$output_file" 2>/dev/null | \
        grep -v "^I'm ready for your first command\.$" | \
        grep -v "^OK\. I'm ready for your first command\.$" | \
        grep -v "^Setup complete\.$" | \
        grep -v "^Awaiting your first command\.$" >"$temp_response_file"
      # If jq extraction failed or empty, fall back to text parsing
      if [ ! -s "$temp_response_file" ]; then
        cat "$output_file" >"$temp_response_file"
      fi
    else
      # jq not available, just output as-is
      cat "$output_file" >"$temp_response_file"
    fi
  elif [ "$llm_name" = "claude" ]; then
    # Claude: -p mode outputs response to stdout
    # But may include debug logs, so we need to filter them out
    awk '
      # Skip known debug/startup patterns
      /^\[STARTUP\]/ { next }
      /^Loaded cached credentials\.?$/ { next }
      /^Error when talking to/ { next }
      /^\[API Error:/ { next }
      /^An unexpected critical error/ { next }
      /^Full report available at:/ { next }
      
      # Print everything else
      { print }
    ' "$output_file" >"$temp_response_file"
  else
    # Fallback: try to detect session markers
    if grep -q "^  user$\|^  assistant$" "$output_file" 2>/dev/null; then
      # Extract everything after the last "assistant" marker
      awk '
        /^  assistant[[:space:]]*$/ { capturing=1; buffer=""; next }
        capturing { buffer = buffer $0 "\n" }
        END { 
          # Remove trailing newline
          sub(/\n$/, "", buffer)
          print buffer 
        }
      ' "$output_file" >"$temp_response_file"
    else
      # No markers, output as-is
      cat "$output_file" >"$temp_response_file"
    fi
  fi
  
  # Check for common error patterns in the response
  final_response="$(cat "$temp_response_file")"
  
  if [ -z "$final_response" ]; then
    echo "" >&2
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
    echo "❌ LLM returned empty response" >&2
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
    echo "" >&2
    echo "Tool: $llm_name" >&2
    echo "" >&2
    if [ -s "$stderr_file" ]; then
      echo "Stderr output:" >&2
      grep -v "^\[STARTUP\]" "$stderr_file" | head -30 >&2
      echo "" >&2
    fi
    echo "Suggestions:" >&2
    echo "  • The LLM may have hit rate limits" >&2
    echo "  • Try again in a few moments" >&2
    echo "  • Try switching to another LLM: llm-list" >&2
    echo "" >&2
    rm -f "$prompt_file" "$output_file" "$stderr_file" "$response_file" "$temp_response_file"
    return 1
  fi
  
  # Check for rate limit messages in the response
  if echo "$final_response" | grep -qi "rate limit\|limit reached\|quota exceeded\|too many requests"; then
    echo "" >&2
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
    echo "⚠️  LLM Rate Limit Reached" >&2
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
    echo "" >&2
    echo "Tool: $llm_name" >&2
    echo "" >&2
    echo "$final_response" >&2
    echo "" >&2
    echo "Suggestions:" >&2
    echo "  • Wait for the rate limit to reset" >&2
    echo "  • Try switching to another LLM: llm-list" >&2
    echo "" >&2
    rm -f "$prompt_file" "$output_file" "$stderr_file" "$response_file" "$temp_response_file"
    return 1
  fi

  # Output the clean response
  echo "$final_response"

  # Cleanup
  rm -f "$prompt_file" "$output_file" "$stderr_file" "$response_file" "$temp_response_file"

  return 0
}

# Switch between different LLM providers (codex, claude, gemini).
# Usage: llm-use <provider>
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

# List all available LLM providers and show which one is active.
llm-list() {
  _llm_show_status
}
