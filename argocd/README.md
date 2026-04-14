# ArgoCD GitOps Configuration

This directory contains ArgoCD manifests for Blue/Green and Rolling deployments.

## Directory Structure

```
argocd/
├── applications/           # ArgoCD Application definitions
│   ├── app-of-apps.yaml   # Root application (manages all apps)
│   ├── staging.yaml       # Staging environment app
│   └── production.yaml    # Production environment app
├── base/                   # Base Kubernetes manifests
│   ├── deployment.yaml    # Base deployment
│   ├── service.yaml       # Base service
│   └── kustomization.yaml # Kustomize config
└── overlays/              # Environment-specific overrides
    ├── staging/
    │   └── kustomization.yaml
    └── production/
        ├── kustomization.yaml
        └── rollout.yaml   # Argo Rollouts for Blue/Green
```

## Prerequisites

1. **Install ArgoCD**
   ```bash
   kubectl create namespace argocd
   kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
   ```

2. **Install Argo Rollouts** (for Blue/Green deployments)
   ```bash
   kubectl create namespace argo-rollouts
   kubectl apply -n argo-rollouts -f https://github.com/argoproj/argo-rollouts/releases/latest/download/install.yaml
   ```

3. **Install Argo Rollouts kubectl plugin**
   ```bash
   brew install argoproj/tap/kubectl-argo-rollouts
   ```

## Setup

### 1. Configure Repository Access

```bash
# Add your Git repository to ArgoCD
argocd repo add https://github.com/YOUR_ORG/YOUR_REPO.git \
  --username <username> \
  --password <token>
```

### 2. Update Manifests

Replace placeholders in the manifests:
- `YOUR_ORG/YOUR_REPO` - Your GitHub organization and repository
- `ACCOUNT_ID` - Your AWS account ID
- `REGION` - Your AWS region

### 3. Deploy App of Apps

```bash
kubectl apply -f argocd/applications/app-of-apps.yaml
```

## Deployment Strategies

### Staging (Rolling Update)
- Automatic sync enabled
- Self-healing enabled
- Standard Kubernetes rolling update

### Production (Blue/Green with Argo Rollouts)
- Manual sync required (approval workflow)
- Blue/Green deployment strategy
- Preview service for testing before promotion

## Blue/Green Workflow

1. **New version deployed** → Creates preview pods
2. **Preview testing** → Test via `app-preview` service
3. **Promote** → Switch traffic to new version
   ```bash
   kubectl argo rollouts promote app-rollout -n production
   ```
4. **Rollback** (if needed)
   ```bash
   kubectl argo rollouts undo app-rollout -n production
   ```

## Monitoring Rollouts

```bash
# Watch rollout status
kubectl argo rollouts get rollout app-rollout -n production --watch

# View rollout history
kubectl argo rollouts history app-rollout -n production

# Dashboard (opens browser)
kubectl argo rollouts dashboard
```

## ArgoCD Commands

```bash
# Get ArgoCD admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Port forward ArgoCD UI
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Login to ArgoCD CLI
argocd login localhost:8080

# Sync application manually
argocd app sync app-production

# View application status
argocd app get app-production
```

## GitHub Actions Integration

The CI/CD pipeline automatically:
1. Builds and pushes images to ECR
2. Updates image tags in this directory
3. ArgoCD detects changes and syncs (staging auto, production manual)

### Required GitHub Secrets
- `AWS_ACCESS_KEY_ID` - From Terraform ECR module output
- `AWS_SECRET_ACCESS_KEY` - From Terraform ECR module output

### Required GitHub Variables
- `AWS_REGION` - e.g., `eu-west-1`
- `ECR_REPOSITORY` - e.g., `acc-app`
