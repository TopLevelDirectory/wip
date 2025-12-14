# PRD / SPEC.md — OneClick Kernel (Freemium)

**Project codename:** `oneclick`
**Invocation contract:** `bash ./oneclick.sh`
**Argument hint:** `<project-description>`
**$ARGUMENTS (resolved):** A “one-click” DevOps-coded, self-updating, self-healing, safety-gated terminal installer/updater/runner that manages a Python `.venv` using **uv** in familiar venv notation (`.venv`, `source .venv/bin/activate`), checks for updates every run, and always brings consequential decisions to explicit operator attention (typed `YES`) before proceeding. Includes a freemium core and a paid “Pro” unlock that adds exquisite terminal UX, hardened supply-chain verification, and team/enterprise orchestration features—without dark patterns or coercion.

---

## 1. Project Overview

### Title

**OneClick Kernel — a governed terminal “game-console” for install/update/run + environment ops**

### Summary

OneClick Kernel is a single-entry Bash launcher that turns a repo into a “console”: on every run it performs an update briefing, proposes the most secure recommended course of action, and then executes only what the operator explicitly authorizes. It keeps UX “no-brainer” (menus, defaults, safe “Enter to continue” where appropriate) while enforcing a strict *typed `YES`* gate for any consequential action (network, updates, writes, installs, deletions).

### Problem Statement

Developers lose time and safety to ad-hoc bootstrap instructions, stale docs, environment drift, and risky update behaviors. Existing “one-liners” optimize convenience but often violate least privilege, supply-chain hygiene, and operator awareness.

### Solution Overview

A repo-native command (`bash ./oneclick.sh`) that:

* Creates a consistent, game-like terminal interface for operations
* Manages a Python venv at `.venv` using **uv** (performance) but in **venv notation** (familiarity) ([Astral Docs][1])
* Performs **self-heal** (local) and **self-update** (remote) with operator gating
* Recommends secure defaults (e.g., prefer repo `ff-only` update over script-only replacement)
* Offers a freemium baseline plus Pro features that are clearly additive (not punitive)

### Success Criteria (measurable)

* **TTR (time-to-run) < 2 minutes** on a fresh machine: clone → `bash ./oneclick.sh` → guided install → run.
* **>80% automated test coverage** for Bash logic measured by Bats test suite coverage proxy metrics (function-level coverage targets + scenario matrix).
* **0 silent writes**: every write/install/network step requires an explicit `YES`.
* **Supply-chain posture**: CI enforces ShellCheck and pinned GitHub Actions SHAs ([GitHub][2])
* **Upgrade conversion**: Pro attachment rate measured by opt-in trial starts and renewals (no dark patterns).

### Tech Stack (2025 recommendations)

* **Runtime:** Bash (`#!/usr/bin/env bash`)
* **Testing:** `bats-core` (v1.13.0) ([NewReleases][3])
* **Lint:** `ShellCheck` stable `v0.11.0` ([GitHub][2])
* **Format:** `shfmt` `v3.12.0` ([GitHub][4])
* **Python env mgmt:** `uv` (create `.venv`, activate, `uv pip sync`) ([Astral Docs][1])
* **Terminal UX (optional / Pro):** `gum` `v0.17.0` for exquisite, game-like prompts ([GitHub][5])
* **Remote update metadata:** GitHub REST API “latest release” endpoint ([GitHub Docs][6])
* **CI/CD:** GitHub Actions with pinned action SHAs ([GitHub Docs][7])

---

## 2. Architecture & Setup Phase (MUST BE FIRST TASKS)

### Core architectural invariants

1. **Fail-closed**: if a decision gate cannot be evaluated safely, the default is “no action.”
2. **Operator sovereignty**: anything consequential requires **typed `YES`**.
3. **Safe UX**: “Enter” may advance only through *non-consequential* screens (status, help, previews).
4. **Deterministic update guidance**: every run prints an “Update Briefing” + recommended secure course.
5. **Freemium separation**: Free tier never degrades; Pro only adds capabilities and polish.

