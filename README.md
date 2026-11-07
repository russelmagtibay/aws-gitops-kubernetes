# Enterprise Amazon EKS Multi-Tier GitOps Platform (`aws-gitops-kubernetes`)

[![Terraform](https://img.shields.io/badge/Terraform-1.10+-623CE4?logo=terraform&logoColor=white)](https://www.terraform.io/)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-1.31-326CE5?logo=kubernetes&logoColor=white)](https://kubernetes.io/)
[![AWS](https://img.shields.io/badge/AWS-ap--southeast--1-FF9900?logo=amazon-aws&logoColor=white)](https://aws.amazon.com/)
[![ArgoCD](https://img.shields.io/badge/GitOps-ArgoCD-EF7B4D?logo=argo&logoColor=white)](https://argoproj.github.io/cd/)
[![Checkov](https://img.shields.io/badge/Security-Checkov_Pass-green?logo=bridgecrew&logoColor=white)](https://www.checkov.io/)

> **Project Lead / Author:** John Russel Magtibay ([`russelmagtibay`](https://github.com/rjcloudev))  
> **Jira Workspace:** [`aws-gitops-kurbenates` (`AGK`) — Sprint 1](https://rjcloudev.atlassian.net/jira/software/projects/AGK/boards/3)  
> **Confluence Blueprint:** [Production-Grade Amazon EKS Multi-Tier Microservices Platform](https://rjcloudev.atlassian.net/wiki/spaces/SCRUM/overview)  
> **AWS Account ID:** `570515227299` | **Target Region:** `ap-southeast-1` (Singapore)

---

## Architecture Overview

This repository contains the end-to-end, production-grade Infrastructure as Code (IaC), Kubernetes manifests, and two-speed DevSecOps CI/CD pipelines for an elastic 3-tier microservices platform running on **Amazon Elastic Kubernetes Service (EKS 1.31)**.

```
+---------------------------------------------------------------------------------------------------+
| AWS VPC: 10.0.0.0/16 (Singapore: ap-southeast-1)                                                  |
|                                                                                                   |
|  [Availability Zone: ap-southeast-1a]                     [Availability Zone: ap-southeast-1b]    |
|  +--------------------------------------------+          +------------------------------------+   |
|  | Public Subnet: 10.0.1.0/24                 |          | Public Subnet: 10.0.2.0/24         |   |
|  | Tag: kubernetes.io/role/elb = "1"          |          | Tag: kubernetes.io/role/elb = "1"  |   |
|  | [Single NAT Gateway] ($32.85/mo savings)   |          |                                    |   |
|  | [AWS Application Load Balancer]             |          | [AWS Application Load Balancer]    |   |
|  +--------------------------------------------+          +------------------------------------+   |
|         |                                                                    |                    |
|         |                                                                    |                    |
|         v                                                                    v                    |
|  +--------------------------------------------+          +------------------------------------+   |
|  | Private Subnet: 10.0.11.0/24               |          | Private Subnet: 10.0.12.0/24       |   |
|  | Tag: kubernetes.io/role/internal-elb = "1" |          | Tag: kubernetes.io/role/internal-elb|  |
|  | EKS Worker Nodes (t3.medium)               |          | EKS Worker Nodes (t3.medium)       |   |
|  |   - Frontend UI (Port 80)                  |          |   - Frontend UI (Port 80)          |   |
|  |   - FastAPI Backend (Port 8000)            |          |   - FastAPI Backend (Port 8000)    |   |
|  |   - Horizontal Pod Autoscaler (2-6 Pods)   |          |   - HPA CPU Target: 70%            |   |
|  +--------------------------------------------+          +------------------------------------+   |
|                                                                                                   |
|  +---------------------------------------------------------------------------------------------+  |
|  | S3 Gateway Endpoint ($0.00 / Free ECR pulls) | DynamoDB Leads Table | Encrypted SNS Alerts     |  |
|  +---------------------------------------------------------------------------------------------+  |
+---------------------------------------------------------------------------------------------------+
```

---

## Jira Epics & User Stories Traceability Matrix

Every architectural capability is governed by Spec-Driven Development (SDD) via `/speckit` and traced to Jira Epics and User Stories:

| Jira Key | Component | Epic | Deliverables | Status |
| :--- | :--- | :--- | :--- | :--- |
| [**`AGK-1`**](https://rjcloudev.atlassian.net/browse/AGK-1) | `[EKS-VPC]` Multi-AZ Networking | `[EPIC-NET]` | [`modules/vpc/`](modules/vpc/), [`environments/dev/`](environments/dev/) | **Done** |
| [**`AGK-2`**](https://rjcloudev.atlassian.net/browse/AGK-2) | `[EKS-IAM]` 3-Tier IAM & Pod Identity | `[EPIC-SEC]` | [`modules/iam/`](modules/iam/), [`modules/dynamodb/`](modules/dynamodb/), [`modules/sns/`](modules/sns/) | **Done** |
| [**`AGK-3`**](https://rjcloudev.atlassian.net/browse/AGK-3) | `[EKS-CORE]` EKS 1.31 & Node Group | `[EPIC-K8S]` | [`modules/eks/`](modules/eks/) | **Done** |
| [**`AGK-4`**](https://rjcloudev.atlassian.net/browse/AGK-4) | `[EKS-INGRESS]` AWS ALB Controller | `[EPIC-ING]` | [`modules/alb_controller/`](modules/alb_controller/), [`environments/dev/helm.tf`](environments/dev/helm.tf) | **Done** |
| [**`AGK-5`**](https://rjcloudev.atlassian.net/browse/AGK-5) | `[EKS-K8S]` 3-Tier Microservices & HPA | `[EPIC-GITOPS]` | [`app/`](app/), [`k8s/`](k8s/) | **Done** |
| [**`AGK-6`**](https://rjcloudev.atlassian.net/browse/AGK-6) | `[EKS-CICD]` Two-Speed CI/CD & ArgoCD | `[EPIC-CICD]` | [`.github/workflows/`](.github/workflows/), [`k8s/argocd-application.yaml`](k8s/argocd-application.yaml) | **Done** |
| [**`AGK-7`**](https://rjcloudev.atlassian.net/browse/AGK-7) | `[EKS-ECR]` Amazon ECR & GitHub OIDC IAM | `[EPIC-CICD]` | [`modules/ecr/`](modules/ecr/), [`modules/iam/`](modules/iam/) | **Done** |

---

## Project Directory Layout

```
aws-gitops-kubernetes/
├── .github/
│   └── workflows/
│       ├── infra.yml               # Two-Speed Pipeline: Terraform fmt, validate, TFLint & Checkov
│       └── app.yml                 # Two-Speed Pipeline: Pytest, Docker multi-stage, Trivy scan & ECR
├── .specify/
│   ├── memory/
│   │   └── constitution.md        # Confluence Architectural Blueprint & Non-Negotiable Guardrails
│   └── specs/                     # SDD Spec-Kit Deliverables per User Story
│       ├── AGK-1/                 # {spec.md, plan.md, tasks.md} - Multi-AZ VPC
│       ├── AGK-2/                 # {spec.md, plan.md, tasks.md} - 3-Tier IAM & Workload Identity
│       ├── AGK-3/                 # {spec.md, plan.md, tasks.md} - EKS 1.31 & IMDSv2 Compute
│       ├── AGK-4/                 # {spec.md, plan.md, tasks.md} - AWS Load Balancer Controller
│       ├── AGK-5/                 # {spec.md, plan.md, tasks.md} - 3-Tier Microservices & HPA
│       ├── AGK-6/                 # {spec.md, plan.md, tasks.md} - CI/CD & ArgoCD GitOps
│       └── AGK-7/                 # {spec.md, plan.md, tasks.md} - Amazon ECR & GitHub OIDC IAM
├── app/
│   ├── backend/                   # FastAPI Lead Capture Microservice (main.py, test_main.py, Dockerfile)
│   └── frontend/                  # Responsive Lead Capture Web UI (index.html, nginx.conf, Dockerfile)
├── environments/
│   └── dev/                       # Root Terraform Environment for Dev deployment
│       ├── main.tf                # Module orchestration & EKS Pod Identity associations
│       ├── helm.tf                # AWS Load Balancer Controller Helm release
│       ├── outputs.tf             # VPC, EKS, IAM, and persistence outputs
│       ├── providers.tf           # AWS and Helm dynamic auth providers + remote S3 backend
│       └── variables.tf           # Environment configuration & az_subnet_map
├── k8s/                           # Declarative Kubernetes Manifests (ArgoCD target)
│   ├── 00-namespace.yaml          # production namespace
│   ├── 01-serviceaccount.yaml     # backend-sa linked via EKS Pod Identity
│   ├── 02-backend.yaml            # Backend Deployment (non-root, probes, limits) + Service
│   ├── 03-frontend.yaml           # Frontend Deployment + Service
│   ├── 04-hpa.yaml                # autoscaling/v2 HorizontalPodAutoscaler (2-6 pods @ 70% CPU)
│   ├── 05-ingress.yaml            # AWS ALB Ingress (ingressClassName: alb, target-type: ip)
│   └── argocd-application.yaml    # Declarative GitOps Application (selfHeal: true, prune: true)
├── modules/
│   ├── vpc/                       # Multi-AZ VPC with deterministic for_each & validation blocks
│   ├── ecr/                       # KMS-encrypted Amazon ECR repositories with ScanOnPush & Lifecycle
│   ├── iam/                       # 3-Tier Least-Privilege IAM (Cluster, Node SSM, Pod Identity, GitHub OIDC)
│   ├── dynamodb/                  # FinOps PAY_PER_REQUEST Leads persistence table
│   ├── sns/                       # KMS-encrypted alerts topic
│   ├── eks/                       # EKS 1.31, KMS Secret envelope encryption, Access Entries, IMDSv2 LT
│   └── alb_controller/            # Helm release & Pod Identity association for ALB controller
├── SPEC.md                        # Master Architecture Specification & Sprint Traceability
└── README.md                      # Comprehensive Project Documentation
```

---

## Architectural Guardrails & FinOps Controls (\$130 Credit Optimization)

1. **Deterministic AZ-to-Subnet Mapping (`for_each` + `map(object)`):**
   - Subnets are keyed explicitly by Availability Zone (`ap-southeast-1a`, `ap-southeast-1b`) preventing index drift.
   - Enforces 4 native Terraform `validation {}` blocks (Multi-AZ minimum, AZ regex verification, valid CIDR syntax, and non-overlapping public/private CIDRs).
2. **FinOps Single NAT Gateway:**
   - Deploys a single NAT Gateway in `ap-southeast-1a`, saving \$32.85/month compared to dual-AZ NAT Gateways.
   - Attached **Amazon S3 Gateway VPC Endpoint** (`com.amazonaws.ap-southeast-1.s3`) at \$0.00 cost so container image layer downloads bypass NAT data processing fees.
3. **Standard-Support EKS 1.31:**
   - Pinned to active standard-support Kubernetes 1.31, completely eliminating the \$0.60/hr (\$438/month) extended support surcharge.
4. **Compute Hardening & Node Scaling Guardrails:**
   - Worker nodes utilize `t3.medium` instances in private subnets with a hard scaling cap of `min_size = 2, desired_size = 2, max_size = 4`.
   - EC2 Launch Template enforces **IMDSv2** (`http_tokens = "required"`, `http_put_response_hop_limit = 1`) and encrypted 20 GiB `gp3` root volumes.
5. **Zero-SSH & Bastionless Debugging:**
   - Worker node role includes `AmazonSSMManagedInstanceCore` enabling AWS Systems Manager Session Manager access without open port 22 or static SSH key pairs.
6. **Zero Static AWS Keys (Workload & CI/CD Identity):**
   - Microservices interact with DynamoDB and SNS using **EKS Pod Identity** (`pods.eks.amazonaws.com`).
   - GitHub Actions pipelines authenticate to AWS using **OIDC Federation** with temporary STS tokens.
7. **Pay-Per-Request Persistence:**
   - DynamoDB table configured with `billing_mode = "PAY_PER_REQUEST"`, guaranteeing \$0 idle cost during development sprints.

---

## Verification & Testing

### 1. Terraform Non-Destructive Local Validation
```bash
# Format check across all modules
terraform fmt -check -recursive

# Validate Dev Environment
cd environments/dev
terraform init -backend=false
terraform validate
```

### 2. Microservice Backend Unit Tests
```bash
cd app/backend
python -m venv .venv
source .venv/bin/activate  # Or .venv\Scripts\Activate.ps1 on Windows
pip install -r requirements.txt
pytest -v
```

---

## License & Attribution

Developed with Spec-Driven Development discipline for the **Cloud & DevOps Engineering Portfolio** by **John Russel Magtibay**.
Licensed under the Apache 2.0 License.

