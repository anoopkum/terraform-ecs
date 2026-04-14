# CI/CD Pipeline Documentation

Complete CI/CD setup using GitHub Actions, Amazon ECR, and ArgoCD.

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              CI/CD Pipeline                                  │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────────────────┐  │
│  │  GitHub  │───▶│  GitHub  │───▶│   ECR    │───▶│       ArgoCD         │  │
│  │   Push   │    │  Actions │    │  Image   │    │  (GitOps Sync)       │  │
│  └──────────┘    └──────────┘    └──────────┘    └──────────────────────┘  │
│                       │                                    │               │
│                       │                                    ▼               │
│                       │              ┌─────────────────────────────────┐   │
│                       │              │         Kubernetes/ECS          │   │
│                       │              │  ┌─────────┐    ┌─────────────┐ │   │
│                       │              │  │ Staging │    │ Production  │ │   │
│                       │              │  │ (Auto)  │    │ (Blue/Green)│ │   │
│                       │              │  └─────────┘    └─────────────┘ │   │
│                       │              └─────────────────────────────────┘   │
│                       │                                                    │
│                       ▼                                                    │
│              ┌──────────────┐                                              │
│              │ Update Image │                                              │
│              │ Tag in Repo  │                                              │
│              └──────────────┘                                              │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Components

### 1. GitHub Actions Workflows

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| `ci.yml` | PR, push to develop | Lint, test, security scan |
| `build-push.yml` | Push to main, tags | Build image, push to ECR, update manifests |
| `deploy.yml` | Manual | Deploy specific version to environment |

### 2. ECR Module (`modules/ecr/`)

Creates:
- ECR repository with lifecycle policies
- IAM user for GitHub Actions
- Security scanning on push

### 3. ArgoCD Configuration (`argocd/`)

- **Staging**: Auto-sync with rolling updates
- **Production**: Manual sync with Blue/Green deployment

## Setup Instructions

### Step 1: Deploy ECR Infrastructure

Add to your `ecs.tf`:

```hcl
module "ecr" {
  source      = "./modules/ecr"
  environment = var.environment
  app_name    = "app"
}

output "github_actions_access_key" {
  value     = module.ecr.github_actions_access_key
  sensitive = false
}

output "github_actions_secret_key" {
  value     = module.ecr.github_actions_secret_key
  sensitive = true
}

output "ecr_repository_url" {
  value = module.ecr.repository_url
}
```

Apply:
```bash
terraform apply -var-file=ecs.tfvars
```

### Step 2: Configure GitHub Secrets

Get credentials from Terraform output:
```bash
terraform output github_actions_access_key
terraform output github_actions_secret_key
```

Add to GitHub repository Settings → Secrets:
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`

Add to GitHub repository Settings → Variables:
- `AWS_REGION` = `eu-west-1`
- `ECR_REPOSITORY` = `acc-app`

### Step 3: Create Dockerfile

Create a `Dockerfile` in your repository root:

```dockerfile
# Build stage
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

# Test stage
FROM builder AS test
RUN npm ci
COPY . .
RUN npm test

# Production stage
FROM node:20-alpine
WORKDIR /app
COPY --from=builder /app/node_modules ./node_modules
COPY . .
EXPOSE 80
USER node
CMD ["node", "server.js"]
```

### Step 4: Setup ArgoCD

```bash
# Install ArgoCD
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Install Argo Rollouts
kubectl create namespace argo-rollouts
kubectl apply -n argo-rollouts -f https://github.com/argoproj/argo-rollouts/releases/latest/download/install.yaml

# Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Access UI
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

### Step 5: Update ArgoCD Manifests

Edit files in `argocd/` directory:
1. Replace `YOUR_ORG/YOUR_REPO` with your GitHub repository
2. Replace `ACCOUNT_ID` with your AWS account ID
3. Replace `REGION` with your AWS region

### Step 6: Deploy Applications

```bash
kubectl apply -f argocd/applications/app-of-apps.yaml
```

## Workflow

### Development Flow

1. Create feature branch
2. Push changes → CI runs (lint, test, scan)
3. Create PR → Review
4. Merge to main → Build & push image
5. Image tag updated in repo → ArgoCD syncs

### Production Deployment

1. Staging auto-deploys on merge
2. Verify in staging
3. Manually sync production in ArgoCD
4. Blue/Green: Preview pods created
5. Test preview service
6. Promote to switch traffic
7. Old pods scaled down

### Rollback

```bash
# ArgoCD rollback
argocd app rollback app-production

# Argo Rollouts rollback
kubectl argo rollouts undo app-rollout -n production
```

## Monitoring

```bash
# ArgoCD app status
argocd app get app-production

# Rollout status
kubectl argo rollouts get rollout app-rollout -n production --watch

# Rollout dashboard
kubectl argo rollouts dashboard
```
