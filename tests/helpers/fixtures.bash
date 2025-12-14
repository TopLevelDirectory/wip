#!/usr/bin/env bash
# Test fixtures and helpers for bats tests

# Create a temporary directory for test isolation
setup_test_env() {
  TEST_TEMP_DIR="$(mktemp -d)"
  export TEST_TEMP_DIR

  # Create fake home for git config isolation
  export HOME="$TEST_TEMP_DIR/home"
  mkdir -p "$HOME"

  # Create a fake repo structure
  export TEST_REPO="$TEST_TEMP_DIR/repo"
  mkdir -p "$TEST_REPO"

  # Initialize git repo for tests that need it
  if [[ "${INIT_GIT_REPO:-true}" == "true" ]]; then
    (
      cd "$TEST_REPO" || exit 1
      git init -q
      git config user.email "test@example.com"
      git config user.name "Test User"
    )
  fi

  # Add fakebin to PATH (prepend so it takes precedence)
  export ORIGINAL_PATH="$PATH"
  export PATH="${BATS_TEST_DIRNAME}/../helpers/fakebin:$PATH"

  # Change to test repo
  cd "$TEST_REPO" || exit 1
}

# Cleanup after tests
teardown_test_env() {
  cd / || true
  if [[ -n "$TEST_TEMP_DIR" && -d "$TEST_TEMP_DIR" ]]; then
    rm -rf "$TEST_TEMP_DIR"
  fi

  # Restore original PATH
  if [[ -n "$ORIGINAL_PATH" ]]; then
    export PATH="$ORIGINAL_PATH"
  fi
}

# Copy oneclick.sh to test repo
copy_oneclick_to_test_repo() {
  local src="${BATS_TEST_DIRNAME}/../../oneclick.sh"
  if [[ -f "$src" ]]; then
    cp "$src" "$TEST_REPO/oneclick.sh"
    chmod +x "$TEST_REPO/oneclick.sh"
  else
    echo "ERROR: oneclick.sh not found at $src" >&2
    return 1
  fi
}

# Add oneclick.sh to git in test repo
commit_oneclick_in_test_repo() {
  copy_oneclick_to_test_repo || return 1
  (
    cd "$TEST_REPO" || exit 1
    git add oneclick.sh
    git commit -q -m "Add oneclick.sh"
  )
}

# Create a mock requirements.txt
create_requirements_txt() {
  local content="${1:-requests==2.31.0}"
  echo "$content" > "$TEST_REPO/requirements.txt"
}

# Mock stdin input for testing decision gates
# Usage: mock_input "YES" | run_function
mock_input() {
  echo "$1"
}

# Assert file contains pattern
assert_file_contains() {
  local file="$1"
  local pattern="$2"
  if ! grep -q "$pattern" "$file"; then
    echo "Expected file '$file' to contain pattern '$pattern'" >&2
    echo "File contents:" >&2
    cat "$file" >&2
    return 1
  fi
}

# Assert file does not contain pattern
assert_file_not_contains() {
  local file="$1"
  local pattern="$2"
  if grep -q "$pattern" "$file"; then
    echo "Expected file '$file' to NOT contain pattern '$pattern'" >&2
    return 1
  fi
}

# Assert command output contains pattern
assert_output_contains() {
  local pattern="$1"
  if [[ ! "$output" =~ $pattern ]]; then
    echo "Expected output to contain pattern '$pattern'" >&2
    echo "Actual output: $output" >&2
    return 1
  fi
}

# Assert exit status
assert_exit_status() {
  local expected="$1"
  if [[ "$status" -ne "$expected" ]]; then
    echo "Expected exit status $expected, got $status" >&2
    echo "Output: $output" >&2
    return 1
  fi
}

# Create a fake GitHub API response for releases
create_github_release_fixture() {
  local tag="${1:-v3.0.0}"
  local fixture_dir="$TEST_TEMP_DIR/fixtures"
  mkdir -p "$fixture_dir"

  cat > "$fixture_dir/latest_release.json" << EOF
{
  "tag_name": "$tag",
  "name": "Release $tag",
  "published_at": "2025-01-01T00:00:00Z",
  "assets": []
}
EOF

  echo "$fixture_dir/latest_release.json"
}

# Enable/disable specific fakebin commands
enable_fakebin() {
  local cmd="$1"
  chmod +x "${BATS_TEST_DIRNAME}/../helpers/fakebin/$cmd" 2>/dev/null || true
}

disable_fakebin() {
  local cmd="$1"
  chmod -x "${BATS_TEST_DIRNAME}/../helpers/fakebin/$cmd" 2>/dev/null || true
}

# Set fakebin behavior via environment
set_fakebin_behavior() {
  local cmd="$1"
  local behavior="$2"
  export "FAKEBIN_${cmd^^}_BEHAVIOR=$behavior"
}

# Source oneclick.sh functions without running main
source_oneclick_functions() {
  # We need to source only the functions, not run main
  # This works by defining a stub main before sourcing
  local temp_script="$TEST_TEMP_DIR/oneclick_funcs.bash"

  # Extract functions from oneclick.sh (everything before main "$@")
  sed '/^main "\$@"$/d' "$TEST_REPO/oneclick.sh" > "$temp_script"

  # shellcheck disable=SC1090
  source "$temp_script"
}
