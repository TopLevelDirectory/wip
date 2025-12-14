#!/usr/bin/env bats
# Unit tests for game-console menu (Task 12)

load '../helpers/fixtures'

setup() {
  setup_test_env
  commit_oneclick_in_test_repo
}

teardown() {
  teardown_test_env
}

@test "menu: displays after acknowledgment" {
  run bash -c 'printf "YES\n6\n" | timeout 5 bash '"$TEST_REPO"'/oneclick.sh 2>&1 || true'
  [[ "$output" == *"ONECLICK MENU"* ]]
}

@test "menu: shows all options 0-6" {
  run bash -c 'printf "YES\n6\n" | timeout 5 bash '"$TEST_REPO"'/oneclick.sh 2>&1 || true'
  [[ "$output" == *"0)"* ]]
  [[ "$output" == *"1)"* ]]
  [[ "$output" == *"2)"* ]]
  [[ "$output" == *"3)"* ]]
  [[ "$output" == *"4)"* ]]
  [[ "$output" == *"5)"* ]]
  [[ "$output" == *"6)"* ]]
}

@test "menu: option 0 shows status (no YES required)" {
  run bash -c 'printf "YES\n0\n6\n" | timeout 5 bash '"$TEST_REPO"'/oneclick.sh 2>&1 || true'
  [[ "$output" == *"Repo:"* ]]
  [[ "$output" == *"Log:"* ]]
}

@test "menu: option 6 quits cleanly" {
  run bash -c 'printf "YES\n6\n" | timeout 5 bash '"$TEST_REPO"'/oneclick.sh 2>&1'
  [ "$status" -eq 0 ]
}

@test "menu: invalid option shows error and continues" {
  run bash -c 'printf "YES\n99\n6\n" | timeout 5 bash '"$TEST_REPO"'/oneclick.sh 2>&1 || true'
  [[ "$output" == *"Invalid selection"* ]]
  [ "$status" -eq 0 ]
}

@test "menu: displays app name and version" {
  run bash -c 'printf "YES\n6\n" | timeout 5 bash '"$TEST_REPO"'/oneclick.sh 2>&1 || true'
  [[ "$output" == *"glassbox"* ]]
  [[ "$output" == *"v3.0.0"* ]] || [[ "$output" == *"VERSION"* ]]
}

@test "menu: loops until quit" {
  # Select multiple options, then quit
  run bash -c 'printf "YES\n0\n0\n6\n" | timeout 5 bash '"$TEST_REPO"'/oneclick.sh 2>&1 || true'
  # Should show menu multiple times
  menu_count=$(echo "$output" | grep -c "ONECLICK MENU" || true)
  [ "$menu_count" -ge 2 ]
}

@test "menu: handles empty input gracefully" {
  run bash -c 'printf "YES\n\n6\n" | timeout 5 bash '"$TEST_REPO"'/oneclick.sh 2>&1 || true'
  [[ "$output" == *"Invalid selection"* ]]
  [ "$status" -eq 0 ]
}
