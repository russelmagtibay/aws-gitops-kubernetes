# Implementation & Validation Checklist: AGK-6

- [x] **Task 1: Create Infrastructure DevSecOps Pipeline**
  - Path: `.github/workflows/infra.yml`
  - Configure GitHub Actions OIDC federation for AWS.
  - Implement `terraform fmt -check`, `terraform init`, `terraform validate`, TFLint, and Checkov scanner.

- [x] **Task 2: Create Application Microservice Pipeline**
  - Path: `.github/workflows/app.yml`
  - Implement Python `pytest` testing step.
  - Implement Docker build, Trivy vulnerability scan, and Amazon ECR push.

- [x] **Task 3: Create Declarative ArgoCD GitOps Manifest**
  - Path: `k8s/argocd-application.yaml`
  - Define ArgoCD `Application` targeting `k8s/` into namespace `production`.
  - Configure automated sync policy with `prune: true` and `selfHeal: true`.

- [x] **Task 4: Execute Automated Validation & SDD Documentation Update**
  - Verify YAML workflow syntax.
  - Run `terraform fmt -recursive` and `terraform validate`.
  - Mark tasks complete in `tasks.md` and update `SPEC.md` to **Done**.
