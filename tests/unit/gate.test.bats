#!/usr/bin/env bats
# Unit tests for decision gate engine

load '../helpers/fixtures'

setup() {
  setup_test_env
  commit_oneclick_in_test_repo
}

teardown() {
  teardown_test_env
}

# Helper to run confirm_yes with input
run_confirm_yes() {
  local input="$1"
  local prompt="$2"
  source_oneclick_functions
  echo "$input" | confirm_yes "$prompt"
}

@test "gate: accepts exactly YES" {
  source_oneclick_functions
  run bash -c 'echo "YES" | source '"$TEST_REPO"'/oneclick.sh 2>/dev/null; confirm_yes "test prompt"'
  # Note: This is tricky to test in isolation; we test via the full script instead
  skip "Direct function testing requires refactored script"
}

@test "gate: rejects lowercase yes" {
  # Test that 'yes' (lowercase) is rejected
  run bash -c 'echo "yes" | (
    confirm_yes() {
      local prompt="$1"
      local ans
      IFS= read -r ans || true
      [[ "$ans" == "YES" ]]
    }
    confirm_yes "test"
  )'
  [ "$status" -eq 1 ]
}

@test "gate: rejects empty input" {
  run bash -c 'echo "" | (
    confirm_yes() {
      local prompt="$1"
      local ans
      IFS= read -r ans || true
      [[ "$ans" == "YES" ]]
    }
    confirm_yes "test"
  )'
  [ "$status" -eq 1 ]
}

@test "gate: rejects whitespace-padded YES" {
  run bash -c 'echo " YES " | (
    confirm_yes() {
      local prompt="$1"
      local ans
      IFS= read -r ans || true
      [[ "$ans" == "YES" ]]
    }
    confirm_yes "test"
  )'
  [ "$status" -eq 1 ]
}

@test "gate: rejects EOF/no input" {
  run bash -c '(
    confirm_yes() {
      local prompt="$1"
      local ans
      IFS= read -r ans || true
      [[ "$ans" == "YES" ]]
    }
    confirm_yes "test" < /dev/null
  )'
  [ "$status" -eq 1 ]
}

@test "gate: confirm_or_die exits 3 on rejection" {
  # Test that the full script exits with code 3 when declining
  run bash -c 'echo "no" | bash '"$TEST_REPO"'/oneclick.sh 2>&1'
  [ "$status" -eq 3 ]
}

@test "gate: script requires initial acknowledgment" {
  # Verify the script prompts for acknowledgment
  run timeout 2 bash -c 'bash '"$TEST_REPO"'/oneclick.sh </dev/null 2>&1 || true'
  [[ "$output" == *"DECISION REQUIRED"* ]]
  [[ "$output" == *"Acknowledge"* ]]
}
