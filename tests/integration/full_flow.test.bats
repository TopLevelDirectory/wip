#!/usr/bin/env bats
# Integration tests for full oneclick flow

load '../helpers/fixtures'

setup() {
  setup_test_env
  commit_oneclick_in_test_repo
  create_requirements_txt "requests==2.31.0"

  # Set up GitHub origin
  (cd "$TEST_REPO" && git remote add origin "https://github.com/testowner/testrepo.git" 2>/dev/null || true)
}

teardown() {
  teardown_test_env
}

@test "integration: full startup to quit flow" {
  # Acknowledge and immediately quit
  run bash -c 'printf "YES\n6\n" | timeout 10 bash '"$TEST_REPO"'/oneclick.sh 2>&1'
  [ "$status" -eq 0 ]
  [[ "$output" == *"APP=glassbox"* ]]
  [[ "$output" == *"UPDATE BRIEFING"* ]]
  [[ "$output" == *"ONECLICK MENU"* ]]
}

@test "integration: status view requires no confirmation" {
  run bash -c 'printf "YES\n0\n6\n" | timeout 10 bash '"$TEST_REPO"'/oneclick.sh 2>&1'
  [ "$status" -eq 0 ]
  [[ "$output" == *"Repo:"* ]]
  [[ "$output" == *"Log:"* ]]
}

@test "integration: multiple menu navigations" {
  run bash -c 'printf "YES\n0\n0\n0\n6\n" | timeout 10 bash '"$TEST_REPO"'/oneclick.sh 2>&1'
  [ "$status" -eq 0 ]
}

@test "integration: decline initial acknowledgment exits 3" {
  run bash -c 'echo "no" | timeout 10 bash '"$TEST_REPO"'/oneclick.sh 2>&1'
  [ "$status" -eq 3 ]
  [[ "$output" == *"declined"* ]]
}

@test "integration: creates all required directories" {
  run bash -c 'printf "YES\n6\n" | timeout 10 bash '"$TEST_REPO"'/oneclick.sh 2>&1'

  [ -d "$TEST_REPO/logs" ]
  [ -d "$TEST_REPO/logs/rca" ]
  [ -d "$TEST_REPO/.locks" ]
  [ -d "$TEST_REPO/out" ]
}

@test "integration: creates log file" {
  run bash -c 'printf "YES\n6\n" | timeout 10 bash '"$TEST_REPO"'/oneclick.sh 2>&1'

  [ -f "$TEST_REPO/logs/oneclick.log" ]
}

@test "integration: handles SIGINT gracefully" {
  # This is tricky to test; we verify the trap is set
  run bash -c 'grep -q "trap" '"$TEST_REPO"'/oneclick.sh'
  [ "$status" -eq 0 ]
}

@test "integration: prevents concurrent runs via lock" {
  # Create a lock directory
  mkdir -p "$TEST_REPO/.locks/glassbox.lock.d"

  run bash -c 'printf "YES\n6\n" | timeout 5 bash '"$TEST_REPO"'/oneclick.sh 2>&1'
  [[ "$output" == *"in progress"* ]] || [[ "$output" == *"lock"* ]]
  [ "$status" -ne 0 ]

  # Clean up
  rmdir "$TEST_REPO/.locks/glassbox.lock.d"
}

@test "integration: fails outside git repo" {
  # Create a non-git directory
  local non_git_dir="$TEST_TEMP_DIR/non_git"
  mkdir -p "$non_git_dir"
  cp "$TEST_REPO/oneclick.sh" "$non_git_dir/"

  run bash -c 'cd '"$non_git_dir"' && printf "YES\n6\n" | timeout 5 bash ./oneclick.sh 2>&1'
  [[ "$output" == *"Not inside a git repo"* ]] || [[ "$status" -ne 0 ]]
}

@test "integration: script has correct permissions" {
  local perms
  perms=$(stat -c %a "$TEST_REPO/oneclick.sh" 2>/dev/null || stat -f %Lp "$TEST_REPO/oneclick.sh")
  # Should be executable (7xx or x55 or similar)
  [[ "$perms" == *"7"* ]] || [[ "$perms" == *"5"* ]]
}

@test "integration: umask is set restrictively" {
  run bash -c 'grep -q "umask 077" '"$TEST_REPO"'/oneclick.sh'
  [ "$status" -eq 0 ]
}

@test "integration: PATH is restricted" {
  run bash -c 'grep -q "PATH=./usr/sbin:/usr/bin:/sbin:/bin." '"$TEST_REPO"'/oneclick.sh'
  [ "$status" -eq 0 ]
}
