# Unit tests for General Functions in allyas.sh

Describe 'General Functions'
  Include ./allyas.sh

  Describe 'Directory listing functions'
    Describe 'll()'
      It 'lists files in long format'
        When call ll /
        The status should be success
        The output should be present
      End

      It 'passes additional arguments to ls'
        When call ll -d /tmp
        The status should be success
        The output should be present
      End
    End

    Describe 'la()'
      It 'lists files including hidden'
        When call la /
        The status should be success
        The output should be present
      End
    End

    Describe 'l()'
      It 'lists files in columns'
        When call l /
        The status should be success
        The output should be present
      End
    End

    Describe 'lt()'
      It 'lists files sorted by modification time'
        When call lt /
        The status should be success
        The output should be present
      End
    End

    Describe 'lsize()'
      It 'lists files sorted by size'
        When call lsize /
        The status should be success
        The output should be present
      End
    End
  End

  Describe 'Navigation functions'
    # Navigation functions change directory, so we test them by checking PWD

    Describe '..()'
      setup() {
        ORIGINAL_DIR=$(pwd)
        TEST_DIR=$(mktemp -d)
        mkdir -p "$TEST_DIR/a/b/c"
        cd "$TEST_DIR/a/b/c"
      }

      cleanup() {
        cd "$ORIGINAL_DIR"
        rm -rf "$TEST_DIR"
      }

      Before 'setup'
      After 'cleanup'

      It 'navigates up one directory'
        ..
        The value "$PWD" should end with '/a/b'
      End
    End

    Describe '...()'
      setup() {
        ORIGINAL_DIR=$(pwd)
        TEST_DIR=$(mktemp -d)
        mkdir -p "$TEST_DIR/a/b/c"
        cd "$TEST_DIR/a/b/c"
      }

      cleanup() {
        cd "$ORIGINAL_DIR"
        rm -rf "$TEST_DIR"
      }

      Before 'setup'
      After 'cleanup'

      It 'navigates up two directories'
        ...
        The value "$PWD" should end with '/a'
      End
    End
  End

  Describe 'grep()'
    setup() {
      echo "test line" > /tmp/shellspec_grep_test.txt
    }

    cleanup() {
      rm -f /tmp/shellspec_grep_test.txt
    }

    Before 'setup'
    After 'cleanup'

    It 'wraps grep with color'
      When call grep "test" /tmp/shellspec_grep_test.txt
      The status should be success
      The output should include 'test'
    End

    It 'returns failure when no match'
      When call grep "notfound" /tmp/shellspec_grep_test.txt
      The status should be failure
    End
  End

  Describe 'count()'
    setup() {
      TEST_DIR=$(mktemp -d)
      touch "$TEST_DIR/file1" "$TEST_DIR/file2" "$TEST_DIR/file3"
      mkdir -p "$TEST_DIR/subdir"
      touch "$TEST_DIR/subdir/file4"
      cd "$TEST_DIR"
    }

    cleanup() {
      cd /
      rm -rf "$TEST_DIR"
    }

    Before 'setup'
    After 'cleanup'

    It 'counts files in directory and subdirectories'
      When call count
      The status should be success
      The output should include '4'
    End
  End

  Describe 'Date functions'
    Describe 'now()'
      It 'displays current date and time'
        When call now
        The status should be success
        The output should match pattern '20[0-9][0-9]-[0-9][0-9]-[0-9][0-9] [0-9][0-9]:[0-9][0-9]:[0-9][0-9]'
      End
    End

    Describe 'week()'
      It 'displays current week number'
        When call week
        The status should be success
        The output should match pattern '[0-5][0-9]'
      End
    End
  End

  Describe 'cdtemp()'
    setup() {
      ORIGINAL_DIR=$(pwd)
    }

    cleanup() {
      cd "$ORIGINAL_DIR"
    }

    Before 'setup'
    After 'cleanup'

    It 'creates and navigates to a temp directory'
      cdtemp
      # On macOS, temp dirs can be in /private/var/folders or /var/folders
      The value "$PWD" should match pattern '/*'
      The value "$PWD" should not equal "$ORIGINAL_DIR"
    End
  End
End
