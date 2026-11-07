# Implementation & Validation Checklist: AGK-3

- [x] **Task 1: Create EKS Module Definition**
  - Path: `modules/eks/variables.tf`
  - Define inputs for `project_name`, `environment`, `vpc_id`, `private_subnet_ids`, `cluster_role_arn`, `node_role_arn`, `kubernetes_version`, `admin_principal_arn`.

- [x] **Task 2: Implement KMS & CloudWatch Resources**
  - Path: `modules/eks/main.tf`
  - KMS Customer Managed Key with rotation for Secrets encryption.
  - CloudWatch Log Group for cluster logs with 7-day retention.

- [x] **Task 3: Provision Amazon EKS 1.31 Control Plane & Access Entries**
  - Path: `modules/eks/main.tf`
  - `aws_eks_cluster` resource with version `1.31`, logging, encryption, and `API_AND_CONFIG_MAP`.
  - `aws_eks_access_entry` and `AmazonEKSClusterAdminPolicy` association.
  - EKS OIDC identity provider resource (`aws_iam_openid_connect_provider`).

- [x] **Task 4: Implement IMDSv2 Launch Template & Managed Node Group**
  - Path: `modules/eks/main.tf`
  - `aws_launch_template` with IMDSv2 (`http_tokens = "required"`, `hop_limit = 1`), encrypted `gp3` root volume.
  - `aws_eks_node_group` with `t3.medium`, private subnets, and `min=2, desired=2, max=4` guardrail.

- [x] **Task 5: Configure Managed EKS Add-ons**
  - Path: `modules/eks/main.tf`
  - Add `vpc-cni`, `coredns`, `kube-proxy`, and `eks-pod-identity-agent`.

- [x] **Task 6: Export Module Outputs & Wire Environment Root**
  - Path: `modules/eks/outputs.tf`, `environments/dev/main.tf`, `environments/dev/outputs.tf`
  - Export cluster endpoint, cluster name, CA data, and OIDC provider ARN.

- [x] **Task 7: Automated Validation & SDD Documentation Update**
  - Run `terraform fmt -recursive`.
  - Run `terraform validate` in `environments/dev`.
  - Mark tasks complete in `tasks.md` and update `SPEC.md` to **Done**.