---

## 3. Testing Architecture (CRITICAL — define before features)

### Tools

* **Bats-core** for unit + scenario tests (CLI behavior, file ops, gating logic) ([NewReleases][3])
* **ShellCheck v0.11.0** for static analysis ([GitHub][2])
* **shfmt v3.12.0** for formatting ([GitHub][4])
* **Integration tests:** Docker-based matrix (Ubuntu + Fedora + minimal images), plus “network denied” and “dirty git tree” cases.

### Test directory structure

```
/tests
  /unit
    gate.test.bats
    git_ops.test.bats
    update_briefing.test.bats
    uv_env.test.bats
    pro_unlock.test.bats
  /integration
    docker_matrix.test.bats
    github_update_mock.test.bats
/tests/helpers
  fixtures.bash
  fakebin/
    git
    curl
    uv
```

### Naming conventions

* `*.test.bats` per feature area
* Each test name includes scenario + expected outcome, e.g.

  * `@test "gate: declines when input != YES"`
  * `@test "update: recommends ff-only repo update over script-only"`

### Mock/stub strategy

* Prefer **fakebin** stubs (PATH injection) for `git`, `curl`, `uv`, `unshare`
* Use recorded fixtures for GitHub API responses (`releases/latest`) ([GitHub Docs][6])
* Never hit network in tests; all network behavior is simulated.

### Coverage requirements

* > 80% scenario coverage across decision gates and update flows
* 100% coverage for any code path that can mutate filesystem/network.

### Integration boundaries

* Unit tests validate pure functions and command wrappers
* Integration tests validate end-to-end flows: clone → run → menu → env sync → run app.

---

## 4. Feature Tasks

### Architecture & Setup Tasks

#### Task 1: Repo Scaffolding & Directory Structure

**Description**: Establish the canonical project structure for the Bash runtime, tests, CI, docs, and Pro module boundary.

**Acceptance Criteria**:

* [ ] `oneclick.sh` lives at repo root
* [ ] `/tests` structure exists as defined
* [ ] `.gitignore` includes runtime dirs (`logs/`, `.locks/`, `out/`, `.venv/`)
* [ ] `docs/` includes `SECURITY.md`, `INSTALL.md`, `PRO.md`

**Test Requirements**:

* [ ] Unit tests written BEFORE implementation (structure assertions)
* [ ] Edge cases covered: missing dirs, read-only filesystem
* [ ] Integration tests for: clean clone layout validation

```json
{
  "task_id": "TASK-1",
  "name": "Repo Scaffolding & Directory Structure",
  "status": "pending",
  "tests_status": "not_written",
  "unit_tests_passing": false,
  "integration_tests_passing": false,
  "dependencies": [],
  "estimated_complexity": "low"
}
```

---

#### Task 2: Tooling Pin Document (Versions & Install Guidance)

**Description**: Create a single source-of-truth document listing required tools and recommended versions for 2025-era stability.

**Acceptance Criteria**:

* [ ] `docs/TOOLCHAIN.md` specifies:

  * [ ] `uv` usage for `.venv` (create/activate/sync) ([Astral Docs][1])
  * [ ] ShellCheck `v0.11.0` ([GitHub][2])
  * [ ] shfmt `v3.12.0` ([GitHub][4])
  * [ ] (Optional) gum `v0.17.0` for Pro UI ([GitHub][5])
* [ ] Includes platform install examples (Linux/macOS; package-manager + curl install options)

**Test Requirements**:

* [ ] Unit tests written BEFORE implementation (doc existence checks)
* [ ] Edge cases covered: doc missing, mismatch between CI versions and doc
* [ ] Integration tests for: CI validates version strings

