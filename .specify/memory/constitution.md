# Project Constitution — `aws-gitops-kubernetes` (`AGK`)

> **Source of Truth:** Synchronized with the Confluence Architecture Blueprint (`https://rjcloudev.atlassian.net/wiki/spaces/SCRUM/overview`) and Jira Project **`aws-gitops-kurbenates` (`AGK`)** (`https://rjcloudev.atlassian.net/jira/software/projects/AGK/boards/3`).

## 1. Architectural Principles & Non-Negotiable Guardrails
- **Cloud Provider & Region:** AWS Account `570515227299`, Region `ap-southeast-1` (Singapore).
- **Remote State Backend:** S3 Bucket `aws-gitops-platform-tfstate-570515227299`, Key `eks-gitops-platform/dev/terraform.tfstate`, native S3 state locking (`use_lockfile = true`).
- **FinOps Budget Cap (\$130 AWS Credits):**
  - Single NAT Gateway in `ap-southeast-1a` + free S3 Gateway VPC Endpoint (`com.amazonaws.ap-southeast-1.s3`).
  - EKS Control Plane on standard-support Kubernetes `1.31` (never extended support).
  - EKS Managed Node Group using `t3.medium` (`min_size = 2`, `desired_size = 2`, `max_size = 4` hard cap).
  - Validate locally via `terraform validate` / `terraform plan` during sprint development; only run `terraform apply` for end-to-end verification and tear down via `terraform destroy` immediately after.
- **Security & Compliance (Checkov / DevSecOps):**
  - Lock default VPC security group (`CKV2_AWS_12`) and enable VPC Flow Logs (`CKV2_AWS_11`).
  - Enforce IMDSv2 (`http_tokens = "required"`, `http_put_response_hop_limit = 1`) on all EC2 worker nodes.
  - Encrypt EKS Kubernetes Secrets with customer-managed KMS key (`enable_key_rotation = true`).
  - Use EKS Access Entries (`API_AND_CONFIG_MAP`) and EKS Pod Identity (`pods.eks.amazonaws.com`) / OIDC least-privilege IAM roles.

---

## 2. Jira Epics & User Stories Hierarchy (`AGK`)

Every User Story (`AGK-1` through `AGK-5`) maps to a parent **Epic** so engineering work can be validated at both the architectural capability level (Epic) and the deliverable level (User Story):

### Epic 1: `[EPIC-NET] Zero-Trust Multi-AZ EKS Network Foundation`
- **Epic Goal:** Establish an isolated, Checkov-compliant Multi-AZ VPC in `ap-southeast-1` using deterministic Terraform **AZ-to-Subnet Mapping (`map(object)` + `for_each`)** and **Input `validation` Guardrails** with automated Kubernetes subnet discovery tags and FinOps-optimized routing.
- **Linked User Story:**
  - **`AGK-1` (`https://rjcloudev.atlassian.net/browse/AGK-1`):** `[EKS-VPC] Provision Multi-AZ EKS Networking & Subnets via Terraform`
  - **Architectural Subnet & AZ Mapping Table (`az_subnet_map`):**
    | Map Key (AZ) | Public Subnet CIDR | Public EKS Role Tag | Private Subnet CIDR | Private EKS Role Tag |
    | :--- | :--- | :--- | :--- | :--- |
    | `ap-southeast-1a` | `10.0.1.0/24` | `kubernetes.io/role/elb = "1"` | `10.0.11.0/24` | `kubernetes.io/role/internal-elb = "1"` |
    | `ap-southeast-1b` | `10.0.2.0/24` | `kubernetes.io/role/elb = "1"` | `10.0.12.0/24` | `kubernetes.io/role/internal-elb = "1"` |
  - **Validation Criteria:**
    1. **Explicit Mapping (`for_each` over `map(object)`):** Never use index-based `count` for subnets; use `for_each = var.az_subnet_map` keyed by Availability Zone (`ap-southeast-1a`, `ap-southeast-1b`) so each AZ is deterministically mapped to its exact `public_cidr` and `private_cidr`.
    2. **Terraform Variable `validation` Rules:**
       - Validate `length(var.az_subnet_map) >= 2` (enforces EKS & ALB Multi-AZ minimum requirement).
       - Validate `can(cidrnetmask(...))` for all `public_cidr` and `private_cidr` blocks and ensure `public_cidr != private_cidr`.
       - Validate that all AZ keys belong to `ap-southeast-1` (`ap-southeast-1a`, `ap-southeast-1b`, `ap-southeast-1c`).
    3. **Kubernetes Auto-Discovery Tags:**
       - Public subnets (`10.0.1.0/24`, `10.0.2.0/24`) tagged with `kubernetes.io/role/elb = "1"` and `kubernetes.io/cluster/<cluster_name> = "shared"`.
       - Private subnets (`10.0.11.0/24`, `10.0.12.0/24`) tagged with `kubernetes.io/role/internal-elb = "1"` and `kubernetes.io/cluster/<cluster_name> = "shared"`.
    4. **FinOps & Security Guardrails:** Single NAT Gateway in `ap-southeast-1a` + S3 Gateway VPC Endpoint (`com.amazonaws.ap-southeast-1.s3`), Default Security Group locked (`CKV2_AWS_12`), and VPC Flow Logs enabled (`CKV2_AWS_11`).
    5. `terraform init` and `terraform validate` pass with zero errors.

