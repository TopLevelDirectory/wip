#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'
umask 077
PATH='/usr/sbin:/usr/bin:/sbin:/bin'

readonly APP="glassbox"
readonly VERSION="3.0.0"

readonly LOG_DIR="./logs"
readonly OUT_DIR="./out"
readonly LOCK_DIR="./.locks"
readonly LOG_FILE="${LOG_DIR}/oneclick.log"
readonly RCA_DIR="${LOG_DIR}/rca"

# Script location + relative path used for self-update downloads.
readonly SELF_PATH_DEFAULT="oneclick.sh"
SELF_PATH="${SELF_PATH:-$SELF_PATH_DEFAULT}"

# Prefer releases for "latest image of itself". Fallback: use default branch if you opt in.
SELF_UPDATE_REF_MODE="${SELF_UPDATE_REF_MODE:-release}" # release | branch
SELF_BRANCH_REF="${SELF_BRANCH_REF:-main}"              # only used if mode=branch

# ============= logging / RCA =============
ts() { date -u +"%Y-%m-%dT%H:%M:%SZ"; }
log() { printf '%s [%s] %s\n' "$(ts)" "$1" "$2" | tee -a "$LOG_FILE" >&2; }
die() { log "FATAL" "$1"; exit "${2:-1}"; }

rca_dump() {
  local ec=$?
  mkdir -p "$RCA_DIR" "$LOG_DIR" "$OUT_DIR" "$LOCK_DIR" >/dev/null 2>&1 || true
  local stamp rca
  stamp="$(date -u +"%Y%m%dT%H%M%SZ")"
  rca="${RCA_DIR}/rca_${stamp}.txt"

  {
    echo "timestamp_utc=$(ts)"
    echo "exit_code=${ec}"
    echo "app=${APP}"
    echo "version=${VERSION}"
    echo "pwd=$(pwd)"
    echo "user=$(id -u) group=$(id -g)"
    echo "bash_version=${BASH_VERSION:-unknown}"
    echo "uname=$(uname -a || true)"
    echo "last_command=${BASH_COMMAND:-unknown}"
    echo "line=${BASH_LINENO[0]:-unknown}"
    echo
    echo "---- git ----"
    if command -v git >/dev/null 2>&1 && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
      echo "top=$(git rev-parse --show-toplevel || true)"
      echo "branch=$(git rev-parse --abbrev-ref HEAD || true)"
      echo "head=$(git rev-parse HEAD || true)"
      echo "status_porcelain:"
      git status --porcelain || true
    else
      echo "git=unavailable_or_not_a_repo"
    fi
    echo
    echo "---- log_tail ----"
    tail -n 200 "$LOG_FILE" 2>/dev/null || true
  } >"$rca" || true

  log "ERROR" "RCA written: $rca"
  exit "$ec"
}
trap rca_dump ERR

need_cmd() { command -v "$1" >/dev/null 2>&1 || die "Missing dependency: $1"; }

ensure_dirs() {
  mkdir -p "$LOG_DIR" "$OUT_DIR" "$LOCK_DIR" "$RCA_DIR"
  : > "$LOG_FILE" || die "Cannot write log: $LOG_FILE"
}

acquire_lock() {
  local lock_name="${APP}.lock"
  if command -v flock >/dev/null 2>&1; then
    exec 9> "${LOCK_DIR}/${lock_name}"
    flock -n 9 || die "Another run is in progress (lock held)."
  else
    local ldir="${LOCK_DIR}/${lock_name}.d"
    mkdir "$ldir" 2>/dev/null || die "Another run is in progress (lock held)."
    trap 'rmdir "'"$ldir"'" 2>/dev/null || true' EXIT
  fi
}

require_repo_root() {
  need_cmd git
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || die "Not inside a git repo."
  local top; top="$(git rev-parse --show-toplevel)"
  cd "$top"
}

require_clean_spine() {
  [[ -z "$(git status --porcelain)" ]] || die "Dirty working tree. Commit/stash before proceeding."
}

# Best-effort net-off wrapper (still safe if unshare missing)
with_net_off() {
  if command -v unshare >/dev/null 2>&1; then
    log "INFO" "Attempting network isolation (unshare -n)."
    if unshare -n -- "$@"; then return 0; fi
    log "WARN" "unshare -n failed; continuing without net namespace isolation."
  else
    log "WARN" "unshare not present; continuing without net namespace isolation."
  fi
  "$@"
}

# ============= decision gates (default deny) =============
confirm_yes() {
  local prompt="$1"
  printf '\nDECISION REQUIRED: %s\nType YES to approve: ' "$prompt" >&2
  local ans; IFS= read -r ans || true
  [[ "$ans" == "YES" ]]
}
confirm_or_die() { confirm_yes "$1" || die "Operator declined: $1" 3; }

