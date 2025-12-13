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

### Making Changes

1. **Edit aliases** in `allyas.sh`
2. **Commit and push** to main:
   ```bash
   git add allyas.sh
   git commit -m "Add new alias for xyz"
   git push
   ```

3. **Create and push a version tag**:
   ```bash
   git tag v0.0.2
   git push origin v0.0.2
   ```

4. **GitHub Actions automatically**:
   - Downloads the release tarball
   - Calculates SHA256 checksum
   - Generates formula from template
   - Pushes updated formula to [homebrew-allyas](https://github.com/rezkam/homebrew-allyas)

5. **Users update with**:
   ```bash
   brew update && brew upgrade allyas
   ```

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

## Included Aliases

See `allyas.sh` for the complete list. Highlights include:

- `ll` - List files with details
- `gs` - Git status
- `ga` - Git add
- `gc` - Git commit
- `gp` - Git push
- `..` - Go up one directory
- And many more!

## How It Works

```
┌─────────────────────────────────────────────────────────────┐
│  1. You edit allyas.sh and create a tag                     │
│     git tag v0.0.2 && git push origin v0.0.2                │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│  2. GitHub Actions (in THIS repo)                           │
│     ├─ Downloads release tarball                            │
│     ├─ Calculates SHA256                                    │
│     ├─ Generates formula from template                      │
│     └─ Pushes to rezkam/homebrew-allyas                     │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│  3. Tap repo updated (rezkam/homebrew-allyas)               │
│     Formula/allyas.rb now has correct version & SHA256      │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│  4. Users upgrade                                            │
│     brew update && brew upgrade allyas                       │
└─────────────────────────────────────────────────────────────┘
```

## License

MIT

## Tips

- **Use semantic versioning**: v0.0.1, v0.0.2, v0.1.0, etc.
- **Test locally first**: Source the aliases file before committing
- **Document changes**: Use clear commit messages
- **Create GitHub releases**: Optional but recommended for changelog

## Troubleshooting

### GitHub Actions fails with "Resource not accessible by integration"

The `TAP_GITHUB_TOKEN` secret is missing or invalid:
1. Check the secret exists in repository settings
2. Verify the token has `repo` scope
3. Make sure the token hasn't expired

### Formula not updated in tap repo

1. Check GitHub Actions ran successfully: https://github.com/rezkam/allyas/actions
2. Verify the tag was pushed: `git ls-remote --tags origin`
3. Check the tap repo for recent commits

### SHA256 mismatch error

This shouldn't happen with automation, but if it does:
1. Delete the tag: `git push --delete origin v0.0.X`
2. Delete the release on GitHub
3. Recreate the tag: `git tag v0.0.X && git push origin v0.0.X`
