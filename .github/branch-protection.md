# Branch Protection Rules for Main Branch

Configure these settings in GitHub: **Settings → Branches → Add rule**

## Branch name pattern
```
main
```

## Protection Rules

### ✅ Require a pull request before merging
- [x] Require approvals: `1` (or more based on team size)
- [x] Dismiss stale pull request approvals when new commits are pushed
- [x] Require review from Code Owners (optional)

### ✅ Require status checks to pass before merging
- [x] Require branches to be up to date before merging

**Required status checks:**
- `Format Check`
- `Validate`
- `Plan`

### ✅ Require conversation resolution before merging

### ✅ Do not allow bypassing the above settings
- Even administrators must follow these rules

### ❌ Allow force pushes
- Disabled

### ❌ Allow deletions
- Disabled

---

## How to Configure via GitHub CLI

```bash
gh api repos/{owner}/{repo}/branches/main/protection -X PUT \
  -H "Accept: application/vnd.github+json" \
  -f required_status_checks='{"strict":true,"contexts":["Format Check","Validate","Plan"]}' \
  -f enforce_admins=true \
  -f required_pull_request_reviews='{"dismiss_stale_reviews":true,"require_code_owner_reviews":false,"required_approving_review_count":1}' \
  -f restrictions=null \
  -f allow_force_pushes=false \
  -f allow_deletions=false
```

## Workflow Summary

```
┌─────────────────────────────────────────────────────────────────┐
│                        PR Created                                │
│                            │                                     │
│                            ▼                                     │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │              terraform fmt -check                        │    │
│  │                     │                                    │    │
│  │         ┌───────────┴───────────┐                       │    │
│  │         ▼                       ▼                        │    │
│  │      ✅ Pass               ❌ Fail                       │    │
│  │         │                  Comment: "Run terraform fmt"  │    │
│  │         │                  Block merge                   │    │
│  │         ▼                                                │    │
│  │   terraform validate                                     │    │
│  │         │                                                │    │
│  │         ▼                                                │    │
│  │   terraform plan                                         │    │
│  │         │                                                │    │
│  │         ▼                                                │    │
│  │   Comment plan on PR                                     │    │
│  └─────────────────────────────────────────────────────────┘    │
│                            │                                     │
│                            ▼                                     │
│              All checks pass? ──No──▶ Block merge               │
│                     │                                            │
│                    Yes                                           │
│                     │                                            │
│                     ▼                                            │
│              Review & Approve                                    │
│                     │                                            │
│                     ▼                                            │
│                Merge to main                                     │
│                     │                                            │
│                     ▼                                            │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │              terraform apply                             │    │
│  │         (with production environment)                    │    │
│  └─────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
```
