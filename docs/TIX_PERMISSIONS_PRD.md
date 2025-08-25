# Product Requirements Document: tix-permissions Extension

## Executive Summary

`tix-permissions` provides a unified interface for managing ticket system permissions across different git hosting providers (GitHub, GitLab, Bitbucket, Gitea, etc.). It abstracts provider-specific APIs behind simple tix-style commands, enabling portable and consistent permission management.

## Problem Statement

Since tix uses git branches for projects, permissions are currently managed through each git provider's unique interface:

- GitHub uses branch protection rules and CODEOWNERS
- GitLab has protected branches and approval rules
- Bitbucket has branch restrictions
- Self-hosted solutions have their own APIs

This creates:

- Learning curve when switching providers
- Complex scripting for multi-provider environments
- No unified way to audit permissions across projects
- Difficult team onboarding and permission templates

## Solution

A single `tix-permissions` extension that translates uniform commands to provider-specific API calls.

## Core Functionality

### Setup & Configuration

```bash
# Configure provider
tix-permissions setup --provider github --token $GITHUB_TOKEN
tix-permissions setup --provider gitlab --url https://gitlab.company.com --token $TOKEN
tix-permissions setup --provider gitea --url https://git.internal.com --token $TOKEN

# Auto-detect from remote
tix-permissions setup --auto  # Detects from 'git remote -v' output
```

### Permission Management

```bash
# Grant permissions
tix-permissions grant alice --push-to backend
tix-permissions grant qa-team --approve release
tix-permissions grant bob --create-projects

# Revoke permissions
tix-permissions revoke alice --push-to backend
tix-permissions revoke contractors --create-projects

# List permissions
tix-permissions list --project backend
tix-permissions list --user alice
tix-permissions whoami  # Shows current user's permissions
```

### Permission Types

| Permission          | Description                          | Provider Mapping       |
| ------------------- | ------------------------------------ | ---------------------- |
| `--push-to PROJECT` | Can modify tickets in project/branch | Branch push access     |
| `--create-projects` | Can create new projects/branches     | Branch creation rights |
| `--approve PROJECT` | Can approve ticket changes           | PR/MR approval rights  |
| `--delete-tickets`  | Can delete tickets                   | Force push rights      |
| `--admin PROJECT`   | Full project control                 | Admin access           |

### Templates & Bulk Operations

```bash
# Define permission templates
tix-permissions template create qa-role \
  --approve release \
  --push-to staging \
  --view production

# Apply templates
tix-permissions apply alice --template qa-role
tix-permissions apply @qa-team --template qa-role

# Bulk operations
tix-permissions import permissions.yaml
tix-permissions export > permissions.yaml
```

### Validation & Enforcement

```bash
# Check if operation is allowed
tix-permissions check --can-push backend
echo $?  # 0 if allowed, 1 if denied

# Pre-push hook integration
tix push  # Internally runs: tix-permissions check --can-push $(tix switch)

# Audit permissions
tix-permissions audit --output report.md
# Generates report of all permissions across all projects
```

## Provider Abstraction Layer

### Provider Detection

```
1. Check git remote URL format
2. GitHub: github.com, *.github.com
3. GitLab: gitlab.com, self-hosted with /api/v4
4. Bitbucket: bitbucket.org
5. Gitea/Gogs: Auto-detect via API endpoint
```

### API Mapping

| tix-permissions         | GitHub                                  | GitLab                              | Bitbucket                  |
| ----------------------- | --------------------------------------- | ----------------------------------- | -------------------------- |
| grant --push-to         | Add to branch protection push allowlist | Add to protected branch push access | Update branch restrictions |
| grant --approve         | Add to CODEOWNERS                       | Add to approval rules               | Add to default reviewers   |
| grant --create-projects | Org/repo settings                       | Group/project settings              | Repository settings        |
| revoke                  | Remove from respective lists            | Remove from access levels           | Remove from restrictions   |

### Credential Management

```bash
# Multiple methods supported
tix-permissions setup --token $TOKEN  # Direct token
tix-permissions setup --use-gh-cli    # Use 'gh auth' token
tix-permissions setup --use-ssh-agent # SSH key auth where supported
tix-permissions setup --netrc         # Use .netrc file

# Per-project overrides
cd project-foo
tix-permissions setup --local --token $PROJECT_SPECIFIC_TOKEN
```

## Implementation Architecture

```
tix-permissions
├── main.go/main.rs/main.py  # CLI entry point
├── providers/
│   ├── github.go      # GitHub API client
│   ├── gitlab.go      # GitLab API client
│   ├── bitbucket.go   # Bitbucket API client
│   └── gitea.go       # Gitea/Gogs client
├── config/
│   └── permissions.yaml  # Local permission cache
└── templates/
    └── *.yaml         # Permission templates
```

## Caching & Offline Support

```bash
# Cache permissions locally
tix-permissions sync
# Stores in .tix/permissions.cache

# Work offline with cached data
tix-permissions list --cached
tix-permissions check --cached --can-push backend

# Cache invalidation
tix-permissions sync --force
```

## Error Handling

```bash
# Clear error messages
$ tix-permissions grant alice --push-to backend
Error: GitHub API rate limit exceeded (resets in 37 minutes)
Try: tix-permissions grant alice --push-to backend --cached

$ tix-permissions grant alice --admin production
Error: Insufficient privileges. You need admin access to grant admin.
Contact: bob (project admin) or carol (org owner)
```

## Integration Points

### Pre-commit Hook

```bash
#!/bin/sh
tix-permissions check --can-push $(git branch --show-current) || exit 1
```

### CI/CD Pipeline

```yaml
- name: Validate Permissions
  run: |
    tix-permissions check --can-approve ${{ github.base_ref }}
    tix-workflow validate
```

### Tix Core Integration

Future: Core tix commands could optionally check permissions:

```bash
tix push  # Could internally call tix-permissions check
```

## Success Metrics

- Single command works across 4+ git providers
- Permission check takes <100ms with cache
- Setup takes <1 minute
- 90% of permission operations don't require provider docs
- Zero provider lock-in

## Security Considerations

- Tokens stored in system keychain where available
- Minimal permission scope requested
- Read-only operations by default
- Audit log of permission changes
- Support for temporary permission grants

## Example Workflows

### New Team Member Onboarding

```bash
# HR system triggers:
tix-permissions apply new-engineer@company.com --template junior-dev
tix-permissions grant new-engineer@company.com --push-to onboarding-project
tix-permissions expire new-engineer@company.com --push-to onboarding-project --after 30d
```

### Project Release

```bash
# Lock down release branch
tix-permissions revoke @all --push-to release
tix-permissions grant release-manager --push-to release --approve release
tix-permissions audit --project release > release-permissions.log
```

### Provider Migration

```bash
# Export from GitHub
tix-permissions setup --provider github
tix-permissions export > permissions.yaml

# Import to GitLab
tix-permissions setup --provider gitlab
tix-permissions import permissions.yaml
```

## Conclusion

`tix-permissions` exemplifies the Unix philosophy applied to modern development workflows: a simple, uniform interface hiding provider complexity. It makes permission management portable, scriptable, and discoverable while maintaining zero coupling with tix core.

