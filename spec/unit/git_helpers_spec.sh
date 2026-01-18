# Unit tests for Git Helper Functions in helpers/git.sh

Describe 'Git Helper Functions'
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

  Describe 'get_current_branch()'
    Before 'setup_repo'
    After 'cleanup_repo'

    It 'returns the current branch name'
      When call get_current_branch
      The status should be success
      The output should be present
    End

    It 'returns branch name after creating new branch'
      git checkout -b feature-test --quiet
      When call get_current_branch
      The status should be success
      The output should equal 'feature-test'
    End

    It 'returns empty in detached HEAD state'
      git checkout --detach --quiet
      When call get_current_branch
      The status should be success
      The output should equal ''
    End
  End

  Describe 'get_remote()'
    Before 'setup_repo'
    After 'cleanup_repo'

    It 'returns origin as default remote'
      When call get_remote
      The status should be success
      The output should equal 'origin'
    End

    It 'returns configured remote for branch'
      git remote add upstream https://github.com/test/repo.git 2>/dev/null || true
      current=$(git branch --show-current)
      git config "branch.${current}.remote" upstream
      When call get_remote
      The status should be success
      The output should equal 'upstream'
    End
  End

  Describe 'get_push_remote()'
    Before 'setup_repo'
    After 'cleanup_repo'

    It 'returns origin as default push remote'
      When call get_push_remote
      The status should be success
      The output should equal 'origin'
    End

    It 'respects pushRemote configuration'
      git remote add fork https://github.com/fork/repo.git 2>/dev/null || true
      current_branch=$(git branch --show-current)
      git config "branch.${current_branch}.pushRemote" fork
      When call get_push_remote
      The status should be success
      The output should equal 'fork'
    End

    It 'respects remote.pushDefault configuration'
      git remote add default-push https://github.com/push/repo.git 2>/dev/null || true
      git config remote.pushDefault default-push
      When call get_push_remote
      The status should be success
      The output should equal 'default-push'
    End
  End

  Describe 'default_branch()'
    Before 'setup_repo'
    After 'cleanup_repo'

    It 'returns a valid branch name'
      When call default_branch
      The status should be success
      The output should be present
    End

    It 'finds main branch when it exists'
      # Create main branch if not default
      current=$(git branch --show-current)
      if [ "$current" != "main" ]; then
        git branch main 2>/dev/null || true
      fi
      When call default_branch
      The status should be success
      The output should equal 'main'
    End
  End

  Describe 'confirm_action()'
    It 'rejects empty input'
      Data ""
      When call confirm_action "Test? "
      The status should be failure
      The output should be present  # Shows the prompt
    End

    It 'accepts y input'
      Data "y"
      When call confirm_action "Test? "
      The status should be success
      The output should be present  # Shows the prompt
    End

    It 'accepts Y input'
      Data "Y"
      When call confirm_action "Test? "
      The status should be success
      The output should be present  # Shows the prompt
    End

    It 'rejects n input'
      Data "n"
      When call confirm_action "Test? "
      The status should be failure
      The output should be present  # Shows the prompt
    End

    It 'rejects other input'
      Data "maybe"
      When call confirm_action "Test? "
      The status should be failure
      The output should be present  # Shows the prompt
    End
  End
End
