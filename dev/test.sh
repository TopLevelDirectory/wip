#!/usr/bin/env bash
# Test runner script for oneclick
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() { echo -e "${GREEN}[INFO]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }

# Check for bats
check_bats() {
  if ! command -v bats >/dev/null 2>&1; then
    log_error "bats-core not found. Install it first:"
    echo "  Linux: git clone https://github.com/bats-core/bats-core.git && cd bats-core && sudo ./install.sh /usr/local"
    echo "  macOS: brew install bats-core"
    exit 1
  fi
  log_info "Using bats: $(command -v bats)"
}

# Check for shellcheck
check_shellcheck() {
  if ! command -v shellcheck >/dev/null 2>&1; then
    log_warn "shellcheck not found. Linting will be skipped."
    return 1
  fi
  log_info "Using shellcheck: $(command -v shellcheck)"
  return 0
}

# Check for shfmt
check_shfmt() {
  if ! command -v shfmt >/dev/null 2>&1; then
    log_warn "shfmt not found. Format checking will be skipped."
    return 1
  fi
  log_info "Using shfmt: $(command -v shfmt)"
  return 0
}

# Run shellcheck
run_lint() {
  log_info "Running shellcheck..."
  local files=(
    "$PROJECT_ROOT/oneclick.sh"
    "$PROJECT_ROOT/dev/test.sh"
    "$PROJECT_ROOT/tests/helpers/fixtures.bash"
  )

  local failed=0
  for f in "${files[@]}"; do
    if [[ -f "$f" ]]; then
      if ! shellcheck -x "$f"; then
        failed=1
      fi
    fi
  done

  if [[ $failed -eq 0 ]]; then
    log_info "shellcheck passed"
  else
    log_error "shellcheck found issues"
  fi
  return $failed
}

# Run shfmt check
run_format_check() {
  log_info "Running shfmt check..."
  local files=(
    "$PROJECT_ROOT/oneclick.sh"
    "$PROJECT_ROOT/dev/test.sh"
  )

  local failed=0
  for f in "${files[@]}"; do
    if [[ -f "$f" ]]; then
      if ! shfmt -d "$f" >/dev/null 2>&1; then
        log_error "Format issues in: $f"
        shfmt -d "$f" || true
        failed=1
      fi
    fi
  done

  if [[ $failed -eq 0 ]]; then
    log_info "shfmt check passed"
  else
    log_error "shfmt found format issues"
  fi
  return $failed
}

# Run unit tests
run_unit_tests() {
  log_info "Running unit tests..."
  local test_dir="$PROJECT_ROOT/tests/unit"

  if [[ ! -d "$test_dir" ]] || [[ -z "$(ls -A "$test_dir"/*.bats 2>/dev/null)" ]]; then
    log_warn "No unit tests found in $test_dir"
    return 0
  fi

  bats "$test_dir"/*.bats
}

# Run integration tests
run_integration_tests() {
  log_info "Running integration tests..."
  local test_dir="$PROJECT_ROOT/tests/integration"

  if [[ ! -d "$test_dir" ]] || [[ -z "$(ls -A "$test_dir"/*.bats 2>/dev/null)" ]]; then
    log_warn "No integration tests found in $test_dir"
    return 0
  fi

  bats "$test_dir"/*.bats
}

# Run all tests
run_all() {
  local exit_code=0

  check_bats

  # Lint (non-blocking for now)
  if check_shellcheck; then
    run_lint || true
  fi

  # Format check (non-blocking for now)
  if check_shfmt; then
    run_format_check || true
  fi

  # Unit tests
  run_unit_tests || exit_code=1

  # Integration tests
  run_integration_tests || exit_code=1

  if [[ $exit_code -eq 0 ]]; then
    log_info "All tests passed!"
  else
    log_error "Some tests failed"
  fi

  return $exit_code
}

# Main
case "${1:-all}" in
  lint)
    check_shellcheck && run_lint
    ;;
  format)
    check_shfmt && run_format_check
    ;;
  unit)
    check_bats && run_unit_tests
    ;;
  integration)
    check_bats && run_integration_tests
    ;;
  all)
    run_all
    ;;
  *)
    echo "Usage: $0 {lint|format|unit|integration|all}"
    exit 1
    ;;
esac
