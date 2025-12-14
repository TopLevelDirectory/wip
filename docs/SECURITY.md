# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 3.x.x   | :white_check_mark: |
| < 3.0   | :x:                |

## Security Model

### Core Principles

1. **Fail-closed**: If a decision gate cannot be evaluated safely, the default is "no action"
2. **Operator sovereignty**: Anything consequential requires **typed `YES`**
3. **No silent writes**: Every write/install/network step requires explicit approval
4. **Deterministic updates**: Every run prints an "Update Briefing" + recommended secure course

### Consequential Actions (require typed YES)

- Network access (fetch, curl, git remote operations)
- File writes/modifications
- Package installations
- Script updates (self-heal or self-update)
- Environment modifications
- Application execution

### Non-consequential Actions (Enter to continue)

- Status screens
- Help displays
- Preview/dry-run outputs
- Menu navigation

## Update Security

### Recommended Update Paths (in order of security)

1. **Repo Update (ff-only)**: `git fetch && git pull --ff-only`
   - Most secure: maintains full repo integrity
   - Requires clean working tree

2. **Self-Heal (local)**: `git checkout -- oneclick.sh`
   - Restores script from local HEAD
   - No network required

3. **Virtual Self-Update (script-only)**
   - Downloads from GitHub releases
   - Least secure: script-only, no repo context
   - Use only when explicitly needed

### Supply Chain Protections

- GitHub Actions pinned to full commit SHAs
- Release artifacts should be signed (Pro feature)
- Sanity checks before script replacement (shebang + markers)
- Atomic backup + swap for updates

## Reporting a Vulnerability

Please report security vulnerabilities by opening a GitHub issue with the `security` label, or by contacting the maintainers directly.

**Do not** disclose security vulnerabilities publicly until a fix is available.

## Secret Handling

- Never commit secrets to the repository
- RCA dumps automatically redact known secret patterns
- Environment variables containing secrets are not logged
- `.gitignore` excludes sensitive runtime directories
