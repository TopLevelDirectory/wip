#!/usr/bin/env bats
# Unit tests for repo structure validation

load '../helpers/fixtures'

setup() {
  # Don't use full test env for structure tests
  TEST_TEMP_DIR=""
}

teardown() {
  if [[ -n "$TEST_TEMP_DIR" && -d "$TEST_TEMP_DIR" ]]; then
    rm -rf "$TEST_TEMP_DIR"
  fi
}

@test "structure: oneclick.sh exists at repo root" {
  [ -f "$BATS_TEST_DIRNAME/../../oneclick.sh" ]
}

@test "structure: oneclick.sh is executable" {
  [ -x "$BATS_TEST_DIRNAME/../../oneclick.sh" ]
}

@test "structure: oneclick.sh has correct shebang" {
  local shebang
  shebang=$(head -n 1 "$BATS_TEST_DIRNAME/../../oneclick.sh")
  [ "$shebang" = "#!/usr/bin/env bash" ]
}

@test "structure: oneclick.sh contains APP marker" {
  grep -q 'readonly APP=' "$BATS_TEST_DIRNAME/../../oneclick.sh"
}

@test "structure: oneclick.sh contains VERSION marker" {
  grep -q 'readonly VERSION=' "$BATS_TEST_DIRNAME/../../oneclick.sh"
}

@test "structure: tests/unit directory exists" {
  [ -d "$BATS_TEST_DIRNAME" ]
}

@test "structure: tests/integration directory exists" {
  [ -d "$BATS_TEST_DIRNAME/../integration" ]
}

@test "structure: tests/helpers directory exists" {
  [ -d "$BATS_TEST_DIRNAME/../helpers" ]
}

@test "structure: tests/helpers/fixtures.bash exists" {
  [ -f "$BATS_TEST_DIRNAME/../helpers/fixtures.bash" ]
}

@test "structure: tests/helpers/fakebin directory exists" {
  [ -d "$BATS_TEST_DIRNAME/../helpers/fakebin" ]
}

@test "structure: docs/SECURITY.md exists" {
  [ -f "$BATS_TEST_DIRNAME/../../docs/SECURITY.md" ]
}

@test "structure: docs/INSTALL.md exists" {
  [ -f "$BATS_TEST_DIRNAME/../../docs/INSTALL.md" ]
}

@test "structure: docs/PRO.md exists" {
  [ -f "$BATS_TEST_DIRNAME/../../docs/PRO.md" ]
}

@test "structure: docs/TOOLCHAIN.md exists" {
  [ -f "$BATS_TEST_DIRNAME/../../docs/TOOLCHAIN.md" ]
}

@test "structure: .gitignore exists" {
  [ -f "$BATS_TEST_DIRNAME/../../.gitignore" ]
}

@test "structure: .gitignore contains logs/" {
  grep -q '^logs/' "$BATS_TEST_DIRNAME/../../.gitignore"
}

@test "structure: .gitignore contains .locks/" {
  grep -q '^\.locks/' "$BATS_TEST_DIRNAME/../../.gitignore"
}

@test "structure: .gitignore contains .venv/" {
  grep -q '^\.venv/' "$BATS_TEST_DIRNAME/../../.gitignore"
}

@test "structure: dev/test.sh exists and is executable" {
  [ -x "$BATS_TEST_DIRNAME/../../dev/test.sh" ]
}

@test "structure: fakebin/git exists and is executable" {
  [ -x "$BATS_TEST_DIRNAME/../helpers/fakebin/git" ]
}

@test "structure: fakebin/curl exists and is executable" {
  [ -x "$BATS_TEST_DIRNAME/../helpers/fakebin/curl" ]
}

@test "structure: fakebin/uv exists and is executable" {
  [ -x "$BATS_TEST_DIRNAME/../helpers/fakebin/uv" ]
}
