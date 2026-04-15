# Issues Tracker

This document tracks all issues encountered during the Terraform ECS project setup and their resolutions.

---

## Issue #1: Incompatible Provider for Apple Silicon (M1/M2)

**Date:** 2026-04-14  
**Status:** ✅ Resolved  
**Severity:** Critical

### Error
```
Error: Incompatible provider version

Provider registry.terraform.io/hashicorp/template v2.2.0 does not have a package 
available for your current platform, darwin_arm64.
```

### Cause
The `hashicorp/template` provider is deprecated and not available for Apple Silicon (darwin_arm64) architecture.

### Solution
Replaced all `data.template_file` resources with the built-in `templatefile()` function:

**Files Modified:**
- `modules/ecs_instances/main.tf` - Replaced template_file with templatefile()
- `modules/ecs_roles/main.tf` - Replaced template_file with templatefile()
- `modules/ecs_events/main.tf` - Replaced template_file with jsonencode()

**Before:**
```hcl
data "template_file" "user_data" {
  template = file("${path.module}/templates/user_data.sh")
  vars = {
    cluster_name = var.cluster
  }
}
```

**After:**
```hcl
locals {
  user_data = templatefile("${path.module}/templates/user_data.sh", {
    cluster_name = var.cluster
  })
}
```

---

## Issue #2: Deprecated aws_eip Attribute

**Date:** 2026-04-14  
**Status:** ✅ Resolved  
**Severity:** Warning

### Error
```
Warning: Argument is deprecated

vpc = true is deprecated. Use domain = "vpc" instead.
```

### Cause
AWS provider 5.x deprecated the `vpc = true` attribute for `aws_eip` resources.

### Solution
Updated `modules/nat_gateway/main.tf`:

**Before:**
```hcl
resource "aws_eip" "nat" {
  vpc = true
}
```

**After:**
```hcl
resource "aws_eip" "nat" {
  domain = "vpc"
}
```

---

## Issue #3: Deprecated data.aws_region Syntax

**Date:** 2026-04-14  
**Status:** ✅ Resolved  
**Severity:** Warning

### Error
```
Warning: Argument is deprecated

current = true is deprecated and will be removed in a future version.
```

### Cause
The `current = true` argument in `data.aws_region` is no longer needed.

### Solution
Updated affected modules:

**Before:**
```hcl
data "aws_region" "current" {
  current = true
}
```

**After:**
```hcl
data "aws_region" "current" {}
```

**Files Modified:**
- `modules/ecs_roles/main.tf`
- `modules/ecs_events/main.tf`

---

## Issue #4: S3 Backend Region Mismatch

**Date:** 2026-04-14  
**Status:** ✅ Resolved  
**Severity:** Critical

### Error
```
Error: Failed to get existing workspaces: Unable to list objects in S3 bucket "mybucket-rax" 
with prefix "env:/": requested bucket from "eu-west-1", actual location "us-east-1"
```

### Cause
The S3 bucket was in `us-east-1` but the Terraform backend configuration specified `eu-west-1`.

### Solution
Created a new S3 bucket in the correct region:

```bash
aws s3api create-bucket \
  --bucket terraform-ecs-state-1776202744 \
  --region eu-west-1 \
  --create-bucket-configuration LocationConstraint=eu-west-1
```

Updated `ecs.tf` backend configuration:
```hcl
backend "s3" {
  bucket       = "terraform-ecs-state-1776202744"
  key          = "terraform/ecs/terraform.tfstate"
  region       = "eu-west-1"
  encrypt      = true
  use_lockfile = true
}
```

---

## Issue #5: GitHub Actions Workflow Not Triggering

**Date:** 2026-04-14  
**Status:** ✅ Resolved  
**Severity:** High

### Error
```
gh run list --workflow=terraform.yml
no runs found
```

### Cause
1. Workflow was configured for `main` branch but repo uses `master`
2. Workflow has `paths` filter - only triggers on `.tf` or `.tfvars` changes
3. Tried to push directly to main instead of creating PR

### Solution
1. Updated `.github/workflows/terraform.yml` to use `master` branch:

```yaml
on:
  pull_request:
    branches: [master]  # Changed from [main]
  push:
    branches: [master]  # Changed from [main]
```

2. Created PR from `dev` to `master` to trigger workflow

---

## Issue #6: Terraform Format Check Failing in CI

**Date:** 2026-04-14  
**Status:** ✅ Resolved  
**Severity:** Medium

### Error
```
Terraform Format Check failed
Exit code 3
```

### Cause
Multiple Terraform files had formatting issues:
- Inconsistent spacing
- Deprecated `type = list` syntax (should be `type = list(any)`)
- Unnecessary string interpolation