```json
{
  "task_id": "TASK-2",
  "name": "Tooling Pin Document (Versions & Install Guidance)",
  "status": "pending",
  "tests_status": "not_written",
  "unit_tests_passing": false,
  "integration_tests_passing": false,
  "dependencies": ["TASK-1"],
  "estimated_complexity": "medium"
}
```

---

#### Task 3: Testing Infrastructure Setup (Bats + Helpers)

**Description**: Install and configure bats-core test runner, helper library patterns, and fakebin stubs.

**Acceptance Criteria**:

* [ ] `tests/helpers/fixtures.bash` provides temp dirs + PATH injection
* [ ] `make test` (or `./dev/test.sh`) runs unit tests locally
* [ ] Tests do not require network access

**Test Requirements**:

* [ ] Unit tests written BEFORE implementation (test harness self-tests)
* [ ] Edge cases covered: missing bats, missing bash features
* [ ] Integration tests for: dockerized test execution

```json
{
  "task_id": "TASK-3",
  "name": "Testing Infrastructure Setup (Bats + Helpers)",
  "status": "pending",
  "tests_status": "not_written",
  "unit_tests_passing": false,
  "integration_tests_passing": false,
  "dependencies": ["TASK-1"],
  "estimated_complexity": "medium"
}
```

---

#### Task 4: CI Pipeline (Lint + Test + Format)

**Description**: Add GitHub Actions workflow that runs ShellCheck, shfmt check, and Bats tests on pushes/PRs.

**Acceptance Criteria**:

* [ ] Workflow uses least privilege permissions
* [ ] Third-party actions pinned to full commit SHAs ([GitHub Docs][7])
* [ ] Fails build on ShellCheck or test failures

**Test Requirements**:

* [ ] Unit tests written BEFORE implementation (workflow file assertions)
* [ ] Edge cases covered: bash strict mode compatibility
* [ ] Integration tests for: CI run on PR with intentionally broken script

```json
{
  "task_id": "TASK-4",
  "name": "CI Pipeline (Lint + Test + Format)",
  "status": "pending",
  "tests_status": "not_written",
  "unit_tests_passing": false,
  "integration_tests_passing": false,
  "dependencies": ["TASK-2", "TASK-3"],
  "estimated_complexity": "medium"
}
```

---

### Core Runtime (Freemium) Tasks

#### Task 5: Decision Gate Engine (Typed YES for Consequential Actions)

**Description**: Implement a single gating primitive: typed `YES` is required for any step marked consequential.

**Acceptance Criteria**:

* [ ] Gate function supports:

  * [ ] `YES` required for network/install/write/delete/update
  * [ ] “Enter continues” only for read-only screens
* [ ] Default is deny if input not exactly `YES`

**Test Requirements**:

* [ ] Unit tests written BEFORE implementation
* [ ] Edge cases covered: EOF input, whitespace, lowercase, non-tty execution
* [ ] Integration tests for: scripted non-interactive run fails closed

```json
{
  "task_id": "TASK-5",
  "name": "Decision Gate Engine (Typed YES)",
  "status": "pending",
  "tests_status": "not_written",
  "unit_tests_passing": false,
  "integration_tests_passing": false,
  "dependencies": ["TASK-3"],
  "estimated_complexity": "medium"
}
```

---

#### Task 6: Update Briefing (Every Run) + Secure Recommendations

**Description**: On every invocation, print a structured “Update Briefing” that recommends the most secure next steps and explains tradeoffs.

**Acceptance Criteria**:

* [ ] Shows:

  * [ ] local self-heal status (script modified vs HEAD)
  * [ ] repo update recommendation (`git pull --ff-only`)
  * [ ] optional script-only update path (explicitly riskier)
* [ ] Never performs update actions without `YES`

**Test Requirements**:

* [ ] Unit tests written BEFORE implementation
* [ ] Edge cases covered: not a git repo, origin missing
* [ ] Integration tests for: dirty tree → refusal + guidance

