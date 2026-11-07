# Specification: AGK-6 Two-Speed GitHub Actions CI/CD & ArgoCD GitOps Reconciliation

| Attribute | Details |
| :--- | :--- |
| **Jira Issue Key** | [AGK-6](https://rjcloudev.atlassian.net/browse/AGK-6) |
| **Jira Issue URL** | `https://rjcloudev.atlassian.net/browse/AGK-6` |
| **Parent Epic** | `[EPIC-GITOPS] 3-Tier Microservices, HPA Autoscaling & ArgoCD GitOps` |
| **Epic Goal** | Automate two-speed DevSecOps pipelines with GitHub Actions OIDC (zero static AWS keys), TFLint, Checkov, Trivy vulnerability scanning, and continuous ArgoCD GitOps cluster reconciliation. |
| **Target AWS Region** | `ap-southeast-1` (Singapore) |
| **AWS Account ID** | `570515227299` |
| **FinOps Guardrail** | Automated pull request validation prevents breaking drift or resource over-provisioning |

---

## 1. User Story Statement

> **As a** Lead DevOps & Platform Engineer,  
> **I want** to implement automated two-speed DevSecOps pipelines in GitHub Actions using AWS OIDC federation alongside a declarative ArgoCD GitOps Application manifest,  
> **So that** infrastructure changes are validated for formatting and Checkov security compliance, container workloads are scanned for CVEs before ECR pushes, and Kubernetes cluster state is continuously reconciled from Git without manual intervention.

---

## 2. Acceptance Criteria & Architecture Requirements

### 2.1 Pipeline 1: Infrastructure DevSecOps (`.github/workflows/infra.yml`)
- [x] **Authentication:** Zero static AWS keys via GitHub Actions OIDC federation (`aws-actions/configure-aws-credentials`).
- [x] **Trigger Rules:** Pull requests and pushes modifying `modules/**`, `environments/**`, or `.github/workflows/infra.yml`.
- [x] **Automated Checks:**
  - `terraform fmt -check -recursive`
  - `terraform init -backend=false`
  - `terraform validate`
  - TFLint static analysis
  - Checkov IaC security scan (`bridgecrewio/checkov-action`)

### 2.2 Pipeline 2: Application DevSecOps (`.github/workflows/app.yml`)
- [x] **Authentication:** AWS OIDC federation for Amazon ECR image registry authentication.
- [x] **Trigger Rules:** Pull requests and pushes modifying `app/**` or `.github/workflows/app.yml`.
- [x] **Automated Checks:**
  - Automated `pytest` unit test execution for the FastAPI backend microservice.
  - Multi-stage Docker container build tagged with Git commit SHA.
  - Trivy container security scanning (`aquasecurity/trivy-action`) for `HIGH` and `CRITICAL` vulnerabilities.
  - Pushes images to Amazon ECR upon successful test and security scanning.

### 2.3 Declarative ArgoCD GitOps Application (`k8s/argocd-application.yaml`)
- [x] CRD: `argoproj.io/v1alpha1`, `kind: Application`.
- [x] Destination: `namespace: production`, `server: https://kubernetes.default.svc`.
- [x] Source: Path `k8s`, repo URL `https://github.com/rjcloudev/aws-gitops-kubernetes.git`, target revision `HEAD`.
- [x] Automated Sync Policy: Automated reconciliation with `prune: true` and `selfHeal: true`.

### 2.4 Validation Criteria
- [x] GitHub Actions workflow YAML manifests are syntactically valid and pass schema validation.
- [x] `SPEC.md` sprint backlog updated with all 6 User Stories (`AGK-1` through `AGK-6`) marked **Done**.