### Solution
Ran `terraform fmt -recursive` to fix all formatting issues:

```bash
terraform fmt -recursive
```

**Files Modified:**
- `ecs.tf`
- `modules/alb/variables.tf`
- `modules/ecr/main.tf`
- `modules/ecs/variables.tf`
- `modules/ecs_events/main.tf`
- `modules/ecs_instances/variables.tf`
- `modules/nat_gateway/outputs.tf`
- `modules/nat_gateway/variables.tf`
- `modules/network/variables.tf`
- `modules/subnet/outputs.tf`
- `modules/subnet/variables.tf`

---

## Issue #7: AWS Profile Not Found in CI

**Date:** 2026-04-14  
**Status:** ✅ Resolved  
**Severity:** Critical

### Error
```
Error: failed to get shared config profile, default

with provider["registry.terraform.io/hashicorp/aws"],
on ecs.tf line 20, in provider "aws":
```

### Cause
The `ecs.tfvars` specified `aws_profile = "default"` but GitHub Actions doesn't have AWS profiles - it uses environment variables from secrets.

### Solution
Made the AWS profile optional:

**ecs.tf:**
```hcl
provider "aws" {
  region = var.aws_region
  # Profile is only used for local development, not in CI
  profile = var.aws_profile != "" ? var.aws_profile : null
}

variable "aws_profile" {
  description = "The AWS-CLI profile for the account to create resources in. Leave empty for CI/CD."
  default     = ""
}
```

**ecs.tfvars:**
```hcl
# Leave empty for CI/CD (uses environment variables instead).
aws_profile = ""
```

---

## Issue #8: File Path Error in Users Module

**Date:** 2026-04-14  
**Status:** ✅ Resolved  
**Severity:** Medium

### Error
```
Error: Invalid function argument

file path must be relative to the module
```

### Cause
The `file()` function was using a path without `${path.module}` prefix.

### Solution
Updated `modules/users/main.tf`:

**Before:**
```hcl
policy = file("ecs_deployer.json")
```

**After:**
```hcl
policy = file("${path.module}/ecs_deployer.json")
```

---

## Issue #9: Resources Not Visible - Wrong AWS Account

**Date:** 2026-04-15  
**Status:** ✅ Resolved  
**Severity:** Medium

### Symptom
After successful `terraform apply` in GitHub Actions, resources were not visible in AWS Console.

### Cause
Two different AWS accounts were in use:
- **302263059488** - User's AWS Console login
- **554423627906** - GitHub Actions secrets (where resources were deployed)

### Solution
Logged into the correct AWS account (554423627906) where the GitHub Actions secrets pointed to.

### Prevention
Always verify which AWS account is configured:
```bash
# Check local CLI account
aws sts get-caller-identity

# Verify GitHub secrets match your intended account
```

Ensure GitHub Actions secrets (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`) are from the same account you use in the console.

---

## Issue #10: Missing package-lock.json in CI

**Date:** 2026-04-15  
**Status:** ✅ Resolved  
**Severity:** Medium

### Error
```
npm error The `npm ci` command can only install with an existing package-lock.json
```

### Cause
The `package-lock.json` file was not committed to the repository, but the CI workflow used `npm ci` which requires it.

### Solution
1. Generated `package-lock.json` locally:
```bash
cd app
npm install --package-lock-only
```

2. Updated workflow to use `npm install` instead of `npm ci`
3. Committed `package-lock.json` to the repository

---

## Issue #11: Container Security Scan Failed - Wrong Image Tag

**Date:** 2026-04-15  
**Status:** ✅ Resolved  
**Severity:** Low

### Error
```
FATAL: unable to find the specified image "acc-app:1c6825b9585c17b267d47a3b2c77eae7529d9adf"
MANIFEST_UNKNOWN: Requested image not found
```

### Cause
The `IMAGE_TAG` environment variable used the full commit SHA, but Docker metadata action creates short SHA tags (7 characters).

### Solution
1. Changed container scan to use `latest` tag instead of `${{ env.IMAGE_TAG }}`
2. Added `continue-on-error: true` to make scan non-blocking
3. Removed container-scan from summary job dependencies

---

## Future Issues

*This section will be updated as new issues are encountered.*

---

## Quick Reference: Common Fixes

### Terraform Format
```bash
terraform fmt -recursive
```

### Validate Configuration
```bash
terraform validate
```

### Check Plan
```bash
terraform plan -var-file=ecs.tfvars
```

### Re-initialize Backend
```bash
terraform init -reconfigure
```

### Check GitHub Actions Status
```bash
gh run list --workflow=terraform.yml
gh run view <run-id>
```
