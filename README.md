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

## Features

- **Automated releases**: Tag once, everything else is automatic
- **Clean separation**: Source code separate from distribution
- **No self-modifying repos**: Tap repo only updated by external triggers
- **Version controlled**: All changes tracked in git
- **Cross-shell compatible**: Works with both bash and zsh
- **Cross-architecture**: Works on both Apple Silicon and Intel Macs
