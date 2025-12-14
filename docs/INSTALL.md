# Installation Guide

## Quick Start

```bash
git clone <repo-url>
cd <repo>
bash ./oneclick.sh
```

That's it. The script will guide you through everything else.

## Prerequisites

### Required

- **Bash** 4.0+ (comes with most Linux/macOS systems)
- **Git** 2.0+ (for repo operations and self-heal)
- **Python** 3.8+ (for application runtime)

### Recommended

- **uv** (fast Python package management) - will be installed if missing
- **curl** (for GitHub API and downloads)

### Optional (Pro features)

- **gum** 0.17.0+ (for exquisite terminal UI)

## Platform-Specific Notes

### Linux (Debian/Ubuntu)

```bash
# Install prerequisites
sudo apt update
sudo apt install -y bash git python3 curl

# Install uv (recommended)
curl -LsSf https://astral.sh/uv/install.sh | sh
```

### Linux (Fedora/RHEL)

```bash
# Install prerequisites
sudo dnf install -y bash git python3 curl

# Install uv (recommended)
curl -LsSf https://astral.sh/uv/install.sh | sh
```

### macOS

```bash
# Using Homebrew
brew install git python3 curl

# Install uv (recommended)
curl -LsSf https://astral.sh/uv/install.sh | sh
```

## First Run

On first run, `oneclick.sh` will:

1. Display an acknowledgment prompt (requires typed `YES`)
2. Show an Update Briefing with recommendations
3. Present the main menu

### Menu Options

| Option | Action | Requires YES |
|--------|--------|--------------|
| 0 | View status | No |
| 1 | Self-Heal locally | Yes |
| 2 | Repo update (ff-only) | Yes |
| 3 | Virtual self-update | Yes |
| 4 | Env sync (uv + .venv) | Yes |
| 5 | Run app | Yes |
| 6 | Quit | No |

## Environment Setup

The script manages Python environments using **uv** with familiar venv notation:

```bash
# Created automatically by option 4
.venv/           # Standard Python virtual environment
  bin/
    activate     # Source this to activate
    python
    pip
```

### Manual Activation (if needed)

```bash
source .venv/bin/activate
```

## Troubleshooting

### "Another run is in progress"

The script uses file locking to prevent concurrent runs. If you see this error:

1. Check for other running instances
2. Remove stale lock: `rm -rf .locks/`

### "Dirty working tree"

Some operations require a clean git state:

```bash
git status          # Check what's changed
git stash           # Temporarily save changes
bash ./oneclick.sh  # Run the script
git stash pop       # Restore your changes
```

### "Missing dependency: X"

Install the missing tool using your package manager (see Platform-Specific Notes above).

### RCA Files

On errors, diagnostic information is written to `logs/rca/`. Share these files when reporting issues.
