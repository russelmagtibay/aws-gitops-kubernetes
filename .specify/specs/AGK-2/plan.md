# Technical Blueprint & Implementation Plan: AGK-2

| Attribute | Details |
| :--- | :--- |
| **Jira Issue Key** | [AGK-2](https://rjcloudev.atlassian.net/browse/AGK-2) |
| **Parent Epic** | `[EPIC-SEC] Zero-Trust IAM & Workload Identity Architecture` |
| **Components** | `modules/iam/`, `modules/dynamodb/`, `modules/sns/`, `environments/dev/` |
| **Target AWS Region** | `ap-southeast-1` |

---

## 1. Files & Modules Affected

1. **`modules/dynamodb/`**:
   - `variables.tf`: `project_name`, `environment`, `table_name`
   - `main.tf`: `aws_dynamodb_table` with `PAY_PER_REQUEST`, SSE KMS encryption, Point-in-time recovery
   - `outputs.tf`: `table_name`, `table_arn`, `table_id`
2. **`modules/sns/`**:
   - `variables.tf`: `project_name`, `environment`, `topic_name`
   - `main.tf`: `aws_sns_topic` with KMS encryption (`alias/aws/sns`)
   - `outputs.tf`: `topic_arn`, `topic_name`, `topic_id`
3. **`modules/iam/`**:
   - `variables.tf`: `project_name`, `environment`, `dynamodb_table_arn`, `sns_topic_arn`
   - `main.tf`:
     - Tier 1: `aws_iam_role.cluster` + `AmazonEKSClusterPolicy` attachment
     - Tier 2: `aws_iam_role.node` + 4 attachments (`AmazonEKSWorkerNodePolicy`, `AmazonEC2ContainerRegistryReadOnly`, `AmazonEKS_CNI_Policy`, `AmazonSSMManagedInstanceCore`)
     - Tier 3: `aws_iam_role.backend_pod` + Pod Identity trust + scoped DynamoDB/SNS least-privilege policy
     - Tier 3: `aws_iam_role.alb_controller` + ALB Controller IAM policy
   - `outputs.tf`: `cluster_role_arn`, `cluster_role_name`, `node_role_arn`, `node_role_name`, `backend_pod_role_arn`, `backend_pod_role_name`, `alb_controller_role_arn`, `alb_controller_role_name`
4. **`environments/dev/`**:
   - `main.tf`: Wire `module.dynamodb`, `module.sns`, `module.iam` into root environment.
   - `outputs.tf`: Export IAM role ARNs, DynamoDB table ARN, and SNS topic ARN.
5. **`SPEC.md`**: Update `AGK-2` status to **Done**.

---

## 2. IAM 3-Tier Security Architecture Diagram

```
+--------------------------------------------------------------------------------------------------+
| Amazon EKS 3-Tier IAM Trust Hierarchy                                                            |
|                                                                                                  |
| [Tier 1: Control Plane]                                                                          |
|   Role: <project>-<env>-eks-cluster-role                                                         |
|   Trust: eks.amazonaws.com                                                                       |
|   Attached Policy: AmazonEKSClusterPolicy                                                        |
|                                                                                                  |
| [Tier 2: EC2 Managed Node Group]                                                                 |
|   Role: <project>-<env>-eks-node-role                                                            |
|   Trust: ec2.amazonaws.com                                                                       |
|   Attached Policies:                                                                             |
|     * AmazonEKSWorkerNodePolicy                                                                  |
|     * AmazonEC2ContainerRegistryReadOnly                                                         |
|     * AmazonEKS_CNI_Policy                                                                       |
|     * AmazonSSMManagedInstanceCore  --> [Zero-SSH / Bastion-Free Debugging]                      |
|                                                                                                  |
| [Tier 3: Workload Identity (EKS Pod Identity & Controller)]                                     |
|   Role A: <project>-<env>-backend-pod-role                                                       |
|   Trust: pods.eks.amazonaws.com (sts:AssumeRole, sts:TagSession)                                 |
|   Inline Least-Privilege Policy:                                                                 |
|     - dynamodb:PutItem, GetItem, Query, Scan  --> scoped to arn:aws:dynamodb:...:table/<leads>   |
|     - sns:Publish                             --> scoped to arn:aws:sns:...:<alerts>             |
|                                                                                                  |
|   Role B: <project>-<env>-alb-controller-role                                                    |
|   Trust: pods.eks.amazonaws.com                                                                 |
|   Attached Policy: AWSLoadBalancerControllerPolicy                                               |
+--------------------------------------------------------------------------------------------------+
```

---

## 3. FinOps & Checkov Guardrails Matrix

| Guardrail ID | Objective | Implementation |
| :--- | :--- | :--- |
| **FIN-03** | Zero idle persistence cost | DynamoDB `billing_mode = "PAY_PER_REQUEST"` ($0/hr base cost). |
| **FIN-04** | Prevent secret leakage & rotation cost | EKS Pod Identity short-lived STS tokens instead of static IAM user access keys. |
| **SEC-04** | Zero-SSH Node Compliance | `AmazonSSMManagedInstanceCore` grants AWS SSM Session Manager shell access; no port 22 security groups or key pairs required. |
| **SEC-05** | Checkov `CKV_AWS_119` & `CKV_AWS_26` | DynamoDB KMS encryption enabled and Point-in-time recovery enabled. |
| **SEC-06** | Checkov `CKV_AWS_26` / SNS Encryption | SNS KMS encryption enabled via `alias/aws/sns`. |

