# Integration tests for Shell Compatibility (bash & zsh)
# These tests verify that allyas works correctly in both bash and zsh

Describe 'Shell Compatibility'
  Include ./allyas.sh
  Include ./helpers/git.sh

  Describe 'Shell Detection'
    It 'identifies current shell'
      shell_name=""
      if [ -n "${BASH_VERSION:-}" ]; then
        shell_name="bash"
      elif [ -n "${ZSH_VERSION:-}" ]; then
        shell_name="zsh"
      fi
      The variable shell_name should not equal ''
    End
  End

  Describe 'Source File Detection'
    It 'can determine the source file location'
      The variable HELPERS_DIR should be present
    End
  End

  Describe 'Function Definitions'
    It 'defines ll as a function'
      When call type ll
      The output should include 'function'
    End

    It 'defines gis as a function'
      When call type gis
      The output should include 'function'
    End

    It 'defines gush as a function'
      When call type gush
      The output should include 'function'
    End

    It 'defines allyas as a function'
      When call type allyas
      The output should include 'function'
    End
  End

  Describe 'Array Handling'
    It 'handles array construction'
      files_to_scan=("./allyas.sh")
      files_to_scan+=("./helpers/git.sh")
      The variable 'files_to_scan' should be present
    End
  End

  Describe 'Command Substitution'
    It 'handles nested command substitution'
      result=$(echo "$(date +%Y)")
      The variable result should be present
    End
  End

  Describe 'Variable Expansion'
    It 'handles default value expansion'
      unset TEST_VAR
      result="${TEST_VAR:-default_value}"
      The variable result should equal 'default_value'
    End

    It 'handles set but empty variable expansion'
      TEST_VAR=""
      result="${TEST_VAR:-default_value}"
      The variable result should equal 'default_value'
    End

    It 'handles alternate value expansion'
      unset TEST_VAR
      : "${TEST_VAR:=assigned_value}"
      The variable TEST_VAR should equal 'assigned_value'
    End
  End

  Describe 'Git Helper Compatibility'
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

    Before 'setup_repo'
    After 'cleanup_repo'

    It 'get_current_branch works in current shell'
      When call get_current_branch
      The status should be success
      The output should not equal ''
    End

    It 'default_branch works in current shell'
      When call default_branch
      The status should be success
      The output should not equal ''
    End

    It 'confirm_action handles input in current shell'
      Data "y"
      When call confirm_action "Test? "
      The status should be success
      The output should be present  # Shows the prompt
    End
  End

  Describe 'POSIX Compatibility'
    It 'handles case statement'
      test_value="main"
      result=""
      case "$test_value" in
        main|master) result="default" ;;
        *) result="other" ;;
      esac
      The variable result should equal 'default'
    End

    It 'handles local variables'
      test_local_vars() {
        local var1="one"
        local var2="two"
        echo "$var1 $var2"
      }
      When call test_local_vars
      The output should equal 'one two'
    End
  End

  Describe 'Error Handling'
    It 'functions return proper exit codes'
      test_error() {
        return 1
      }
      When call test_error
      The status should be failure
    End
  End
End