### Epic 2: `[EPIC-SEC] Zero-Trust IAM & Workload Identity Architecture`
- **Epic Goal:** Enforce strict 3-tier IAM separation between the EKS Control Plane, EC2 Worker Nodes, and Kubernetes Pods using EKS Pod Identity and OIDC without static AWS keys.
- **Linked User Story:**
  - **`AGK-2` (`https://rjcloudev.atlassian.net/browse/AGK-2`):** `[EKS-IAM] Configure 3-Tier IAM Roles & EKS Pod Identity`
  - **Validation Criteria:**
    1. Tier 1 Control Plane IAM Role has `AmazonEKSClusterPolicy`.
    2. Tier 2 Worker Node IAM Role has `AmazonEKSWorkerNodePolicy`, `AmazonEC2ContainerRegistryReadOnly`, `AmazonEKS_CNI_Policy`, and `AmazonSSMManagedInstanceCore` (Zero-SSH).
    3. Tier 3 Pod IAM Role grants least-privilege `dynamodb:PutItem`, `dynamodb:GetItem`, `dynamodb:Query`, `dynamodb:Scan` on the DynamoDB leads table and `sns:Publish` on the SNS alerts topic via `pods.eks.amazonaws.com`.
    4. `terraform validate` passes with zero errors.

### Epic 3: `[EPIC-K8S] Production Amazon EKS Control Plane & Compute`
- **Epic Goal:** Provision a production-hardened Amazon EKS `1.31` cluster with KMS envelope encryption, API Access Entries, and IMDSv2-hardened `t3.medium` private worker nodes.
- **Linked User Story:**
  - **`AGK-3` (`https://rjcloudev.atlassian.net/browse/AGK-3`):** `[EKS-CORE] Deploy Amazon EKS Cluster & Managed Node Group`
  - **Validation Criteria:**
    1. EKS `1.31` Control Plane with KMS secret encryption (`enable_key_rotation = true`) and CloudWatch control plane logs (`api`, `audit`, `authenticator`).
    2. Authentication mode `API_AND_CONFIG_MAP` with `aws_eks_access_entry` (no legacy `aws-auth` ConfigMap).
    3. Managed Node Group in private subnets using `t3.medium` (`min = 2`, `desired = 2`, `max = 4`), custom Launch Template enforcing IMDSv2 (`http_tokens = "required"`, `hop_limit = 1`) and encrypted `gp3` disks.
    4. Managed addons enabled (`vpc-cni`, `coredns`, `kube-proxy`, `eks-pod-identity-agent`, `metrics-server`).
    5. `terraform validate` passes with zero errors.

