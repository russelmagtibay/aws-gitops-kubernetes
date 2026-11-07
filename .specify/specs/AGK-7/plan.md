# Technical Blueprint & Implementation Plan: AGK-7

| Attribute | Details |
| :--- | :--- |
| **Jira Issue Key** | [AGK-7](https://rjcloudev.atlassian.net/browse/AGK-7) |
| **Parent Epic** | `[EPIC-CICD] Zero-Trust DevSecOps CI/CD & ArgoCD GitOps Delivery` |
| **Components** | `modules/ecr/`, `modules/iam/`, `environments/dev/`, `.github/workflows/infra.yml` |
| **Target AWS Region** | `ap-southeast-1` |

---

## 1. Files & Modules Affected

1. **`modules/ecr/variables.tf`**:
   - `project_name`, `environment`, `repository_names` (`set(string)`, default `["lead-capture-backend", "lead-capture-frontend"]`), `image_tag_mutability` (`"IMMUTABLE"`), `max_image_count` (`5`).
2. **`modules/ecr/main.tf`**:
   - Customer-managed KMS Key (`aws_kms_key.ecr`) with `enable_key_rotation = true` for Checkov `CKV_AWS_136`.
   - `aws_ecr_repository.this` (`for_each = var.repository_names`) with `scan_on_push = true`, `image_tag_mutability = var.image_tag_mutability`, `force_delete = true` (for clean `terraform destroy`).
   - `aws_ecr_lifecycle_policy.this` keeping only the latest 5 images per repository.
3. **`modules/ecr/outputs.tf`**:
   - `repository_urls` (map of repo name to URL), `repository_arns` (list of ARNs).
4. **`modules/iam/variables.tf`, `modules/iam/main.tf`, `modules/iam/outputs.tf`**:
   - Add `ecr_repository_arns` and `github_repo` variables.
   - Add `aws_iam_openid_connect_provider.github` (or optional creation flag `create_github_oidc_provider`) and `aws_iam_role.github_actions` (`github-actions-eks-gitops-role`) with least-privilege ECR push permissions and S3 state access.
5. **`environments/dev/main.tf` & `environments/dev/outputs.tf`**:
   - Instantiate `module.ecr` and pass `module.ecr.repository_arns` into `module.iam`.
   - Export `ecr_repository_urls` and `github_actions_role_arn`.
6. **`.github/workflows/infra.yml`**:
   - Add `workflow_dispatch` inputs (`action: plan | apply | destroy`) so `terraform init` (with S3 remote backend) and `terraform apply` / `destroy` can be triggered on demand using OIDC without spending AWS credits on every commit.

---

## 2. ECR & GitHub OIDC Architecture Topology

```
+---------------------------------------------------------------------------------------------------+
| GitHub Actions Workflow (app.yml / infra.yml)                                                     |
|   |                                                                                               |
|   | 1. Request short-lived OIDC JWT (token.actions.githubusercontent.com)                         |
|   v                                                                                               |
| [AWS IAM OIDC Provider & Role: github-actions-eks-gitops-role]                                    |
|   |                                                                                               |
|   +---> [Speed 1: infra.yml] ---> terraform init (S3 Backend) & terraform plan/apply/destroy      |
|   |                                                                                               |
|   +---> [Speed 2: app.yml]   ---> Push Scanned Images to Hardened Amazon ECR:                     |
|                                   - 570515227299.dkr.ecr.ap-southeast-1.amazonaws.com/            |
|                                     * lead-capture-backend  (KMS + ScanOnPush + Keep Last 5)      |
|                                     * lead-capture-frontend (KMS + ScanOnPush + Keep Last 5)      |
+---------------------------------------------------------------------------------------------------+
```

---

## 3. FinOps & Checkov Guardrails Matrix

| Guardrail ID | Objective | Implementation |
| :--- | :--- | :--- |
| **FIN-13** | Prevent ECR Storage Bloat | `aws_ecr_lifecycle_policy` expires images beyond the last 5 builds. |
| **FIN-14** | Clean Teardown (`terraform destroy`) | `force_delete = true` on ECR repositories ensures `terraform destroy` never hangs on non-empty registries. |
| **SEC-15** | Checkov `CKV_AWS_51`, `CKV_AWS_136`, `CKV_AWS_163` | Immutable tags, KMS CMK encryption with key rotation, and `scan_on_push = true`. |
| **SEC-16** | Scoped GitHub OIDC Trust | `StringLike` condition restricts `token.actions.githubusercontent.com:sub` strictly to `repo:russelmagtibay/aws-gitops-kubernetes:*`. |