```json
{
  "task_id": "TASK-6",
  "name": "Update Briefing (Every Run) + Secure Recommendations",
  "status": "pending",
  "tests_status": "not_written",
  "unit_tests_passing": false,
  "integration_tests_passing": false,
  "dependencies": ["TASK-5"],
  "estimated_complexity": "medium"
}
```

---

#### Task 7: Self-Heal Locally (No Network)

**Description**: If `oneclick.sh` differs from the checked-in repo state, propose restoring from HEAD.

**Acceptance Criteria**:

* [ ] Detects file modification via git diff
* [ ] Requires `YES` to restore (`git checkout -- oneclick.sh`)
* [ ] Never runs outside a git worktree

**Test Requirements**:

* [ ] Unit tests written BEFORE implementation
* [ ] Edge cases covered: untracked script, detached HEAD
* [ ] Integration tests for: modification → restore → verified clean

```json
{
  "task_id": "TASK-7",
  "name": "Self-Heal Locally (No Network)",
  "status": "pending",
  "tests_status": "not_written",
  "unit_tests_passing": false,
  "integration_tests_passing": false,
  "dependencies": ["TASK-6"],
  "estimated_complexity": "medium"
}
```

---

#### Task 8: Repo Update (Preferred) — Fetch + Pull ff-only

**Description**: Implement coherent repo update flow gated by `YES` and network authorization.

**Acceptance Criteria**:

* [ ] Requires clean working tree before update
* [ ] Runs `git fetch --all --prune` then `git pull --ff-only`
* [ ] Prints outcome and next recommended action

**Test Requirements**:

* [ ] Unit tests written BEFORE implementation
* [ ] Edge cases covered: merge required (non-ff), shallow clone
* [ ] Integration tests for: update success and expected refusal

```json
{
  "task_id": "TASK-8",
  "name": "Repo Update (Preferred) — Fetch + Pull ff-only",
  "status": "pending",
  "tests_status": "not_written",
  "unit_tests_passing": false,
  "integration_tests_passing": false,
  "dependencies": ["TASK-6"],
  "estimated_complexity": "medium"
}
```

---

#### Task 9: Virtual Self-Update (Script-only) via GitHub “Latest Release”

**Description**: Provide an optional script-only update mechanism that checks GitHub latest release metadata and can replace the local script atomically.

**Acceptance Criteria**:

* [ ] Uses GitHub REST API “latest release” endpoint ([GitHub Docs][6])
* [ ] Requires `YES` for:

  * [ ] enabling network
  * [ ] downloading replacement
  * [ ] replacing file
* [ ] Refuses replacement unless file passes sanity checks (shebang + marker)
* [ ] Creates backup and performs atomic swap

**Test Requirements**:

* [ ] Unit tests written BEFORE implementation (mock API responses)
* [ ] Edge cases covered: API rate limit, missing release, HTML error download
* [ ] Integration tests for: mocked latest tag → replacement success

```json
{
  "task_id": "TASK-9",
  "name": "Virtual Self-Update (Script-only) via GitHub Latest Release",
  "status": "pending",
  "tests_status": "not_written",
  "unit_tests_passing": false,
  "integration_tests_passing": false,
  "dependencies": ["TASK-6", "TASK-5"],
  "estimated_complexity": "high"
}
```

---

#### Task 10: uv “venv way” Environment Sync (.venv + activate + uv pip sync)

**Description**: Implement environment bootstrap using `uv` for performance while keeping the UX in standard venv notation (`.venv`, `source .venv/bin/activate`). uv supports creating and discovering `.venv` and uses venvs by default ([Astral Docs][1]).

**Acceptance Criteria**:

* [ ] Creates `.venv` via `uv venv` ([Astral Docs][1])
* [ ] Activates `.venv` with `source .venv/bin/activate` ([Astral Docs][1])
* [ ] If `requirements.txt` exists, offers `uv pip sync requirements.txt`
* [ ] If missing, provides clear guidance (optionally supports `pyproject.toml` in later task)

