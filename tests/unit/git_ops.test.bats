#!/usr/bin/env bats
# Unit tests for git operations (Task 8 - Repo Update)

load '../helpers/fixtures'

setup() {
  setup_test_env
  commit_oneclick_in_test_repo

  # Set up a remote for the test repo
  (
    cd "$TEST_REPO"
    git remote add origin "https://github.com/testowner/testrepo.git" 2>/dev/null || true
  )
}

teardown() {
  teardown_test_env
}

@test "git_ops: requires clean working tree for update" {
  # Make repo dirty
  echo "dirty" > "$TEST_REPO/dirty.txt"

  # Try repo update (menu option 2)
  run bash -c 'printf "YES\n2\nYES\nYES\n" | timeout 5 bash '"$TEST_REPO"'/oneclick.sh 2>&1 || true'
  # Should fail due to dirty tree
  [[ "$output" == *"Dirty working tree"* ]] || [[ "$output" == *"dirty"* ]] || [[ "$status" -ne 0 ]]
}

@test "git_ops: menu option 2 triggers repo update" {
  run bash -c 'printf "YES\n2\n" | timeout 3 bash '"$TEST_REPO"'/oneclick.sh 2>&1 || true'
  # Should ask for confirmation
  [[ "$output" == *"Update repo"* ]] || [[ "$output" == *"DECISION REQUIRED"* ]]
}

@test "git_ops: repo update requires double YES (action + network)" {
  # The repo update requires two YES confirmations
  run bash -c 'printf "YES\n2\nYES\nno\n" | timeout 5 bash '"$TEST_REPO"'/oneclick.sh 2>&1 || true'
  # Should decline at network permission
  [[ "$output" == *"declined"* ]] || [[ "$status" -eq 3 ]]
}

@test "git_ops: parses https github origin" {
  (cd "$TEST_REPO" && git remote set-url origin "https://github.com/myowner/myrepo.git")

  run bash -c 'echo "YES" | timeout 2 bash '"$TEST_REPO"'/oneclick.sh 2>&1 || true'
  [[ "$output" == *"myowner/myrepo"* ]] || [[ "$output" == *"GitHub repo detected"* ]]
}

@test "git_ops: parses ssh github origin" {
  (cd "$TEST_REPO" && git remote set-url origin "git@github.com:sshowner/sshrepo.git")

  run bash -c 'echo "YES" | timeout 2 bash '"$TEST_REPO"'/oneclick.sh 2>&1 || true'
  [[ "$output" == *"sshowner/sshrepo"* ]] || [[ "$output" == *"GitHub repo detected"* ]]
}

@test "git_ops: handles missing origin gracefully" {
  (cd "$TEST_REPO" && git remote remove origin 2>/dev/null || true)

  run bash -c 'echo "YES" | timeout 2 bash '"$TEST_REPO"'/oneclick.sh 2>&1 || true'
  # Should not crash, should note origin issue
  [[ "$output" == *"not a parseable"* ]] || [[ "$output" == *"SELF-UPDATE"* ]]
}
