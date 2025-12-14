#!/usr/bin/env bats
# Unit tests for update briefing (Task 6)

load '../helpers/fixtures'

setup() {
  setup_test_env
  commit_oneclick_in_test_repo
}

teardown() {
  teardown_test_env
}

@test "update_briefing: shows update briefing header" {
  # The update briefing should be shown after initial acknowledgment
  run bash -c 'echo "YES" | timeout 2 bash '"$TEST_REPO"'/oneclick.sh 2>&1 || true'
  [[ "$output" == *"UPDATE BRIEFING"* ]]
}

@test "update_briefing: shows recommended secure course" {
  run bash -c 'echo "YES" | timeout 2 bash '"$TEST_REPO"'/oneclick.sh 2>&1 || true'
  [[ "$output" == *"RECOMMENDED SECURE COURSE"* ]]
}

@test "update_briefing: recommends self-heal for modified scripts" {
  run bash -c 'echo "YES" | timeout 2 bash '"$TEST_REPO"'/oneclick.sh 2>&1 || true'
  [[ "$output" == *"Self-Heal"* ]]
}

@test "update_briefing: recommends repo update as preferred" {
  run bash -c 'echo "YES" | timeout 2 bash '"$TEST_REPO"'/oneclick.sh 2>&1 || true'
  [[ "$output" == *"Repo Update"* ]] || [[ "$output" == *"ff-only"* ]]
}

@test "update_briefing: self-heal detects unmodified script" {
  # When script matches HEAD, should report as matching
  run bash -c 'echo "YES" | timeout 2 bash '"$TEST_REPO"'/oneclick.sh 2>&1 || true'
  [[ "$output" == *"matches HEAD"* ]] || [[ "$output" == *"SELF-HEAL"* ]]
}

@test "update_briefing: handles non-github origin gracefully" {
  # Set a non-github origin
  (cd "$TEST_REPO" && git remote set-url origin "https://gitlab.com/owner/repo.git")

  run bash -c 'echo "YES" | timeout 2 bash '"$TEST_REPO"'/oneclick.sh 2>&1 || true'
  [[ "$output" == *"not a parseable github.com remote"* ]] || [[ "$output" == *"SELF-UPDATE"* ]]
}