**Test Requirements**:

* [ ] Unit tests written BEFORE implementation (fake uv binary)
* [ ] Edge cases covered: uv missing, python missing, permissions
* [ ] Integration tests for: happy path in container

```json
{
  "task_id": "TASK-10",
  "name": "uv venv-style Environment Sync",
  "status": "pending",
  "tests_status": "not_written",
  "unit_tests_passing": false,
  "integration_tests_passing": false,
  "dependencies": ["TASK-5", "TASK-6"],
  "estimated_complexity": "high"
}
```

---

#### Task 11: RCA Crash Report (Actionable Failure Dump)

**Description**: On any error, write an RCA artifact capturing the last command, environment, git status, and relevant logs.

**Acceptance Criteria**:

* [ ] `trap ERR` writes RCA file under `logs/rca/`
* [ ] Includes: timestamp, exit code, last command, git status, log tail
* [ ] Never leaks secrets (redaction rules in spec)

**Test Requirements**:

* [ ] Unit tests written BEFORE implementation
* [ ] Edge cases covered: log dir missing, trap recursion
* [ ] Integration tests for: forced failure creates RCA file

```json
{
  "task_id": "TASK-11",
  "name": "RCA Crash Report (Actionable Failure Dump)",
  "status": "pending",
  "tests_status": "not_written",
  "unit_tests_passing": false,
  "integration_tests_passing": false,
  "dependencies": ["TASK-5"],
  "estimated_complexity": "medium"
}
```

---

#### Task 12: Game-Console Menu (Freemium Baseline)

**Description**: Implement the “console” interface: numeric menu, status screens, previews; actions remain gated by typed `YES`.

**Acceptance Criteria**:

* [ ] Menu offers: status, self-heal, repo update, env sync, run app
* [ ] Status screens advance with Enter
* [ ] Any mutating action requires `YES`

**Test Requirements**:

* [ ] Unit tests written BEFORE implementation
* [ ] Edge cases covered: invalid input loops safely, EOF
* [ ] Integration tests for: scripted menu navigation

```json
{
  "task_id": "TASK-12",
  "name": "Game-Console Menu (Freemium Baseline)",
  "status": "pending",
  "tests_status": "not_written",
  "unit_tests_passing": false,
  "integration_tests_passing": false,
  "dependencies": ["TASK-5", "TASK-6", "TASK-10"],
  "estimated_complexity": "high"
}
```

---

### Freemium → Pro Productization Tasks (Ethical, non-coercive)

#### Task 13: Freemium/Pro Boundary & Feature Flag System

**Description**: Define and implement a clean boundary where Pro features are optional modules that can be enabled only when a valid license is present—without degrading the free tier.

**Acceptance Criteria**:

* [ ] Feature flags exist (e.g., `PRO_ENABLED=false`)
* [ ] Pro modules load only if:

  * [ ] license file is present and valid
  * [ ] operator explicitly enables Pro mode
* [ ] Free tier retains full baseline functionality

**Test Requirements**:

* [ ] Unit tests written BEFORE implementation
* [ ] Edge cases covered: tampered license file, missing module files
* [ ] Integration tests for: free run vs pro run behaviors

```json
{
  "task_id": "TASK-13",
  "name": "Freemium/Pro Boundary & Feature Flag System",
  "status": "pending",
  "tests_status": "not_written",
  "unit_tests_passing": false,
  "integration_tests_passing": false,
  "dependencies": ["TASK-12"],
  "estimated_complexity": "high"
}
```

---

#### Task 14: Pro Unlock UX (Clear Value, No Dark Patterns)

**Description**: Add an upgrade screen that explains Pro benefits, offers a trial, and provides a copy/paste activation path—without manipulative timers, forced friction, or punitive limits.

**Acceptance Criteria**:

