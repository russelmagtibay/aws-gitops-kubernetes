# Technical Blueprint & Implementation Plan: AGK-1

| Attribute | Details |
| :--- | :--- |
| **Jira Issue Key** | [AGK-1](https://rjcloudev.atlassian.net/browse/AGK-1) |
| **Parent Epic** | `[EPIC-NET] Zero-Trust Multi-AZ EKS Network Foundation` |
| **Component** | `modules/vpc/` and `environments/dev/` |
| **Target AWS Region** | `ap-southeast-1` |

---

## 1. Files & Modules Affected

1. **`modules/vpc/variables.tf`**:
   - Introduce `var.az_subnet_map` (`map(object({ public_cidr = string, private_cidr = string }))`) with the 4 strict Terraform `validation` blocks.
   - Introduce `var.nat_gateway_az` (`string`, default: `"ap-southeast-1a"`) with validation ensuring it exists in `keys(var.az_subnet_map)`.
   - Deprecate/remove legacy flat lists `var.availability_zones`, `var.public_subnet_cidrs`, and `var.private_subnet_cidrs`.
2. **`modules/vpc/main.tf`**:
   - Refactor `aws_subnet.public` to `for_each = var.az_subnet_map`.
   - Refactor `aws_subnet.private` to `for_each = var.az_subnet_map`.
   - Update `aws_nat_gateway.this` subnet reference to `aws_subnet.public[var.nat_gateway_az].id`.
   - Refactor `aws_route_table_association.public` to `for_each = aws_subnet.public`.
   - Refactor `aws_route_table_association.private` to `for_each = aws_subnet.private`.
   - Retain Checkov compliance: locked `aws_default_security_group`, CloudWatch Flow Logs, and S3 Gateway Endpoint.
3. **`modules/vpc/outputs.tf`**:
   - Expose `public_subnet_ids` as `[for s in aws_subnet.public : s.id]`.
   - Expose `private_subnet_ids` as `[for s in aws_subnet.private : s.id]`.
   - Expose subnet maps `public_subnets` and `private_subnets` for downstream consumers (EKS Node Groups and Ingress).
4. **`environments/dev/main.tf` & `outputs.tf`**:
   - Wire root outputs directly to the updated VPC module outputs.
5. **`SPEC.md`**:
   - Update status of `AGK-1` to **Done** once validation succeeds.

---

## 2. Resource Topology Diagram

```
+---------------------------------------------------------------------------------------------------+
| AWS VPC: 10.0.0.0/16 (Default SG Locked - CKV2_AWS_12, Flow Logs - CKV2_AWS_11)                  |
|                                                                                                   |
|  [Availability Zone: ap-southeast-1a]                     [Availability Zone: ap-southeast-1b]    |
|  +--------------------------------------------+          +------------------------------------+   |
|  | Public Subnet: 10.0.1.0/24                 |          | Public Subnet: 10.0.2.0/24         |   |
|  | Tag: kubernetes.io/role/elb = "1"          |          | Tag: kubernetes.io/role/elb = "1"  |   |
|  | [Single NAT Gateway] + [EIP]               |          |                                    |   |
|  +--------------------------------------------+          +------------------------------------+   |
|         |                     |                                      |                            |
|         v                     v                                      v                            |
|  +--------------------------------------------+          +------------------------------------+   |
|  | Private Subnet: 10.0.11.0/24               |          | Private Subnet: 10.0.12.0/24       |   |
|  | Tag: kubernetes.io/role/internal-elb = "1" |          | Tag: kubernetes.io/role/internal-elb|  |
|  | EKS Worker Nodes (t3.medium)               |          | EKS Worker Nodes (t3.medium)       |   |
|  | Outbound default route -> NAT Gateway (1a) |          | Outbound default route -> NAT (1a) |   |
|  +--------------------------------------------+          +------------------------------------+   |
|                                                                                                   |
|  +---------------------------------------------------------------------------------------------+  |
|  | S3 Gateway VPC Endpoint: com.amazonaws.ap-southeast-1.s3 ($0.00 / Free Tier ECR Pulls)       |  |
|  +---------------------------------------------------------------------------------------------+  |
+---------------------------------------------------------------------------------------------------+
```

---

## 3. FinOps & Checkov Guardrails Matrix

| Guardrail ID | Objective | Implementation |
| :--- | :--- | :--- |
| **FIN-01** | Avoid multi-NAT egress charges | Single NAT Gateway in `ap-southeast-1a` saving ~$32.85/month. |
| **FIN-02** | Zero-cost S3 / ECR data transfer | S3 Gateway Endpoint attached to the private route table. |
| **SEC-01** | Checkov `CKV2_AWS_12` | `aws_default_security_group` resource defined with no ingress/egress. |
| **SEC-02** | Checkov `CKV2_AWS_11` | `aws_flow_log` sending to CloudWatch with least-privilege IAM policy. |
| **SEC-03** | Checkov `CKV_AWS_130` | `map_public_ip_on_launch = false` across all public subnets. |

