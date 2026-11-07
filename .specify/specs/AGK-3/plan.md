# Technical Blueprint & Implementation Plan: AGK-3

| Attribute | Details |
| :--- | :--- |
| **Jira Issue Key** | [AGK-3](https://rjcloudev.atlassian.net/browse/AGK-3) |
| **Parent Epic** | `[EPIC-K8S] Production Amazon EKS Control Plane & Compute` |
| **Components** | `modules/eks/`, `environments/dev/` |
| **Target AWS Region** | `ap-southeast-1` |

---

## 1. Files & Modules Affected

1. **`modules/eks/`**:
   - `variables.tf`: Inputs for `project_name`, `environment`, `vpc_id`, `private_subnet_ids`, `cluster_role_arn`, `node_role_arn`, `kubernetes_version` (default `"1.31"`), `admin_principal_arn`.
   - `main.tf`:
     - KMS Key & Policy for Kubernetes Secrets Envelope Encryption (`enable_key_rotation = true`).
     - CloudWatch Log Group for EKS cluster logs (`retention_in_days = 7`).
     - `aws_eks_cluster`: Version 1.31, KMS encryption config, enabled log types (`api`, `audit`, `authenticator`), `authentication_mode = "API_AND_CONFIG_MAP"`.
     - `aws_eks_access_entry` + `aws_eks_access_policy_association` with `AmazonEKSClusterAdminPolicy`.
     - EC2 Launch Template with IMDSv2 (`http_tokens = "required"`, `http_put_response_hop_limit = 1`), encrypted `gp3` root volume.
     - `aws_eks_node_group`: `t3.medium`, private subnets, scaling `min=2, desired=2, max=4`.
     - EKS Add-ons: `vpc-cni`, `coredns`, `kube-proxy`, `eks-pod-identity-agent`.
   - `outputs.tf`: `cluster_name`, `cluster_id`, `cluster_arn`, `cluster_endpoint`, `cluster_certificate_authority_data`, `cluster_oidc_issuer_url`, `oidc_provider_arn`, `node_group_arn`.
2. **`environments/dev/`**:
   - `main.tf`: Wire `module.eks` with VPC subnets, cluster role ARN, and node role ARN.
   - `outputs.tf`: Export EKS cluster endpoint, OIDC issuer, and node group ARN.
3. **`SPEC.md`**: Update `AGK-3` status to **Done**.

---

## 2. EKS Control Plane & Compute Topology

```
+---------------------------------------------------------------------------------------------------+
| Amazon EKS Cluster v1.31 (Standard Support - $0.00 Extended Surcharge)                            |
|                                                                                                   |
|  +---------------------------------------------------------------------------------------------+  |
|  | AWS KMS CMK (Key Rotation Enabled) --> Envelope Encryption for k8s `secrets`               |  |
|  | CloudWatch Log Group (/aws/eks/...)  --> Retention: 7 days (Audit, API, Authenticator)       |  |
|  | EKS Access Entry                     --> ClusterAdminPolicy for deployment identity         |  |
|  +---------------------------------------------------------------------------------------------+  |
|                                                                                                   |
|  Managed Add-ons: [vpc-cni] [coredns] [kube-proxy] [eks-pod-identity-agent]                       |
|                                                                                                   |
|  Private Subnet: ap-southeast-1a (10.0.11.0/24)           Private Subnet: ap-southeast-1b (10.0.12.0/24)|
|  +--------------------------------------------+          +------------------------------------+   |
|  | EKS Node Group (EC2 Launch Template)       |          | EKS Node Group (EC2 Launch Template)|  |
|  | - Instance Type: t3.medium                 |          | - Instance Type: t3.medium         |   |
|  | - IMDSv2 Enforced (hop_limit = 1)          |          | - IMDSv2 Enforced (hop_limit = 1)  |   |
|  | - Encrypted gp3 Root EBS (20 GiB)          |          | - Encrypted gp3 Root EBS (20 GiB)  |   |
|  | - Zero Public IP (Private Subnet Only)     |          | - Zero Public IP (Private Subnet)  |   |
|  +--------------------------------------------+          +------------------------------------+   |
|         Autoscaling Boundary: min_size = 2 | desired_size = 2 | max_size = 4 (Hard Budget Cap)     |
+---------------------------------------------------------------------------------------------------+
```

---

## 3. FinOps & Checkov Guardrails Matrix

| Guardrail ID | Objective | Implementation |
| :--- | :--- | :--- |
| **FIN-05** | Eliminate extended support tax | Pin Kubernetes to version `1.31` (Standard Support). |
| **FIN-06** | Constrain compute spending | Hard cap node scaling to `max_size = 4` with `t3.medium`. |
| **SEC-07** | IMDSv2 Token Enforcement | `http_tokens = "required"` and `http_put_response_hop_limit = 1` prevents SSRF credential extraction. |
| **SEC-08** | Secret Envelope Encryption | Customer managed KMS key with `enable_key_rotation = true` encrypts etcd secrets. |
| **SEC-09** | Modern Access Entries | `authentication_mode = "API_AND_CONFIG_MAP"` replaces vulnerable legacy `aws-auth` ConfigMap. |

