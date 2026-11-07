# Implementation & Validation Checklist: AGK-7

- [x] **Task 1: Create Hardened Amazon ECR Module (`modules/ecr/`)**
  - Path: `modules/ecr/` (`variables.tf`, `main.tf`, `outputs.tf`)
  - Provision KMS CMK with rotation (`enable_key_rotation = true`).
  - Provision `lead-capture-backend` and `lead-capture-frontend` repositories with `for_each`, `scan_on_push = true`, `image_tag_mutability = "IMMUTABLE"`, and `force_delete = true`.
  - Attach `aws_ecr_lifecycle_policy` retaining at most 5 images.

- [x] **Task 2: Add GitHub Actions OIDC Role & ECR Push Policy (`modules/iam/`)**
  - Path: `modules/iam/` (`variables.tf`, `main.tf`, `outputs.tf`)
  - Create `github-actions-eks-gitops-role` trusting `token.actions.githubusercontent.com` for `russelmagtibay/aws-gitops-kubernetes` and `rjcloudev/aws-gitops-kubernetes`.
  - Attach least-privilege ECR push policy scoped to `var.ecr_repository_arns`.

- [x] **Task 3: Wire ECR & OIDC into `environments/dev/`**
  - Path: `environments/dev/main.tf` and `environments/dev/outputs.tf`
  - Instantiate `module.ecr` and pass `ecr_repository_arns` to `module.iam`.
  - Export `ecr_repository_urls` and `github_actions_role_arn`.

- [x] **Task 4: Enhance `.github/workflows/infra.yml` for Controlled `terraform init` & `apply`/`destroy`**
  - Path: `.github/workflows/infra.yml`
  - Add `workflow_dispatch` inputs (`plan`, `apply`, `destroy`) with OIDC authentication and S3 backend `terraform init`.

- [x] **Task 5: Synchronize Constitution, `SPEC.md` & Run Automated Validation**
  - Update `.specify/memory/constitution.md` and `SPEC.md` with `AGK-7`.
  - Run `terraform fmt -recursive`, `terraform init -backend=false`, and `terraform validate` inside `environments/dev`.
