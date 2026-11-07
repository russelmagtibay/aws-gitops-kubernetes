# Specification: AGK-2 Configure 3-Tier IAM Roles & EKS Pod Identity

| Attribute | Details |
| :--- | :--- |
| **Jira Issue Key** | [AGK-2](https://rjcloudev.atlassian.net/browse/AGK-2) |
| **Jira Issue URL** | `https://rjcloudev.atlassian.net/browse/AGK-2` |
| **Parent Epic** | `[EPIC-SEC] Zero-Trust IAM & Workload Identity Architecture` |
| **Epic Goal** | Enforce strict 3-tier IAM separation between the EKS Control Plane, EC2 Worker Nodes, and Kubernetes Pods using EKS Pod Identity and OIDC without static AWS keys. |
| **Target AWS Region** | `ap-southeast-1` (Singapore) |
| **AWS Account ID** | `570515227299` |
| **FinOps Guardrail** | \$0 static key overhead; DynamoDB on Pay-Per-Request (`PAY_PER_REQUEST`); SNS encrypted with AWS managed KMS |

---

## 1. User Story Statement

> **As a** Cloud Security / DevOps Engineer,  
> **I want** to implement a zero-trust 3-Tier IAM architecture separating the EKS Control Plane, EC2 Managed Node Group, and Kubernetes Pod Workloads using AWS EKS Pod Identity,  
> **So that** worker nodes operate with zero static SSH keys (via SSM Session Manager), container pods interact with DynamoDB and SNS using temporary cryptographic STS credentials, and least privilege is maintained across all layers.

---

## 2. Acceptance Criteria & Architecture Requirements

### 2.1 Tier 1: EKS Cluster Control Plane IAM Role
- [x] Trust relationship: `eks.amazonaws.com`
- [x] Managed Policy attached: `arn:aws:iam::aws:policy/AmazonEKSClusterPolicy`

### 2.2 Tier 2: EKS Managed Node Group IAM Role (Zero-SSH via SSM)
- [x] Trust relationship: `ec2.amazonaws.com`
- [x] Managed Policies attached:
  1. `arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy`
  2. `arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly`
  3. `arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy`
  4. `arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore` (enables Zero-SSH bastion-free instance debugging)

### 2.3 Tier 3: Workload Identities (EKS Pod Identity & ALB Controller)
- [x] **Backend Microservice Pod Role:**
  - Trust relationship: `pods.eks.amazonaws.com` with actions `sts:AssumeRole` and `sts:TagSession`
  - Inline / customer-managed policy granting least-privilege:
    - Actions: `dynamodb:PutItem`, `dynamodb:GetItem`, `dynamodb:Query`, `dynamodb:Scan`
    - Target: Scoped strictly to the DynamoDB leads table ARN
    - Actions: `sns:Publish`
    - Target: Scoped strictly to the SNS alerts topic ARN
- [x] **AWS Load Balancer Controller IAM Role:**
  - Trust relationship: Configured for EKS Pod Identity (`pods.eks.amazonaws.com`) and OIDC provider
  - Scoped ALB controller policy attached for Kubernetes Ingress provisioning

### 2.4 Supporting Persistence Resources (FinOps-Optimized)
- [x] **DynamoDB Leads Table (`modules/dynamodb`):**
  - Billing mode: `PAY_PER_REQUEST` (Zero idle cost for credit protection)
  - Hash Key: `id` (String)
  - Server-side encryption enabled (AWS KMS / CMK)
  - Point-in-time recovery enabled
- [x] **SNS Alerts Topic (`modules/sns`):**
  - Topic Name: `${var.project_name}-${var.environment}-alerts`
  - Server-side encryption enabled via KMS (`alias/aws/sns`)

### 2.5 Validation Criteria
- [x] `terraform fmt -recursive` passes with zero discrepancies
- [x] `terraform validate` in `environments/dev` passes with zero errors

