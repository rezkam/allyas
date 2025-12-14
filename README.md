# allyas

Personal shell aliases for macOS - Source Repository

This is the **source code repository** for allyas. The Homebrew formula is maintained separately in [homebrew-allyas](https://github.com/rezkam/homebrew-allyas).

## What is this?

`allyas` is a collection of shell aliases that can be installed and managed via Homebrew. This repository contains:
- `allyas.sh` - The shell aliases file
- `support/formula-template.rb` - Template for the Homebrew formula
- `.github/workflows/release.yml` - Automation that updates the Homebrew tap

## Installation (for users)

**Don't install from this repo directly!** Use the Homebrew tap instead:

```bash
brew tap rezkam/allyas
brew install allyas
```

For more details, see [homebrew-allyas](https://github.com/rezkam/homebrew-allyas).

## Development Workflow (for maintainers)

### Repository Structure

This project uses a **two-repository pattern**:

1. **rezkam/allyas** (this repo) - Source code
   - Contains `allyas.sh` and formula template
   - GitHub Actions here updates the tap repo

2. **rezkam/homebrew-allyas** - Homebrew tap
   - Contains only the generated formula
   - Updated automatically by releases from this repo

### First-Time Setup

#### 1. Create GitHub Personal Access Token

You need a token with `repo` scope to allow this repo to push to the tap repo:

1. Go to https://github.com/settings/tokens/new
2. Name: "Homebrew Tap Update Token"
3. Expiration: No expiration (or set as needed)
4. Scopes: Check `repo` (full control of private repositories)
5. Click "Generate token"
6. **Copy the token** (you won't see it again!)

#### 2. Add Token as Repository Secret

1. Go to https://github.com/rezkam/allyas/settings/secrets/actions
2. Click "New repository secret"
3. Name: `TAP_GITHUB_TOKEN`
4. Value: Paste the token you copied
5. Click "Add secret"

#### 3. Push Both Repositories

**Source repo (this one):**
```bash
cd /Users/rez/Code/git/allyas
git init
git add .
git commit -m "Initial commit: allyas source repository"
git remote add origin https://github.com/rezkam/allyas.git
git branch -M main
git push -u origin main
```

**Tap repo:**
```bash
cd /Users/rez/Code/git/homebrew-allyas
git init
git add .
git commit -m "Initial commit: Homebrew tap for allyas"
git remote add origin https://github.com/rezkam/homebrew-allyas.git
git branch -M main
git push -u origin main
```

#### 4. Create First Release

```bash
cd /Users/rez/Code/git/allyas
git tag v0.0.1
git push origin v0.0.1
```

This triggers the GitHub Actions workflow which will:
- Calculate the SHA256 of the v0.0.1 tarball
- Generate the formula
- Push it to the tap repo

#### 5. Verify

1. Check the Actions tab: https://github.com/rezkam/allyas/actions
2. Wait for the workflow to complete (~30 seconds)
3. Check the tap repo: https://github.com/rezkam/homebrew-allyas
4. The formula should now have a valid SHA256!

## Features

- **Automated releases**: Tag once, everything else is automatic
- **Clean separation**: Source code separate from distribution
- **No self-modifying repos**: Tap repo only updated by external triggers
- **Version controlled**: All changes tracked in git
- **Cross-shell compatible**: Works with both bash and zsh
- **Cross-architecture**: Works on both Apple Silicon and Intel Macs
