# Specification: AGK-4 Install AWS Load Balancer Controller via Helm

| Attribute | Details |
| :--- | :--- |
| **Jira Issue Key** | [AGK-4](https://rjcloudev.atlassian.net/browse/AGK-4) |
| **Jira Issue URL** | `https://rjcloudev.atlassian.net/browse/AGK-4` |
| **Parent Epic** | `[EPIC-ING] Cloud-Native Layer-7 Ingress & Traffic Routing` |
| **Epic Goal** | Automate AWS Application Load Balancer (ALB) provisioning from Kubernetes Ingress resources with direct-to-Pod IP routing (`target-type: ip`). |
| **Target AWS Region** | `ap-southeast-1` (Singapore) |
| **AWS Account ID** | `570515227299` |
| **FinOps Guardrail** | ALB provisioned dynamically on Ingress deployment; no idle pre-warmed ALB charges |

---

## 1. User Story Statement

> **As a** Cloud Platform & Kubernetes Engineer,  
> **I want** to deploy the AWS Load Balancer Controller using Helm with EKS Workload Identity (EKS Pod Identity / IRSA),  
> **So that** Kubernetes `Ingress` resources dynamically provision AWS Application Load Balancers with `target-type: ip` routing traffic directly to private Pod endpoints.

---

## 2. Acceptance Criteria & Architecture Requirements

### 2.1 EKS Pod Identity / IRSA Association
- [x] Service Account `aws-load-balancer-controller` created in namespace `kube-system`.
- [x] Associated with `alb_controller` IAM role ARN created in `modules/iam` (using `aws_eks_pod_identity_association`).

### 2.2 Helm Chart Configuration
- [x] Chart Repository: `https://aws.github.io/eks-charts`
- [x] Chart Name: `aws-load-balancer-controller`
- [x] Namespace: `kube-system`
- [x] Required Values Configured:
  - `clusterName`: Set to the EKS cluster name (`${project_name}-${environment}-cluster`).
  - `region`: Set to `ap-southeast-1`.
  - `vpcId`: Set to the EKS VPC ID.
  - `serviceAccount.name`: `aws-load-balancer-controller`.
  - `serviceAccount.create`: `true`.

### 2.3 Provider Authentication
- [x] Terraform `helm` provider configured to authenticate dynamically to the EKS cluster endpoint using cluster certificate authority and token.

### 2.4 Validation Criteria
- [x] `terraform fmt -recursive` passes with zero discrepancies.
- [x] `terraform validate` in `environments/dev` passes with zero errors.

