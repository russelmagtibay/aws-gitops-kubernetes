# Implementation & Validation Checklist: AGK-2

- [x] **Task 1: Create FinOps DynamoDB Module**
  - Path: `modules/dynamodb/` (`variables.tf`, `main.tf`, `outputs.tf`)
  - Configure `PAY_PER_REQUEST` billing mode, server-side encryption, and PITR.
  - Export table name and ARN.

- [x] **Task 2: Create Encrypted SNS Module**
  - Path: `modules/sns/` (`variables.tf`, `main.tf`, `outputs.tf`)
  - Configure KMS encryption using `alias/aws/sns`.
  - Export topic name and ARN.

- [x] **Task 3: Create 3-Tier IAM Module**
  - Path: `modules/iam/` (`variables.tf`, `main.tf`, `outputs.tf`)
  - Tier 1: EKS Cluster IAM Role with `AmazonEKSClusterPolicy`.
  - Tier 2: EKS Worker Node IAM Role with `AmazonEKSWorkerNodePolicy`, `AmazonEC2ContainerRegistryReadOnly`, `AmazonEKS_CNI_Policy`, and `AmazonSSMManagedInstanceCore`.
  - Tier 3: Workload Identity IAM Roles:
    - Backend Pod Role with trust for `pods.eks.amazonaws.com` and least-privilege scoped DynamoDB & SNS policy.
    - AWS Load Balancer Controller IAM Role with complete ALB ingress controller permissions.

- [x] **Task 4: Integrate Modules in Environment Root**
  - Path: `environments/dev/main.tf` and `environments/dev/outputs.tf`
  - Wire `module.dynamodb`, `module.sns`, and `module.iam`.
  - Export role ARNs, DynamoDB ARN, and SNS ARN.

- [x] **Task 5: Execute Automated Formatting & Validation**
  - Run `terraform fmt -recursive`.
  - Run `terraform validate` inside `environments/dev`.

- [x] **Task 6: Update Documentation & Traceability Matrix**
  - Mark checklist tasks as `[x]`.
  - Update `SPEC.md` to reflect `AGK-2` status as **Done**.
