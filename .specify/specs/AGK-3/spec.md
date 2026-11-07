# Specification: AGK-3 Deploy Amazon EKS Cluster & Managed Node Group

| Attribute | Details |
| :--- | :--- |
| **Jira Issue Key** | [AGK-3](https://rjcloudev.atlassian.net/browse/AGK-3) |
| **Jira Issue URL** | `https://rjcloudev.atlassian.net/browse/AGK-3` |
| **Parent Epic** | `[EPIC-K8S] Production Amazon EKS Control Plane & Compute` |
| **Epic Goal** | Provision a production-hardened Amazon EKS 1.31 cluster with KMS envelope encryption, API Access Entries, and IMDSv2-hardened t3.medium private worker nodes. |
| **Target AWS Region** | `ap-southeast-1` (Singapore) |
| **AWS Account ID** | `570515227299` |
| **FinOps Guardrail** | Kubernetes 1.31 standard support (\$0 extended fee); `t3.medium` capped at `min=2, desired=2, max=4`; 7-day log retention |

---

## 1. User Story Statement

> **As a** Cloud Platform Engineer,  
> **I want** to deploy an Amazon EKS 1.31 control plane and a managed node group running across private subnets using an IMDSv2-hardened launch template and customer-managed KMS envelope encryption,  
> **So that** our Kubernetes workloads run in an isolated, secure, and autoscalable environment with modern EKS Access Entries and EKS Pod Identity support without exceeding the \$130 AWS budget limit.

---

## 2. Acceptance Criteria & Architecture Requirements

### 2.1 EKS Control Plane Configuration
- [x] **Kubernetes Version:** `1.31` (Standard Support, avoids extended support charges).
- [x] **Envelope Encryption:** Customer-managed KMS key encrypting Kubernetes `secrets` with `enable_key_rotation = true`.
- [x] **Authentication Mode:** `API_AND_CONFIG_MAP` with modern `aws_eks_access_entry` and `AmazonEKSClusterAdminPolicy` association for cluster administrators.
- [x] **Control Plane Logging:** Enabled for `api`, `audit`, and `authenticator` sending to a dedicated CloudWatch Log Group (`retention_in_days = 7`).
- [x] **VPC Integration:** Private endpoint enabled, public endpoint enabled with CIDR restriction or cluster-level security group. Cluster deployed across private subnets.

### 2.2 Managed Node Group (`t3.medium`)
- [x] **Compute Sizing:** Instance type `t3.medium` (2 vCPU, 4 GiB memory, 17 max pods).
- [x] **Autoscaling Guardrails:** `min_size = 2`, `desired_size = 2`, `max_size = 4` hard cap to protect AWS credit budget.
- [x] **Subnet Placement:** Nodes deployed strictly across private subnets (`10.0.11.0/24`, `10.0.12.0/24`).
- [x] **Custom Launch Template:**
  - Enforce IMDSv2: `http_tokens = "required"`, `http_put_response_hop_limit = 1`.
  - EBS root volume: `gp3`, encrypted (`encrypted = true`), `volume_size = 20`.
  - Tagged with cluster ownership tags.

### 2.3 Essential Managed EKS Add-ons
- [x] `vpc-cni` (AWS VPC CNI for native Pod IP routing)
- [x] `coredns` (Kubernetes DNS resolution)
- [x] `kube-proxy` (Network proxy)
- [x] `eks-pod-identity-agent` (EKS Pod Identity agent for short-lived credentials)

### 2.4 Validation Criteria
- [x] `terraform fmt -recursive` passes with zero discrepancies
- [x] `terraform validate` in `environments/dev` passes with zero errors

