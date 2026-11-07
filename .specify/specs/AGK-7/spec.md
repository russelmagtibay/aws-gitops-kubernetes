# Specification: AGK-7 Provision Amazon ECR Repositories & GitHub Actions OIDC IAM Role via Terraform

| Attribute | Details |
| :--- | :--- |
| **Jira Issue Key** | [AGK-7](https://rjcloudev.atlassian.net/browse/AGK-7) |
| **Jira Issue URL** | `https://rjcloudev.atlassian.net/browse/AGK-7` |
| **Parent Epic** | `[EPIC-CICD] Zero-Trust DevSecOps CI/CD & ArgoCD GitOps Delivery` |
| **Epic Goal** | Provision hardened Amazon ECR container registries and GitHub Actions OIDC IAM federation via Terraform so CI/CD pipelines can initialize remote state, execute Terraform workflows, and push scanned container images without static AWS keys. |
| **Target AWS Region** | `ap-southeast-1` (Singapore) |
| **AWS Account ID** | `570515227299` |
| **FinOps Guardrail** | ECR Lifecycle Policy expires untagged/old images (>5 images) to prevent storage bloat under the \$130 credit cap |

---

## 1. User Story Statement

> **As a** Cloud DevSecOps Engineer,  
> **I want** to provision encrypted Amazon ECR repositories (`lead-capture-backend` and `lead-capture-frontend`) with automated image scanning, lifecycle policies, and a GitHub Actions OIDC IAM Role via Terraform,  
> **So that** `terraform init` and `terraform apply` provision the complete container registry and OIDC trust chain, enabling GitHub Actions pipelines to build, scan, push images, and manage infrastructure with zero static AWS credentials.

---

## 2. Acceptance Criteria & Architecture Requirements

### 2.1 Hardened Amazon ECR Repositories (`modules/ecr/`)
- [x] Provision two ECR repositories: `lead-capture-backend` and `lead-capture-frontend` using `for_each`.
- [x] **Checkov Compliance (`CKV_AWS_163`):** `scan_on_push = true` enabled on all repositories.
- [x] **Checkov Compliance (`CKV_AWS_136`):** KMS encryption (`encryption_type = "KMS"`) enabled on all repositories.
- [x] **Checkov Compliance (`CKV_AWS_51`):** `image_tag_mutability = "IMMUTABLE"` (with configurable variable default).
- [x] **FinOps Lifecycle Policy:** Automatically expire images beyond the most recent 5 tags so ECR storage costs remain near \$0.00.

### 2.2 GitHub Actions OIDC Provider & IAM Role (`modules/iam/`)
- [x] **GitHub OIDC Provider:** `https://token.actions.githubusercontent.com` (`client_id_list = ["sts.amazonaws.com"]`).
- [x] **IAM Role (`github-actions-eks-gitops-role`):**
  - Trust policy scoped strictly to `repo:russelmagtibay/aws-gitops-kubernetes:*` (and `rjcloudev/aws-gitops-kubernetes:*`).
  - Least-privilege ECR push/pull policy (`ecr:GetAuthorizationToken`, `ecr:BatchCheckLayerAvailability`, `ecr:PutImage`, `ecr:InitiateLayerUpload`, `ecr:UploadLayerPart`, `ecr:CompleteLayerUpload`) scoped to the provisioned ECR repository ARNs.

### 2.3 Terraform Init & Apply Integration
- [x] Wire `module.ecr` into `environments/dev/main.tf` and export repository URLs and GitHub Actions OIDC role ARN in `environments/dev/outputs.tf`.
- [x] Enhance `.github/workflows/infra.yml` with an optional `workflow_dispatch` job (`terraform init` + `terraform plan` / `apply` / `destroy`) so infrastructure deployment is strictly controlled to protect the \$130 AWS credit budget.
- [x] `terraform fmt -recursive`, `terraform init -backend=false`, and `terraform validate` pass with zero errors.

