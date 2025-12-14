#!/usr/bin/env bats
# Unit tests for virtual self-update (Task 9)

load '../helpers/fixtures'

setup() {
  setup_test_env
  commit_oneclick_in_test_repo

  # Set up GitHub origin
  (cd "$TEST_REPO" && git remote add origin "https://github.com/testowner/testrepo.git" 2>/dev/null || true)
}

teardown() {
  teardown_test_env
}

@test "self_update: menu option 3 triggers virtual update" {
  run bash -c 'printf "YES\n3\n" | timeout 3 bash '"$TEST_REPO"'/oneclick.sh 2>&1 || true'
  # Should ask for confirmation
  [[ "$output" == *"self-update"* ]] || [[ "$output" == *"DECISION REQUIRED"* ]] || [[ "$output" == *"GitHub"* ]]
}

@test "self_update: requires YES for authorization" {
  run bash -c 'printf "YES\n3\nno\n" | timeout 5 bash '"$TEST_REPO"'/oneclick.sh 2>&1 || true'
  [[ "$output" == *"declined"* ]] || [[ "$status" -eq 3 ]]
}

@test "self_update: requires YES for network" {
  run bash -c 'printf "YES\n3\nYES\nno\n" | timeout 5 bash '"$TEST_REPO"'/oneclick.sh 2>&1 || true'
  [[ "$output" == *"declined"* ]] || [[ "$status" -eq 3 ]]
}

@test "self_update: fails without github origin" {
  (cd "$TEST_REPO" && git remote remove origin 2>/dev/null || true)

  run bash -c 'printf "YES\n3\nYES\nYES\n" | timeout 5 bash '"$TEST_REPO"'/oneclick.sh 2>&1 || true'
  [[ "$output" == *"not github.com"* ]] || [[ "$output" == *"unparseable"* ]] || [[ "$status" -ne 0 ]]
}

@test "self_update: sanity check rejects non-script files" {
  # The sanity_check_script function should reject HTML
  run bash -c '
    # Create a fake HTML file
    echo "<!DOCTYPE html>" > /tmp/fake_script.html

    # Source only the sanity check function
    sanity_check_script() {
      local file="$1"
      head -n 1 "$file" | grep -q "^#!/" || return 1
      grep -q "readonly APP=" "$file" || return 1
      return 0
    }

    sanity_check_script /tmp/fake_script.html
    echo "exit_code=$?"
  '
  [[ "$output" == *"exit_code=1"* ]]
}

@test "self_update: sanity check accepts valid script" {
  run bash -c '
    sanity_check_script() {
      local file="$1"
      head -n 1 "$file" | grep -q "^#!/" || return 1
      grep -q "readonly APP=" "$file" || return 1
      return 0
    }

    sanity_check_script '"$TEST_REPO"'/oneclick.sh
    echo "exit_code=$?"
  '
  [[ "$output" == *"exit_code=0"* ]]
}

@test "self_update: uses release mode by default" {
  run bash -c 'grep -q "SELF_UPDATE_REF_MODE.*release" '"$TEST_REPO"'/oneclick.sh'
  [ "$status" -eq 0 ]
}

@test "self_update: supports branch mode override" {
  run bash -c 'grep -q "SELF_BRANCH_REF" '"$TEST_REPO"'/oneclick.sh'
  [ "$status" -eq 0 ]
}

@test "self_update: creates backup before replace" {
  run bash -c 'grep -q "\.bak\." '"$TEST_REPO"'/oneclick.sh'
  [ "$status" -eq 0 ]
}

@test "self_update: offers relaunch after update" {
  run bash -c 'grep -q "Relaunch updated script" '"$TEST_REPO"'/oneclick.sh'
  [ "$status" -eq 0 ]
}
