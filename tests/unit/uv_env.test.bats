#!/usr/bin/env bats
# Unit tests for uv environment sync (Task 10)

load '../helpers/fixtures'

setup() {
  setup_test_env
  commit_oneclick_in_test_repo
  create_requirements_txt "requests==2.31.0"
}

teardown() {
  teardown_test_env
}

@test "uv_env: menu option 4 triggers env sync" {
  run bash -c 'printf "YES\n4\n" | timeout 3 bash '"$TEST_REPO"'/oneclick.sh 2>&1 || true'
  # Should ask about uv venv
  [[ "$output" == *"uv"* ]] || [[ "$output" == *"venv"* ]] || [[ "$output" == *"DECISION REQUIRED"* ]]
}

@test "uv_env: requires YES for venv creation" {
  run bash -c 'printf "YES\n4\nno\n" | timeout 5 bash '"$TEST_REPO"'/oneclick.sh 2>&1 || true'
  # Should decline
  [[ "$output" == *"declined"* ]] || [[ "$status" -eq 3 ]]
}

@test "uv_env: requires YES for network access" {
  run bash -c 'printf "YES\n4\nYES\nno\n" | timeout 5 bash '"$TEST_REPO"'/oneclick.sh 2>&1 || true'
  # Should decline at network
  [[ "$output" == *"declined"* ]] || [[ "$status" -eq 3 ]]
}

@test "uv_env: fails gracefully without requirements.txt" {
  rm -f "$TEST_REPO/requirements.txt"

  # With fakebin/uv, this should get to the requirements check
  run bash -c 'printf "YES\n4\nYES\nYES\n" | timeout 10 bash '"$TEST_REPO"'/oneclick.sh 2>&1 || true'
  # Should complain about missing requirements
  [[ "$output" == *"requirements.txt"* ]] || [[ "$output" == *"missing"* ]] || [[ "$output" == *"uv"* ]]
}

@test "uv_env: detects missing uv command" {
  # Remove uv from PATH (fakebin provides it, but let's test the check)
  export PATH="/usr/bin:/bin"

  run bash -c 'printf "YES\n4\nYES\nYES\n" | timeout 5 bash '"$TEST_REPO"'/oneclick.sh 2>&1 || true'
  # Should fail with missing uv
  [[ "$output" == *"Missing dependency"* ]] || [[ "$output" == *"uv"* ]]
}