# ============= GitHub origin parsing =============
# Supports:
#   https://github.com/OWNER/REPO.git
#   git@github.com:OWNER/REPO.git
# Returns "OWNER REPO" on stdout, or nothing if not parseable.
parse_github_origin() {
  local url
  url="$(git remote get-url origin 2>/dev/null || true)"
  [[ -n "$url" ]] || return 1

  # Normalize
  url="${url%.git}"

  # https
  if [[ "$url" =~ ^https://github\.com/([^/]+)/([^/]+)$ ]]; then
    printf '%s %s\n' "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}"
    return 0
  fi

  # ssh
  if [[ "$url" =~ ^git@github\.com:([^/]+)/([^/]+)$ ]]; then
    printf '%s %s\n' "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}"
    return 0
  fi

  return 1
}

# ============= SELF-HEAL (local) =============
self_heal_local_briefing() {
  # Detect whether this script differs from HEAD and recommend restore.
  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    log "INFO" "SELF-HEAL: not a git repo; local heal unavailable."
    return
  fi

  local diff
  diff="$(git diff --name-only -- "$SELF_PATH" 2>/dev/null || true)"
  if [[ -n "$diff" ]]; then
    log "WARN" "SELF-HEAL: $SELF_PATH is modified vs. HEAD."
    printf '%s\n' "RECOMMENDED (secure): restore $SELF_PATH from local repo state (no network)."
  else
    log "INFO" "SELF-HEAL: $SELF_PATH matches HEAD."
  fi
}

self_heal_local_apply() {
  local diff
  diff="$(git diff --name-only -- "$SELF_PATH" 2>/dev/null || true)"
  [[ -n "$diff" ]] || { printf '%s\n' "No local heal needed."; return; }

  confirm_or_die "Restore $SELF_PATH from local repo (git checkout -- $SELF_PATH)? This will discard local edits to that file."
  git checkout -- "$SELF_PATH"
  printf '%s\n' "SELF-HEAL: restored $SELF_PATH from HEAD."
}

# ============= SELF-UPDATE (virtual, GitHub) =============
github_latest_release_tag() {
  # Prints tag_name if possible.
  local owner="$1" repo="$2"
  need_cmd curl
  need_cmd python3

  curl -fsSL \
    -H "Accept: application/vnd.github+json" \
    "https://api.github.com/repos/${owner}/${repo}/releases/latest" \
  | python3 -c 'import json,sys; print(json.load(sys.stdin).get("tag_name",""))'
}

download_raw_script() {
  # Downloads raw script for owner/repo/ref/path and prints temp filepath.
  local owner="$1" repo="$2" ref="$3" path="$4"
  need_cmd curl

  local url="https://raw.githubusercontent.com/${owner}/${repo}/${ref}/${path}"
  local tmp
  tmp="$(mktemp)"
  curl -fsSL "$url" -o "$tmp"
  printf '%s\n' "$tmp"
}

sanity_check_script() {
  local file="$1"
  # Minimal sanity checks to prevent replacing with HTML/404/etc.
  head -n 1 "$file" | grep -q '^#!/' || return 1
  grep -q 'readonly APP=' "$file" || return 1
  return 0
}

self_update_virtual_briefing() {
  if ! parse_github_origin >/dev/null 2>&1; then
    printf '%s\n' "SELF-UPDATE: origin is not a parseable github.com remote; skipping virtual update check."
    printf '%s\n' "RECOMMENDED: set origin to GitHub or use repo update via your normal remote."
    return
  fi

  local owner repo
  read -r owner repo < <(parse_github_origin)

  printf '%s\n' "SELF-UPDATE: GitHub repo detected: ${owner}/${repo}"
  printf '%s\n' "SELF-UPDATE: checking latest '${SELF_UPDATE_REF_MODE}' requires network."

  if ! confirm_yes "Allow network now to check GitHub for the latest script version?"; then
    printf '%s\n' "SELF-UPDATE: skipped (network not approved)."
    printf '%s\n' "RECOMMENDED: approve network next run to get secure update guidance."
    return
  fi

  if [[ "$SELF_UPDATE_REF_MODE" == "release" ]]; then
    local tag
    tag="$(github_latest_release_tag "$owner" "$repo")"
    if [[ -z "$tag" ]]; then
      printf '%s\n' "SELF-UPDATE: no latest release tag found (or API limited)."
      printf '%s\n' "RECOMMENDED: publish GitHub Releases and tag them; then rerun update check."
      return
    fi
    printf '%s\n' "SELF-UPDATE: latest_release_tag=${tag}"
    printf '%s\n' "RECOMMENDED (secure): update to latest release by syncing the repo (preferred) or script-only update (acceptable)."
  else
    printf '%s\n' "SELF-UPDATE: branch mode enabled: ref=${SELF_BRANCH_REF}"
    printf '%s\n' "RECOMMENDED (secure): prefer releases/tags for deterministic updates."
  fi
}

self_update_virtual_apply() {
  parse_github_origin >/dev/null 2>&1 || die "Cannot self-update: origin is not github.com (or unparseable)."

  local owner repo ref
  read -r owner repo < <(parse_github_origin)

  confirm_or_die "Authorize virtual self-update: download latest $SELF_PATH from GitHub and replace the local script?"
  confirm_or_die "Allow network for the download?"

  if [[ "$SELF_UPDATE_REF_MODE" == "release" ]]; then
    ref="$(github_latest_release_tag "$owner" "$repo")"
    [[ -n "$ref" ]] || die "No latest release tag found; cannot update."
  else
    ref="$SELF_BRANCH_REF"
  fi

  local tmp
  tmp="$(download_raw_script "$owner" "$repo" "$ref" "$SELF_PATH")"
  sanity_check_script "$tmp" || die "Downloaded file failed sanity checks; refusing to replace local script."

  # Backup + atomic replace
  local bak
  bak="${SELF_PATH}.bak.$(date -u +%Y%m%dT%H%M%SZ)"
  cp -f "$SELF_PATH" "$bak" 2>/dev/null || true

  mv -f "$tmp" "$SELF_PATH"
  chmod 600 "$SELF_PATH" 2>/dev/null || true

  printf '%s\n' "SELF-UPDATE: replaced $SELF_PATH from ref=${ref} (backup: $bak)."

  if confirm_yes "Relaunch updated script now? (exec bash ./$SELF_PATH)"; then
    exec bash "./$SELF_PATH"
  else
    printf '%s\n' "SELF-UPDATE: not relaunched. Re-run: bash ./$SELF_PATH"
  fi
}

# ============= REPO UPDATE (preferred coherent update) =============
repo_update_ff_only() {
  confirm_or_die "Update repo now (git fetch --all --prune; git pull --ff-only)?"
  confirm_or_die "Allow network for git update?"
  require_clean_spine
  git fetch --all --prune
  git pull --ff-only
  printf '%s\n' "REPO: update complete (ff-only)."
}

# ============= uv in venv-style (.venv + activate) =============
env_sync_uv_venvstyle() {
  need_cmd python3

  confirm_or_die "Use uv for performance, but keep venv-style .venv (create if missing, then sync requirements)?"
  confirm_or_die "Allow network for dependency resolution/downloads?"

  need_cmd uv

  # Create standard venv at .venv (PEP 405 style)
  uv venv .venv

  # "Typed in venv way": activate, then operate inside.
  # uv will also find .venv automatically, but we keep it explicit and familiar.
  # shellcheck disable=SC1091
  source .venv/bin/activate

  if [[ -f requirements.txt ]]; then
    confirm_or_die "Sync .venv to match requirements.txt exactly using uv (recommended)?"
    uv pip sync requirements.txt
  else
    die "requirements.txt missing. Provide one (or switch to pyproject-based workflow)."
  fi

  deactivate || true
  printf '%s\n' "ENV: .venv created/refreshed using uv; requirements synchronized."
}

# ============= entrypoint =============
run_app() {
  confirm_or_die "Run application now?"
  require_clean_spine

  if [[ -x "./bin/glassbox" ]]; then
    confirm_or_die "Run ./bin/glassbox under net-off wrapper (best-effort)?"
    with_net_off ./bin/glassbox
    return
  fi

  die "No runnable entrypoint found: expected ./bin/glassbox"
}

# ============= Update briefing (every run) =============
update_briefing_every_run() {
  printf '\n%s\n' "================ UPDATE BRIEFING (every run) ================"
  self_heal_local_briefing
  self_update_virtual_briefing
  printf '%s\n' "RECOMMENDED SECURE COURSE:"
  printf '%s\n' "  1) If local script is modified: use Self-Heal (local restore)."
  printf '%s\n' "  2) Prefer Repo Update (ff-only) for coherent updates."
  printf '%s\n' "  3) Use Virtual Self-Update only when you explicitly want script-only refresh."
  printf '%s\n' "============================================================="
}

menu() {
  while :; do
    printf '\n%s\n' "=== ${APP} // ONECLICK MENU v${VERSION} ==="
    printf '%s\n' "0) View status"
    printf '%s\n' "1) Self-Heal locally (restore oneclick.sh from HEAD)"
    printf '%s\n' "2) Repo update (ff-only)"
    printf '%s\n' "3) Virtual self-update (download oneclick.sh from GitHub latest)"
    printf '%s\n' "4) Env sync: uv + venv-style (.venv activate + uv pip sync)"
    printf '%s\n' "5) Run app"
    printf '%s\n' "6) Quit"
    printf '%s'   "Select [0-6]: "

    local choice
    IFS= read -r choice || true
    case "$choice" in
      0)
        printf '%s\n' "Repo: $(pwd)"
        printf '%s\n' "Log:  $LOG_FILE"
        printf '%s\n' "RCA:  $RCA_DIR/rca_*.txt"
        ;;
      1) self_heal_local_apply ;;
      2) repo_update_ff_only ;;
      3) self_update_virtual_apply ;;
      4) env_sync_uv_venvstyle ;;
      5) run_app ;;
      6) exit 0 ;;
      *) printf '%s\n' "Invalid selection." ;;
    esac
  done
}

main() {
  ensure_dirs
  acquire_lock
  require_repo_root
  need_cmd git

  printf '%s\n' "APP=${APP} VERSION=${VERSION} REPO_ROOT=$(pwd)"
  confirm_or_die "Acknowledge: no action runs without typed YES, including self-update/network changes."

  update_briefing_every_run
  menu
}

main "$@"
