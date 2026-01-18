# Unit tests for Git Functions in allyas.sh

Describe 'Git Functions'
  Include ./allyas.sh
  Include ./helpers/git.sh

  # Setup a mock git repository for testing
  setup_repo() {
    ORIGINAL_DIR=$(pwd)
    TEST_REPO=$(mktemp -d)
    cd "$TEST_REPO"
    git init --quiet
    git config user.email "test@example.com"
    git config user.name "Test User"
    echo "initial" > README.md
    git add README.md
    git commit --quiet -m "Initial commit"
  }

  cleanup_repo() {
    cd "$ORIGINAL_DIR"
    rm -rf "$TEST_REPO"
  }

  Describe 'Status & Info'
    Before 'setup_repo'
    After 'cleanup_repo'

    Describe 'gis()'
      It 'shows git status'
        When call gis
        The status should be success
        The output should include 'On branch'
      End
    End

    Describe 'gisb()'
      It 'shows short status'
        When call gisb
        The status should be success
        The output should match pattern '## *'
      End
    End

    Describe 'gib()'
      It 'lists local branches'
        When call gib
        The status should be success
        The output should be present
      End
    End
  End

  Describe 'Log & History'
    Before 'setup_repo'
    After 'cleanup_repo'

    Describe 'gil()'
      It 'shows commit log'
        When call gil
        The status should be success
        The output should include 'Initial commit'
      End
    End

    Describe 'gilast()'
      It 'shows last commit'
        When call gilast
        The status should be success
        The output should include 'Initial commit'
      End
    End

    Describe 'gilog()'
      It 'shows graphical log'
        When call gilog
        The status should be success
        The output should include 'Initial commit'
      End
    End
  End

  Describe 'Add & Commit'
    Before 'setup_repo'
    After 'cleanup_repo'

    Describe 'gia()'
      It 'stages all changes in current directory'
        echo "new file" > newfile.txt
        When call gia
        The status should be success
      End
    End

    Describe 'giaa()'
      It 'stages all changes in entire repository'
        echo "another file" > another.txt
        When call giaa
        The status should be success
      End
    End

    Describe 'gim()'
      It 'commits with message'
        echo "commit test" > commit_test.txt
        git add commit_test.txt
        When call gim "Test commit message"
        The status should be success
        The output should include 'Test commit message'
      End
    End
  End

  Describe 'Diff'
    Before 'setup_repo'
    After 'cleanup_repo'

    Describe 'gif()'
      It 'shows diff for unstaged changes'
        echo "modified" >> README.md
        When call gif
        The status should be success
        The output should include 'modified'
      End

      It 'shows no output when no changes'
        When call gif
        The status should be success
        The output should equal ''
      End
    End

    Describe 'giff()'
      It 'shows diff for staged changes'
        echo "staged change" >> README.md
        git add README.md
        When call giff
        The status should be success
        The output should include 'staged change'
      End
    End

    Describe 'gifn()'
      It 'shows changed file names'
        echo "name only test" >> README.md
        When call gifn
        The status should be success
        The output should include 'README.md'
      End
    End
  End

  Describe 'Checkout & Branch'
    Before 'setup_repo'
    After 'cleanup_repo'

    Describe 'gco()'
      It 'checks out files'
        echo "changed" >> README.md
        When call gco README.md
        The status should be success
        The stderr should be present  # Git outputs "Updated X path from the index"
      End
    End

    Describe 'gcb()'
      It 'creates and switches to a new branch'
        When call gcb feature-branch
        The status should be success
        The stderr should include 'Switched to a new branch'
      End
    End

    Describe 'gcm()'
      It 'switches to default branch'
        git checkout -b test-branch --quiet
        When call gcm
        The status should be success
        The stderr should include 'Switched to branch'
      End
    End
  End

  Describe 'Stash'
    Before 'setup_repo'
    After 'cleanup_repo'

    Describe 'gist()'
      It 'stashes changes'
        echo "to stash" >> README.md
        When call gist
        The status should be success
        The output should include 'Saved working directory'
      End
    End

    Describe 'gistp()'
      It 'pops stashed changes'
        echo "stash pop test" >> README.md
        git stash --quiet
        When call gistp
        The status should be success
        The output should include 'Dropped'
      End
    End

    Describe 'gistl()'
      It 'lists stashed changes'
        echo "stash list test" >> README.md
        git stash --quiet
        When call gistl
        The status should be success
        The output should include 'stash@'
      End
    End
  End
End
