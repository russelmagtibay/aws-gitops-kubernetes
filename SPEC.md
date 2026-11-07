# Architecture & Engineering Specification (`SPEC.md`)

| Document Metadata | Details |
| :--- | :--- |
| **Project Name** | `aws-gitops-kubernetes` (Production Amazon EKS Multi-Tier Platform) |
| **Author / Cloud Engineer** | John Russel Magtibay (`russelmagtibay`) |
| **Jira Space & Key** | `aws-gitops-kurbenates` (`AGK`) — [AGK Sprint 1 Board](https://rjcloudev.atlassian.net/jira/software/projects/AGK/boards/3) |
| **Confluence Blueprint** | [Production-Grade Amazon EKS Multi-Tier Microservices Platform](https://rjcloudev.atlassian.net/wiki/spaces/SCRUM/overview) |
| **Target AWS Account & Region** | `570515227299` / `ap-southeast-1` (Singapore) |
| **Terraform State Bucket** | `aws-gitops-platform-tfstate-570515227299` (`key = "eks-gitops-platform/dev/terraform.tfstate"`) |
| **Budget Guardrail** | Strict cap under **\$130 USD** AWS Free Tier Credits (Single NAT Gateway, `t3.medium` cap `max_size = 4`, teardown after verification) |

---

## 1. Architecture Guardrails (Non-Negotiable Constraints)

Every Terraform module, Kubernetes manifest, and GitHub Actions workflow in this repository MUST satisfy the following constraints:

1. **Multi-AZ EKS Networking (`modules/vpc` — Jira `AGK-1`):**
   - VPC CIDR `10.0.0.0/16` spanning `ap-southeast-1a` and `ap-southeast-1b`.
   - **Deterministic AZ-to-Subnet Mapping (`for_each` + `map(object)`):**
     - Uses a structured `az_subnet_map` (`map(object({ public_cidr = string, private_cidr = string }))`) keyed by Availability Zone (`"ap-southeast-1a"`, `"ap-southeast-1b"`) instead of fragile `count` index arrays.
     - Includes native Terraform `validation {}` blocks verifying: (a) at least 2 Availability Zones are mapped (`length >= 2`), (b) all AZ keys match `ap-southeast-1*`, (c) all Public/Private CIDRs are valid IPv4 `/24` blocks (`can(cidrnetmask(...))`), and (d) Public and Private CIDRs never overlap.
   - **Public Subnets (`ap-southeast-1a` -> `10.0.1.0/24`, `ap-southeast-1b` -> `10.0.2.0/24`):** Tagged with `kubernetes.io/role/elb = "1"` and `kubernetes.io/cluster/${cluster_name} = "shared"` for internet-facing ALB discovery.
   - **Private Subnets (`ap-southeast-1a` -> `10.0.11.0/24`, `ap-southeast-1b` -> `10.0.12.0/24`):** Tagged with `kubernetes.io/role/internal-elb = "1"` and `kubernetes.io/cluster/${cluster_name} = "shared"` for EKS worker nodes and internal services.
   - **Cost Optimization:** Single NAT Gateway in `ap-southeast-1a` + free **S3 Gateway VPC Endpoint** (`com.amazonaws.ap-southeast-1.s3`) so ECR image layer pulls bypass NAT Gateway data processing charges.
   - **Checkov Compliance:** Lock down the default VPC security group (`CKV2_AWS_12`) and enable VPC Flow Logs to CloudWatch (`CKV2_AWS_11`).

2. **3-Tier Least-Privilege IAM & EKS Pod Identity (`modules/iam` — Jira `AGK-2`):**
   - **Tier 1 (EKS Control Plane Role):** `AmazonEKSClusterPolicy`.
   - **Tier 2 (Managed Node Group Role):** `AmazonEKSWorkerNodePolicy`, `AmazonEC2ContainerRegistryReadOnly`, `AmazonEKS_CNI_Policy`, and `AmazonSSMManagedInstanceCore` (Zero-SSH node debugging via AWS Systems Manager Session Manager).
   - **Tier 3 (Workload Identity — EKS Pod Identity & OIDC):**
     - **AWS Load Balancer Controller IAM Role:** Scoped to manage AWS ALB/TargetGroups/SecurityGroups via OIDC/Pod Identity.
     - **Backend Microservice Pod Role:** Scoped strictly to `dynamodb:PutItem`, `dynamodb:GetItem`, `dynamodb:Query`, `dynamodb:Scan` on the leads DynamoDB table and `sns:Publish` on the alerts SNS topic (`pods.eks.amazonaws.com`).

3. **Hardened Amazon EKS Cluster & Compute (`modules/eks` — Jira `AGK-3`):**
   - **Kubernetes Version:** Standard-support EKS version (`1.31`) — never use extended-support versions to avoid the \$0.60/hr surcharge.
   - **Authentication Mode:** `API_AND_CONFIG_MAP` / `API` with **EKS Access Entries** (`aws_eks_access_entry` + `aws_eks_access_policy_association`) replacing the deprecated `aws-auth` ConfigMap.
   - **Control Plane Audit Logging:** Enable `api`, `audit`, and `authenticator` logs to CloudWatch (`retention_in_days = 7`).
   - **Envelope Encryption:** Encrypt Kubernetes `secrets` with a dedicated customer-managed AWS KMS Key (`enable_key_rotation = true`).
   - **Managed Node Group:** Instance type `t3.medium` (2 vCPU, 4 GiB RAM, 17 max pods/node), `min_size = 2`, `desired_size = 2`, `max_size = 4`, running in private subnets only, with custom EC2 Launch Template enforcing **IMDSv2** (`http_tokens = "required"`, `http_put_response_hop_limit = 1`) and encrypted `gp3` root volumes.

4. **AWS Load Balancer Controller (`modules/alb_controller` — Jira `AGK-4`):**
   - Installed via the Terraform `helm_release` provider (`aws-load-balancer-controller` from `https://aws.github.io/eks-charts`).
   - Configured with `target-type: ip` so the Application Load Balancer routes Layer-7 HTTP traffic directly to Pod IPs inside private subnets.

5. **3-Tier Microservices, HPA & ArgoCD GitOps (`k8s/` — Jira `AGK-5`):**
   - Namespace `production` containing Frontend UI, Backend FastAPI Lead Capture API, and DynamoDB/SNS persistence.
   - Non-root container execution (`runAsNonRoot: true`, `readOnlyRootFilesystem: true`), CPU/Memory `requests` and `limits`, `livenessProbe` / `readinessProbe`, and `HorizontalPodAutoscaler` (`autoscaling/v2`) scaling from `2` to `6` replicas at `70%` CPU utilization.
   - Declarative ArgoCD `Application` manifest reconciling cluster state from Git.

---

## 2. Sprint Backlog & Traceability Matrix (Jira Key: `AGK`)

| Jira Issue | Component | Status | Deliverable Path | Acceptance Criteria |
| :--- | :--- | :--- | :--- | :--- |
| **`AGK-1`** | `[EKS-VPC]` Multi-AZ VPC & Subnets | **Done** | `modules/vpc/`, `environments/dev/` | Deterministic `az_subnet_map` (`for_each`) + 4 validation rules implemented; subnets carry `kubernetes.io/role/elb` & `internal-elb` tags; Single NAT + S3 Gateway Endpoint + locked default SG + Flow Logs; `terraform validate` passes. |
| **`AGK-2`** | `[EKS-IAM]` 3-Tier IAM & Pod Identity | To Do | `modules/iam/`, `modules/dynamodb/`, `modules/sns/` | Cluster Role, Node Role (`SSM` enabled), ALB Controller Role, and Backend Pod Identity Role pass `terraform validate`. |
| **`AGK-3`** | `[EKS-CORE]` EKS Cluster & Node Group | To Do | `modules/eks/` | EKS 1.31, KMS Secret encryption, Access Entries, Pod Identity Addon, and `t3.medium` (`min=2, max=4`) IMDSv2 Launch Template. |
| **`AGK-4`** | `[EKS-INGRESS]` AWS ALB Controller | To Do | `environments/dev/helm.tf` | Helm release deploys `aws-load-balancer-controller` in `kube-system` using IAM ServiceAccount. |
| **`AGK-5`** | `[EKS-GITOPS]` 3-Tier K8s + HPA + ArgoCD | To Do | `k8s/`, `.github/workflows/` | Manifests for UI, FastAPI Backend, HPA (`2-6` pods), Ingress (`alb`), ArgoCD `Application`, and CI/CD pipelines. |
