# OneClick Pro

## Overview

OneClick Pro extends the free kernel with premium features for teams and enterprises who need:

- **Exquisite UX**: Beautiful terminal interfaces powered by gum
- **Hardened Security**: Verified updates with signature checking
- **Team Orchestration**: Multi-repo management and shared policies

## Free vs Pro Comparison

| Feature | Free | Pro |
|---------|------|-----|
| Decision gates (typed YES) | Yes | Yes |
| Update briefing | Yes | Yes |
| Self-heal (local) | Yes | Yes |
| Repo update (ff-only) | Yes | Yes |
| Virtual self-update | Yes | Yes |
| uv environment sync | Yes | Yes |
| RCA crash reports | Yes | Yes |
| Basic menu interface | Yes | Yes |
| Exquisite gum-powered UI | - | Yes |
| Verified/signed updates | - | Yes |
| Multi-repo orchestration | - | Yes |
| Team policy packs | - | Yes |
| SBOM export | - | Yes |
| Audit logging | - | Yes |

## Pro Features in Detail

### Exquisite Terminal UI

When Pro is enabled and `gum` is installed, the console transforms into a polished, game-like experience:

- Animated confirmations and progress indicators
- Rich menu rendering with colors and borders
- Better previews and diff displays
- Smooth transitions between screens

**Note**: All consequential actions still require typed `YES` - the enhanced UI is for polish, not bypassing security.

### Hardened Supply-Chain Updates

Pro adds cryptographic verification to the update process:

- Signed release verification using GPG or sigstore
- Attestation checking for CI-built artifacts
- Refuses updates that fail verification
- Clear audit trail of update decisions

### Multi-Repo Orchestration ("Console Hub")

Manage multiple repositories as "cartridges":

```yaml
# cartridges.yaml
cartridges:
  - name: frontend
    path: ../frontend
    commands:
      build: npm run build
      test: npm test

  - name: backend
    path: ../backend
    commands:
      build: ./gradlew build
      test: ./gradlew test
```

Each cartridge action is individually gated - no batch approvals that could hide dangerous operations.

### Team Policy Packs

Define and share security profiles across your organization:

- **Offline**: No network operations permitted
- **Repo-only**: Only git-based updates allowed
- **Verified-only**: Require signed artifacts for all updates
- **Custom**: Define your own constraints

Policies are versioned and switching requires explicit `YES` with diff display.

## Activation

### Trial

Start a 14-day trial from the console menu. No credit card required.

### Purchase

Visit [purchase-url] to obtain a license key.

### Activation Steps

1. Place your license file at `.oneclick-pro.license`
2. Run `bash ./oneclick.sh`
3. The console will detect and validate the license
4. Pro features become available immediately

### Deactivation

Remove the license file to return to free mode. No data is lost.

## Pricing

- **Individual**: $X/month or $Y/year
- **Team** (5 seats): $X/month or $Y/year
- **Enterprise**: Contact us

## No Dark Patterns Promise

We believe in ethical software monetization:

- Free tier is genuinely useful and complete
- Pro features are additive, never punitive
- No artificial limits or degraded performance
- No countdown timers or pressure tactics
- Upgrade prompts are always skippable
- Trial doesn't require payment info

If you find value in Pro features, we'd love your support. If the free tier meets your needs, that's great too.

## Support

- **Free users**: Community support via GitHub issues
- **Pro users**: Priority support via email
- **Enterprise**: Dedicated support channel + SLA