* [ ] Upgrade screen is discoverable but not spammy (e.g., menu option + subtle banner)
* [ ] Trial and purchase are opt-in and reversible
* [ ] Pro benefits are concrete and operationally meaningful (see list below)

**Test Requirements**:

* [ ] Unit tests written BEFORE implementation
* [ ] Edge cases covered: offline mode, user declines repeatedly
* [ ] Integration tests for: upgrade screen renders and exits safely

```json
{
  "task_id": "TASK-14",
  "name": "Pro Unlock UX (Clear Value, No Dark Patterns)",
  "status": "pending",
  "tests_status": "not_written",
  "unit_tests_passing": false,
  "integration_tests_passing": false,
  "dependencies": ["TASK-13"],
  "estimated_complexity": "medium"
}
```

---

#### Task 15: Pro Feature — Exquisite Terminal UI (gum-powered)

**Description**: Replace baseline prompts with an “exquisite” console experience when `gum` is available and Pro is enabled (animated confirmations, rich menus, progress, safe previews). gum v0.17.0 is the pinned target ([GitHub][5]).

**Acceptance Criteria**:

* [ ] If Pro enabled and gum installed:

  * [ ] menus use gum UI
  * [ ] confirmations still require typed `YES` for consequential actions
* [ ] If gum missing: fall back gracefully

**Test Requirements**:

* [ ] Unit tests written BEFORE implementation (fake gum)
* [ ] Edge cases covered: gum present but failing, non-tty session
* [ ] Integration tests for: both fallback and pro UI branches

```json
{
  "task_id": "TASK-15",
  "name": "Pro Feature — Exquisite Terminal UI (gum-powered)",
  "status": "pending",
  "tests_status": "not_written",
  "unit_tests_passing": false,
  "integration_tests_passing": false,
  "dependencies": ["TASK-13", "TASK-12"],
  "estimated_complexity": "high"
}
```

---

#### Task 16: Pro Feature — Hardened Supply-Chain Updates (Signature/Attestation)

**Description**: Add signature verification for release artifacts and provide higher-assurance update paths (signed tags/releases, verified downloads). CI and docs also enforce supply-chain hygiene including pinned actions SHAs ([GitHub Docs][7]).

**Acceptance Criteria**:

* [ ] Pro update flow verifies authenticity before replacing script/binaries
* [ ] If verification cannot be performed, it refuses or downgrades to “inform-only” mode
* [ ] Documentation clearly distinguishes:

  * [ ] repo update (preferred)
  * [ ] script-only update (riskier)
  * [ ] verified update (Pro)

**Test Requirements**:

* [ ] Unit tests written BEFORE implementation (fixture signatures)
* [ ] Edge cases covered: missing signature, mismatch, replay
* [ ] Integration tests for: verified update succeeds; unverified refuses

```json
{
  "task_id": "TASK-16",
  "name": "Pro Feature — Hardened Supply-Chain Updates",
  "status": "pending",
  "tests_status": "not_written",
  "unit_tests_passing": false,
  "integration_tests_passing": false,
  "dependencies": ["TASK-9", "TASK-4"],
  "estimated_complexity": "high"
}
```

---

#### Task 17: Pro Feature — Multi-Repo Orchestration (“Console Hub”)

**Description**: Let OneClick manage multiple repos as “cartridges”: update, env sync, and run each with identical governance gates.

**Acceptance Criteria**:

* [ ] `cartridges.yaml` defines repos and commands
* [ ] Console lists cartridges and supports batch operations
* [ ] Each cartridge action is individually gated by `YES`

**Test Requirements**:

* [ ] Unit tests written BEFORE implementation
* [ ] Edge cases covered: missing repo dir, partial failures, rollbacks
* [ ] Integration tests for: two cartridges, one fails, RCA generated

