# ============================================================================
# Homebrew Formula Template for allyas
# ============================================================================
#
# PURPOSE:
#   This is a TEMPLATE file with Handlebars-style placeholders that gets
#   automatically processed by GitHub Actions to generate the actual Homebrew
#   formula in the rezkam/homebrew-allyas repository.
#
# HOW IT WORKS:
#   1. When you create a tag (e.g., v0.0.2) in THIS repository:
#      git tag v0.0.2 && git push origin v0.0.2
#
#   2. GitHub Actions workflow (.github/workflows/release.yml) automatically:
#      - Downloads the release tarball from GitHub
#      - Calculates the SHA256 checksum
#      - Reads this template file
#      - Replaces the {{placeholders}} with actual values:
#        * {{version}}    → "0.0.2"
#        * {{tarballUrl}} → "https://github.com/rezkam/allyas/archive/refs/tags/v0.0.2.tar.gz"
#        * {{sha256}}     → "abc123def456..." (calculated checksum)
#
#   3. Pushes the generated formula to: rezkam/homebrew-allyas/Formula/allyas.rb
#
# IMPORTANT:
#   - DO NOT manually edit the formula in the homebrew-allyas repository!
#   - ALL changes to the formula should be made HERE in this template
#   - The placeholders {{version}}, {{sha256}}, and {{tarballUrl}} will be
#     automatically replaced - do not modify them
#   - This ensures the tap repository never modifies itself, maintaining
#     clean separation between source code and distribution
#
# ============================================================================

class Allyas < Formula
  desc "Personal shell aliases for macOS"
  homepage "https://github.com/rezkam/allyas"
  url "{{tarballUrl}}"          # Auto-filled: Download URL for the release tarball
  sha256 "{{sha256}}"            # Auto-filled: SHA256 checksum of the tarball
  version "{{version}}"          # Auto-filled: Version from the git tag (e.g., v0.0.2 → 0.0.2)
  license "MIT"

  def install
    # Install the aliases file to Homebrew's etc directory
    etc.install "allyas.sh"
  end

  def caveats
    <<~EOS
      🎉 allyas has been installed!

      To use these aliases, add this line to your shell configuration:

      For bash (~/.bashrc or ~/.bash_profile):
        [ -f $(brew --prefix)/etc/allyas.sh ] && . $(brew --prefix)/etc/allyas.sh

      For zsh (~/.zshrc):
        [ -f $(brew --prefix)/etc/allyas.sh ] && . $(brew --prefix)/etc/allyas.sh

      Then reload your shell:
        source ~/.zshrc    # for zsh
        source ~/.bashrc   # for bash

      To verify installation:
        ls -la $(brew --prefix)/etc/allyas.sh

      To update your aliases:
        brew update && brew upgrade allyas
    EOS
  end

  test do
    # Verify that the aliases file was installed
    assert_predicate etc/"allyas.sh", :exist?
    assert_match "allyas", (etc/"allyas.sh").read
  end
end