### Epic 4: `[EPIC-ING] Cloud-Native Layer-7 Ingress & Traffic Routing`
- **Epic Goal:** Automate AWS Application Load Balancer (ALB) provisioning from Kubernetes `Ingress` resources with direct-to-Pod IP routing (`target-type: ip`).
- **Linked User Story:**
  - **`AGK-4` (`https://rjcloudev.atlassian.net/browse/AGK-4`):** `[EKS-INGRESS] Install AWS Load Balancer Controller via Helm`
  - **Validation Criteria:**
    1. IAM OIDC Provider and IRSA Role configured with the official AWS Load Balancer Controller IAM policy.
    2. `helm_release` resource installs `aws-load-balancer-controller` from `https://aws.github.io/eks-charts` into `kube-system`.
    3. `terraform validate` passes with zero errors.

### Epic 5: `[EPIC-K8S-APP] Cloud-Native 3-Tier Microservices & HPA Autoscaling`
- **Epic Goal:** Deploy a hardened 3-Tier application (UI + FastAPI Backend + DynamoDB/SNS) on Amazon EKS with Horizontal Pod Autoscaling (`HPA`) and zero-downtime probes.
- **Linked User Story:**
  - **`AGK-5` (`https://rjcloudev.atlassian.net/browse/AGK-5`):** `[EKS-K8S] Deploy 3-Tier Microservices & Horizontal Pod Autoscaler (HPA)`
  - **Validation Criteria:**
    1. Kubernetes manifests in `k8s/` enforce `runAsNonRoot: true`, `readOnlyRootFilesystem: true`, resource `requests`/`limits`, and `livenessProbe`/`readinessProbe`.
    2. `HorizontalPodAutoscaler` (`autoscaling/v2`) scales backend pods from `minReplicas: 2` to `maxReplicas: 6` at `70%` CPU target.
    3. Kubernetes `Ingress` (`ingressClassName: alb`, `target-type: ip`) exposes the 3-tier platform publicly via the AWS Load Balancer Controller.

### Epic 6: `[EPIC-CICD] Zero-Trust DevSecOps CI/CD & ArgoCD GitOps Delivery`
- **Epic Goal:** Automate infrastructure validation, container security scanning, ECR image publishing, and continuous GitOps cluster reconciliation using GitHub Actions OIDC and ArgoCD.
- **Linked User Story:**
  - **`AGK-6` (`https://rjcloudev.atlassian.net/browse/AGK-6`):** `[EKS-CICD] Automate Two-Speed GitHub Actions OIDC CI/CD & ArgoCD GitOps`
  - **Validation Criteria:**
    1. **Pipeline 1 (`.github/workflows/infra.yml`):** Uses AWS OIDC role assumption (no static AWS keys) to run `terraform fmt -check`, `terraform validate`, **TFLint**, and **Checkov** IaC security scans.
    2. **Pipeline 2 (`.github/workflows/app.yml`):** Runs `pytest` unit tests, builds the Docker container image, runs **Trivy** vulnerability scanning, and pushes immutable tags to Amazon ECR.
    3. **GitOps Reconciliation (`k8s/argocd-application.yaml`):** Declarative ArgoCD `Application` manifest configured with `automated: { prune: true, selfHeal: true }` synced to `https://github.com/russelmagtibay/aws-gitops-kubernetes.git`.

  - **`AGK-7` (`https://rjcloudev.atlassian.net/browse/AGK-7`):** `[EKS-ECR] Provision Amazon ECR Repositories & GitHub OIDC IAM Role via Terraform`
  - **Validation Criteria:**
    1. **Hardened ECR (`modules/ecr/`):** KMS CMK encryption (`CKV_AWS_136`), `scan_on_push = true` (`CKV_AWS_163`), `image_tag_mutability = "IMMUTABLE"` (`CKV_AWS_51`), and lifecycle retention policy (`max_image_count = 5`).
    2. **GitHub Actions OIDC Role (`modules/iam/`):** `github-actions-eks-gitops-role` trusting `token.actions.githubusercontent.com` with least-privilege ECR push and S3 state backend permissions.
    3. `terraform validate` passes with zero errors.
