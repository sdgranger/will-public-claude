# DevOps / Infrastructure Domain Guide

## Common File Patterns
- `Dockerfile` / `docker-compose.yml` — container definitions
- `.github/workflows/*.yml` — GitHub Actions CI/CD
- `.gitlab-ci.yml` — GitLab CI
- `Jenkinsfile` — Jenkins pipeline
- `terraform/*.tf` — Infrastructure as Code (Terraform)
- `ansible/*.yml` — Configuration management
- `k8s/` or `kubernetes/` — Kubernetes manifests
- `Makefile` — Task automation
- `scripts/` — Shell scripts for deployment, setup, maintenance

## Common Commands

**Docker:**
- Build: `docker build -t <image> .`
- Run: `docker run -d -p <port>:<port> <image>`
- Compose up: `docker-compose up -d`
- Compose down: `docker-compose down`
- Logs: `docker logs -f <container>`

**Kubernetes:**
- Apply: `kubectl apply -f <manifest>`
- Status: `kubectl get pods`
- Logs: `kubectl logs <pod>`
- Describe: `kubectl describe pod <pod>`

**Terraform:**
- Init: `terraform init`
- Plan: `terraform plan`
- Apply: `terraform apply`
- Destroy: `terraform destroy`

**System:**
- Service status: `systemctl status <service>`
- Process check: `ps aux | grep <process>`
- Port check: `lsof -i :<port>` or `ss -tlnp`

## Common Step Patterns

- **Build step**: Build container image, verify build success
- **Deploy step**: Apply configuration, verify service health
- **Health check step**: Curl health endpoint, check response
- **Rollback step**: Define rollback procedure for every deploy step
- **Log verification step**: Check logs for errors after changes
- **Cleanup step**: Remove temporary resources, old images

## Recommended allowed-tools

```yaml
allowed-tools:
  - Bash(docker:*)
  - Bash(docker-compose:*)
  - Bash(kubectl:*)
  - Bash(terraform:*)
  - Bash(ssh:*)
  - Bash(curl:*)
  - Bash(systemctl:*)
  - Read
  - Edit
  - Write
  - Grep
  - Glob
```

## Common Pitfalls

- **Irreversible actions**: `terraform destroy`, `kubectl delete`, `docker system prune` — always add human checkpoints
- Secret management: never hardcode credentials in configs; use environment variables, vault, or sealed secrets
- Docker layer caching: order Dockerfile instructions from least to most frequently changed
- Port conflicts: check if ports are already in use before starting services
- CI/CD config changes can break all deployments — test in staging first
- Terraform state is critical — never manually edit `.tfstate` files
