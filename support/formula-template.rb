class Allyas < Formula
  desc "Personal shell aliases for macOS"
  homepage "https://github.com/rezkam/allyas"
  url "{{tarballUrl}}"
  sha256 "{{sha256}}"
  version "{{version}}"
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