```json
{
  "task_id": "TASK-17",
  "name": "Pro Feature — Multi-Repo Orchestration",
  "status": "pending",
  "tests_status": "not_written",
  "unit_tests_passing": false,
  "integration_tests_passing": false,
  "dependencies": ["TASK-13", "TASK-11", "TASK-12"],
  "estimated_complexity": "high"
}
```

---

### “Killer App” Extensions (Roadmap)

#### Task 18: Plugin API (Safe, Declarative Ops Modules)

**Description**: Introduce a constrained plugin interface (declarative commands + typed args) to avoid arbitrary command execution while still enabling extensibility.

**Acceptance Criteria**:

* [ ] Plugin manifest schema exists
* [ ] Only whitelisted functions can run
* [ ] Plugins cannot bypass gating

**Test Requirements**:

* [ ] Unit tests written BEFORE implementation
* [ ] Edge cases covered: malicious plugin manifest, path traversal
* [ ] Integration tests for: plugin install and invocation

```json
{
  "task_id": "TASK-18",
  "name": "Plugin API (Safe, Declarative Ops Modules)",
  "status": "pending",
  "tests_status": "not_written",
  "unit_tests_passing": false,
  "integration_tests_passing": false,
  "dependencies": ["TASK-12"],
  "estimated_complexity": "high"
}
```

---

#### Task 19: Onboarding “Quest Mode” (Guided First Run)

**Description**: Provide a narrative onboarding that feels like an early terminal game: first-run checklist, progress, “you are here” map—without weakening security gates.

**Acceptance Criteria**:

* [ ] First run triggers “Quest Mode”
* [ ] Progress saved locally (non-sensitive)
* [ ] Operator can skip at any time

**Test Requirements**:

* [ ] Unit tests written BEFORE implementation
* [ ] Edge cases covered: corrupted state file, non-tty
* [ ] Integration tests for: quest completion on clean machine

```json
{
  "task_id": "TASK-19",
  "name": "Onboarding Quest Mode (Guided First Run)",
  "status": "pending",
  "tests_status": "not_written",
  "unit_tests_passing": false,
  "integration_tests_passing": false,
  "dependencies": ["TASK-12"],
  "estimated_complexity": "high"
}
```

---

#### Task 20: Security Policy Pack (Operator-Attested Risk Profiles)

**Description**: Add selectable security profiles (e.g., “Offline”, “Repo-only updates”, “Verified-only updates”) that change what the script recommends and permits—never silently.

**Acceptance Criteria**:

* [ ] Profiles are explicit, human-readable, and versioned
* [ ] Switching profiles requires `YES` and prints diffs
* [ ] Offline profile forbids network even if user tries

**Test Requirements**:

* [ ] Unit tests written BEFORE implementation
* [ ] Edge cases covered: conflicting flags, downgrade attacks
* [ ] Integration tests for: offline profile blocks network paths

```json
{
  "task_id": "TASK-20",
  "name": "Security Policy Pack (Operator-Attested Risk Profiles)",
  "status": "pending",
  "tests_status": "not_written",
  "unit_tests_passing": false,
  "integration_tests_passing": false,
  "dependencies": ["TASK-5", "TASK-6"],
  "estimated_complexity": "high"
}
```

---

## Pro Feature Catalog (what users pay for — “exquisite” but legitimate)

* **Exquisite TUI:** gum-powered UI/animations, better previews, richer progress ([GitHub][5])
* **Verified Updates:** signed/attested release verification + safer auto-sync lanes
* **Multi-repo hub:** cartridge orchestration + batch ops
* **Team mode:** shared policy packs, guardrails, CODEOWNERS alignment, CI templates (leveraging GitHub Actions security guidance) ([GitHub Docs][7])
* **Enterprise:** SBOM export, audit logs, reproducible build metadata, SSO-friendly license distribution

---

## 5. Instructions for AI Coding Agent

## Instructions for AI Coding Agent

### Development Methodology

You MUST follow **Test-Driven Development (TDD)** and **Spec-Driven Development (SDD)**:

