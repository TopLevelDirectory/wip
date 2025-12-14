# Toolchain Specification

This document is the single source of truth for required tools and their pinned versions.

## Required Tools

### Core Runtime

| Tool | Version | Purpose | Required |
|------|---------|---------|----------|
| Bash | 4.0+ | Script runtime | Yes |
| Git | 2.0+ | Version control, self-heal | Yes |
| Python | 3.8+ | Application runtime | Yes |
| curl | 7.0+ | HTTP client for updates | Yes |

### Python Environment Management

| Tool | Version | Purpose | Required |
|------|---------|---------|----------|
| uv | latest | Fast package management | Recommended |

**uv Usage Pattern (venv-style)**:

```bash
# Create virtual environment
uv venv .venv

# Activate (standard venv notation)
source .venv/bin/activate

# Sync dependencies
uv pip sync requirements.txt

# Or install individual packages
uv pip install <package>
```

Reference: [uv environments documentation](https://docs.astral.sh/uv/pip/environments/)

### Development & CI Tools

| Tool | Version | Purpose | Required |
|------|---------|---------|----------|
| ShellCheck | 0.11.0 | Bash static analysis | Dev/CI |
| shfmt | 3.12.0 | Bash formatting | Dev/CI |
| bats-core | 1.13.0 | Bash testing framework | Dev/CI |

### Optional (Pro Features)

| Tool | Version | Purpose | Required |
|------|---------|---------|----------|
| gum | 0.17.0 | Terminal UI components | Pro only |

## Installation Instructions

### Linux (Debian/Ubuntu)

```bash
# Core tools
sudo apt update
sudo apt install -y bash git python3 curl

# uv (recommended)
curl -LsSf https://astral.sh/uv/install.sh | sh

# Development tools
# ShellCheck
sudo apt install -y shellcheck

# shfmt (download binary)
curl -sS https://webinstall.dev/shfmt | bash

# bats-core
git clone https://github.com/bats-core/bats-core.git /tmp/bats
sudo /tmp/bats/install.sh /usr/local

# gum (optional, for Pro)
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://repo.charm.sh/apt/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/charm.gpg
echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | sudo tee /etc/apt/sources.list.d/charm.list
sudo apt update && sudo apt install gum
```

### Linux (Fedora/RHEL)

```bash
# Core tools
sudo dnf install -y bash git python3 curl

# uv (recommended)
curl -LsSf https://astral.sh/uv/install.sh | sh

# Development tools
sudo dnf install -y ShellCheck

# shfmt
curl -sS https://webinstall.dev/shfmt | bash

# bats-core
git clone https://github.com/bats-core/bats-core.git /tmp/bats
sudo /tmp/bats/install.sh /usr/local

# gum (optional)
echo '[charm]
name=Charm
baseurl=https://repo.charm.sh/yum/
enabled=1
gpgcheck=1
gpgkey=https://repo.charm.sh/yum/gpg.key' | sudo tee /etc/yum.repos.d/charm.repo
sudo dnf install gum
```

### macOS

```bash
# Using Homebrew
brew install bash git python3 curl

# uv
curl -LsSf https://astral.sh/uv/install.sh | sh

# Development tools
brew install shellcheck shfmt bats-core

# gum (optional)
brew install gum
```

### Docker (for CI)

```dockerfile
FROM ubuntu:22.04

RUN apt-get update && apt-get install -y \
    bash \
    git \
    python3 \
    curl \
    shellcheck \
    && rm -rf /var/lib/apt/lists/*

# Install uv
RUN curl -LsSf https://astral.sh/uv/install.sh | sh

# Install shfmt
RUN curl -sS https://webinstall.dev/shfmt | bash

# Install bats-core
RUN git clone https://github.com/bats-core/bats-core.git /tmp/bats \
    && /tmp/bats/install.sh /usr/local \
    && rm -rf /tmp/bats
```

## Version Verification

```bash
# Check installed versions
bash --version | head -1
git --version
python3 --version
curl --version | head -1
uv --version
shellcheck --version | head -1
shfmt --version
bats --version
gum --version 2>/dev/null || echo "gum not installed (optional)"
```

## CI Version Enforcement

The CI pipeline validates that tools match these pinned versions. See `.github/workflows/ci.yml` for enforcement logic.

## Upgrade Policy

Tool versions should be updated:
- Quarterly for minor versions
- Immediately for security patches
- After thorough testing for major versions

When upgrading, update this document first, then update CI configuration.

## References

- [uv documentation](https://docs.astral.sh/uv/)
- [ShellCheck releases](https://github.com/koalaman/shellcheck/releases)
- [shfmt releases](https://github.com/mvdan/sh/releases)
- [bats-core releases](https://github.com/bats-core/bats-core/releases)
- [gum releases](https://github.com/charmbracelet/gum/releases)
