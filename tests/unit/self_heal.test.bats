#!/usr/bin/env bats
# Unit tests for self-heal locally (Task 7)

load '../helpers/fixtures'

setup() {
  setup_test_env
  commit_oneclick_in_test_repo
}

teardown() {
  teardown_test_env
}

@test "self_heal: detects modified script" {
  # Modify the script after commit
  echo "# Modified" >> "$TEST_REPO/oneclick.sh"

  run bash -c 'echo "YES" | timeout 2 bash '"$TEST_REPO"'/oneclick.sh 2>&1 || true'
  [[ "$output" == *"modified"* ]] || [[ "$output" == *"SELF-HEAL"* ]]
}

@test "self_heal: reports clean when script unmodified" {
  run bash -c 'echo "YES" | timeout 2 bash '"$TEST_REPO"'/oneclick.sh 2>&1 || true'
  [[ "$output" == *"matches HEAD"* ]]
}

@test "self_heal: menu option 1 triggers self-heal" {
  # Modify script and try to heal
  echo "# Modified" >> "$TEST_REPO/oneclick.sh"

  # YES for ack, then 1 for self-heal menu, then YES for confirm, then 6 to quit
  run bash -c 'printf "YES\n1\nYES\n6\n" | timeout 5 bash '"$TEST_REPO"'/oneclick.sh 2>&1 || true'
  # Should either restore or ask for confirmation
  [[ "$output" == *"SELF-HEAL"* ]] || [[ "$output" == *"restore"* ]] || [[ "$output" == *"Restore"* ]]
}

@test "self_heal: requires YES to restore" {
  echo "# Modified" >> "$TEST_REPO/oneclick.sh"

  # Try with 'no' instead of YES
  run bash -c 'printf "YES\n1\nno\n6\n" | timeout 5 bash '"$TEST_REPO"'/oneclick.sh 2>&1 || true'
  # Should decline
  [[ "$output" == *"declined"* ]] || [[ "$status" -eq 3 ]]
}

@test "self_heal: no action needed when clean" {
  run bash -c 'printf "YES\n1\n6\n" | timeout 5 bash '"$TEST_REPO"'/oneclick.sh 2>&1 || true'
  [[ "$output" == *"No local heal needed"* ]] || [[ "$output" == *"matches HEAD"* ]]
}