1. **Read the spec first** - Understand the full requirement before writing code
2. **Write tests first** - Create failing tests that define expected behavior
3. **Implement minimally** - Write only enough code to pass tests
4. **Refactor** - Clean up while keeping tests green
5. **Update this document** - Mark checkboxes and update JSON blocks

### Web Search & Documentation Protocol

* Use web search to find current documentation for packages
* Use Context7 MCP (if available) to get library-specific context
* Always verify API signatures against latest docs
* Search for known issues/bugs before implementing workarounds
* For GitHub API “latest release”, follow official REST docs ([GitHub Docs][6])

### Test Execution Protocol

After completing each task:

1. Run the current task's unit tests
2. Run the previous 2 tasks' unit tests (regression check)
3. Run all integration tests that touch modified code
4. Only mark task complete if ALL tests pass

### Document Update Protocol

When a task is complete:

1. Check off all acceptance criteria boxes
2. Update the JSON block:

   * Set `"status": "completed"`
   * Set `"tests_status": "passing"`
   * Set `"unit_tests_passing": true`
   * Set `"integration_tests_passing": true`
3. Add completion timestamp as comment

### Error Handling Standards

* Never silently swallow errors
* Log with appropriate severity levels
* Provide actionable error messages
* Include error recovery paths where applicable

### Code Quality Standards

* Follow language-specific conventions
* Use meaningful variable/function names
* Keep functions small and focused
* Document complex logic with comments
* No hardcoded values - use configuration

---

## 6. Project State (External Memory)

### Completed Tasks

<!-- Agent: Add completed task IDs here -->

### Current Task

<!-- Agent: Update with current task ID -->

### Blockers & Notes

<!-- Agent: Document any blockers or important discoveries -->

### Test Results Log

<!-- Agent: Log test run results with timestamps -->

---

## 7. Dependency Graph (Task Order)

**Foundational (must happen first):**

* TASK-1 → TASK-2 → TASK-3 → TASK-4

**Core governance runtime:**

* TASK-5 → TASK-6 → (TASK-7, TASK-8, TASK-9, TASK-10, TASK-11) → TASK-12

**Freemium/Pro productization:**

* TASK-12 → TASK-13 → TASK-14 → TASK-15 → TASK-16 → TASK-17

**Roadmap extensions:**

* TASK-12 → TASK-18 / TASK-19
* TASK-6 → TASK-20

---

## Notes on “Freemium that feels inevitable” (without manipulation)

The conversion strategy should be **value-led**: the free tier is genuinely useful, and Pro feels like “I want that polish + assurance,” not “I’m being punished.” Concretely:

* Free: everything needed to install/update/run safely.
* Pro: **exquisite** UX + **verified** supply chain + orchestration.
* Keep the upgrade pitch inside the console, but always skippable and never time-pressured.
* Never degrade baseline performance to force upgrades (no dark patterns).

If you want, I can generate a companion `PRO.md` that precisely enumerates Free vs Pro behaviors and the license verification threat model in spec form.

[1]: https://docs.astral.sh/uv/pip/environments/ "Using environments | uv"
[2]: https://github.com/koalaman/shellcheck/releases "Releases · koalaman/shellcheck · GitHub"
[3]: https://newreleases.io/project/github/bats-core/bats-core/release/v1.13.0?utm_source=chatgpt.com "bats-core/bats-core v1.13.0 on GitHub"
[4]: https://github.com/mvdan/sh/releases "Releases · mvdan/sh · GitHub"
[5]: https://github.com/charmbracelet/gum/releases "Releases · charmbracelet/gum · GitHub"
[6]: https://docs.github.com/rest/releases/releases "REST API endpoints for releases - GitHub Docs"
[7]: https://docs.github.com/en/enterprise-cloud%40latest/actions/reference/security/secure-use "Secure use reference - GitHub Enterprise Cloud Docs"
