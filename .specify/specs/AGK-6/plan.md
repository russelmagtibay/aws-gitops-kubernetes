# Technical Blueprint & Implementation Plan: AGK-6

| Attribute | Details |
| :--- | :--- |
| **Jira Issue Key** | [AGK-6](https://rjcloudev.atlassian.net/browse/AGK-6) |
| **Parent Epic** | `[EPIC-GITOPS] 3-Tier Microservices, HPA Autoscaling & ArgoCD GitOps` |
| **Components** | `.github/workflows/infra.yml`, `.github/workflows/app.yml`, `k8s/argocd-application.yaml` |
| **Target AWS Region** | `ap-southeast-1` |

---

## 1. Files & Modules Affected

1. **`.github/workflows/infra.yml`**:
   - Two-speed infrastructure pipeline triggered on infrastructure code paths.
   - GitHub Actions OIDC federated login to AWS Account `570515227299`.
   - Setup Terraform, run `terraform fmt -check`, `terraform init`, `terraform validate`, TFLint, and Checkov scanner.
2. **`.github/workflows/app.yml`**:
   - Two-speed application pipeline triggered on application code paths.
   - Python setup, dependency install, and `pytest` execution.
   - Docker build, Trivy CVE scanning (`aquasecurity/trivy-action`), Amazon ECR login and push.
3. **`k8s/argocd-application.yaml`**:
   - Declarative ArgoCD `Application` manifest defining continuous GitOps reconciliation of the `k8s/` folder into the `production` namespace.
4. **`SPEC.md`**:
   - Update `AGK-6` status to **Done**.

---

## 2. Two-Speed DevSecOps CI/CD & ArgoCD GitOps Workflow

```
+---------------------------------------------------------------------------------------------------+
| TWO-SPEED DEVSECOPS & GITOPS DELIVERY ARCHITECTURE                                                |
|                                                                                                   |
| [Speed 1: Infrastructure Pipeline - infra.yml]                                                    |
|   Push / PR to `modules/**` or `environments/**`                                                  |
|     --> AWS OIDC Federation (Zero static AWS keys)                                               |
|     --> terraform fmt -check -recursive                                                           |
|     --> terraform validate                                                                        |
|     --> TFLint Static Analysis                                                                    |
|     --> Checkov IaC Security Scanner (CKV / CKV2 compliance)                                      |
|                                                                                                   |
| [Speed 2: Microservice Application Pipeline - app.yml]                                           |
|   Push / PR to `app/**`                                                                           |
|     --> Python 3.11 Pytest Unit Tests                                                             |
|     --> Docker Multi-Stage Container Build                                                        |
|     --> Trivy Container Image Security Scan (HIGH / CRITICAL block)                               |
|     --> AWS OIDC Login & Push to Amazon ECR                                                       |
|                                                                                                   |
| [Continuous GitOps Reconciliation - ArgoCD]                                                       |
|   k8s/argocd-application.yaml                                                                     |
|     --> ArgoCD Controller syncs `k8s/` to `production` namespace                                  |
|     --> Automated Self-Healing (`selfHeal: true`) and Pruning (`prune: true`)                     |
+---------------------------------------------------------------------------------------------------+
```

---

## 3. FinOps & Checkov Guardrails Matrix

| Guardrail ID | Objective | Implementation |
| :--- | :--- | :--- |
| **FIN-11** | Zero Static AWS Key Storage | GitHub Actions OIDC avoids long-lived AWS IAM User access keys with automatic credential expiration. |
| **FIN-12** | Pull Request Shift-Left Validation | Non-destructive IaC checks block invalid resource configuration before spending cloud credits. |
| **SEC-13** | Trivy Container Security | Scans application container images for vulnerabilities prior to Amazon ECR registry publishing. |
| **SEC-14** | Automated Self-Healing | ArgoCD continuously audits live cluster state against Git repository to prevent configuration drift. |

