# allyas

Personal shell aliases for macOS - Source Repository

This is the **source code repository** for allyas. The Homebrew formula is maintained separately in [homebrew-allyas](https://github.com/rezkam/homebrew-allyas).

## What is this?

`allyas` is a collection of shell aliases that can be installed and managed via Homebrew. This repository contains:
- `allyas.sh` - The shell aliases file
- `.github/workflows/release.yml` - Automation that updates the Homebrew tap

## Installation (for users)

**Don't install from this repo directly!** Use the Homebrew tap instead:

```bash
brew tap rezkam/allyas
brew install allyas
```

For more details, see [homebrew-allyas](https://github.com/rezkam/homebrew-allyas).

## Usage

After sourcing `allyas.sh` (usually via the Homebrew shim), run the `allyas` command to print every alias/function along with the section headings they live under. This is the quickest way to discover the shortcuts that are available in your shell session.

### LLM-Powered Commands

allyas includes LLM-powered security analysis tools that require one of the following CLI tools:
- [codex](https://github.com/openai/openai-cli) - OpenAI Codex (default, fast ~6s)
- [claude](https://github.com/anthropics/claude-cli) - Anthropic Claude (fastest ~5s with Haiku)
- [gemini](https://github.com/google/gemini-cli) - Google Gemini (~29s, slower)

#### portswhy
Analyze all listening TCP ports on your system and identify suspicious processes:

```bash
portswhy
```

This command:
1. Scans all listening TCP ports
2. Identifies the processes using those ports
3. Checks code signatures for each executable
4. Uses LLM to analyze security implications and provide recommendations

#### LLM Configuration

Switch between LLM providers:

```bash
llm-use codex   # OpenAI Codex (default, fast)
llm-use claude  # Anthropic Claude (fastest with Haiku model)
llm-use gemini  # Google Gemini
llm-list        # Show available LLMs and current configuration
```

#### Model Customization

Override default models via environment variables:

```bash
# Temporary override for current session
export ALLYAS_CODEX_MODEL="gpt-4o"
export ALLYAS_CLAUDE_MODEL="sonnet"
export ALLYAS_GEMINI_MODEL="gemini-2.0-flash-exp"

# Then run your command
portswhy
```

To make changes permanent, add to your `~/.zshrc` or `~/.bashrc`:

```bash
# In ~/.zshrc
export ALLYAS_LLM="claude"              # Set default LLM
export ALLYAS_CLAUDE_MODEL="sonnet"     # Use Claude Sonnet instead of Haiku
```

**Default models:**
- Codex: `gpt-5-codex`
- Claude: `haiku` (optimized for speed)
- Gemini: `gemini-2.5-flash`

**Performance note:** Claude Haiku and OpenAI Codex are significantly faster (~5-6s) than Gemini (~29s) for typical analyses.

## Features

- **Automated releases**: Tag once, everything else is automatic
- **Clean separation**: Source code separate from distribution
- **No self-modifying repos**: Tap repo only updated by external triggers
- **Version controlled**: All changes tracked in git
- **Cross-shell compatible**: Works with both bash and zsh
- **Cross-architecture**: Works on both Apple Silicon and Intel Macs
