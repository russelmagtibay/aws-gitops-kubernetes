# Specification: AGK-1 Provision Multi-AZ EKS Networking & Subnets via Terraform

| Attribute | Details |
| :--- | :--- |
| **Jira Issue Key** | [AGK-1](https://rjcloudev.atlassian.net/browse/AGK-1) |
| **Jira Issue URL** | `https://rjcloudev.atlassian.net/browse/AGK-1` |
| **Parent Epic** | `[EPIC-NET] Zero-Trust Multi-AZ EKS Network Foundation` |
| **Epic Goal** | Establish an isolated, Checkov-compliant Multi-AZ VPC in `ap-southeast-1` using deterministic Terraform AZ-to-Subnet Mapping (`map(object)` + `for_each`) and Input `validation` Guardrails with automated Kubernetes subnet discovery tags and FinOps-optimized routing. |
| **Target AWS Region** | `ap-southeast-1` (Singapore) |
| **AWS Account ID** | `570515227299` |
| **FinOps Guardrail** | Cap spending under \$130 AWS Credits; Single NAT Gateway + free S3 Gateway VPC Endpoint |

---

## 1. User Story Statement

> **As a** Cloud Platform / DevOps Engineer,  
> **I want** to provision a dedicated Multi-AZ VPC across `ap-southeast-1a` and `ap-southeast-1b` with explicit Availability-Zone-to-subnet mapping (`for_each`) and strict input variable validation,  
> **So that** Amazon EKS worker nodes and the AWS Load Balancer Controller can auto-discover public and private subnets deterministically without race conditions or index drift, while satisfying Checkov security rules and conserving AWS credits.

---

## 2. Acceptance Criteria & Architecture Requirements

### 2.1 Deterministic Subnet Mapping (`az_subnet_map`)
- [x] Subnets MUST NOT use index-based `count`.
- [x] Subnets MUST use `for_each = var.az_subnet_map` with `map(object({ public_cidr = string, private_cidr = string }))`.
- [x] Default mapping MUST specify:
  - AZ `ap-southeast-1a`: Public `10.0.1.0/24`, Private `10.0.11.0/24`
  - AZ `ap-southeast-1b`: Public `10.0.2.0/24`, Private `10.0.12.0/24`

### 2.2 Terraform Variable Validation Guardrails
The variable `az_subnet_map` must enforce 4 non-negotiable validation blocks:
1. **Multi-AZ Minimum**: `length(var.az_subnet_map) >= 2` to guarantee high availability for EKS worker nodes and Application Load Balancers.
2. **Region & AZ Verification**: All keys must be valid `ap-southeast-1` AZ identifiers (e.g., `ap-southeast-1a`, `ap-southeast-1b`, `ap-southeast-1c`).
3. **CIDR Format Integrity**: All `public_cidr` and `private_cidr` strings must be valid IPv4 CIDRs using `can(cidrnetmask(...))`.
4. **No Subnet Collisions**: `public_cidr` and `private_cidr` within the same AZ must not be identical (`v.public_cidr != v.private_cidr`).

### 2.3 Kubernetes Subnet Auto-Discovery Tags
- Public subnets:
  - `kubernetes.io/role/elb = "1"`
  - `kubernetes.io/cluster/<cluster_name> = "shared"`
- Private subnets:
  - `kubernetes.io/role/internal-elb = "1"`
  - `kubernetes.io/cluster/<cluster_name> = "shared"`

### 2.4 Security & Checkov Compliance
- **CKV2_AWS_12**: The default VPC security group must be locked down (adopt via `aws_default_security_group` with no ingress/egress rules).
- **CKV2_AWS_11**: VPC Flow Logs must be enabled to a CloudWatch Log Group with 7-day retention and least-privilege IAM delivery role.
- **CKV_AWS_130**: `map_public_ip_on_launch` must be set to `false` for public subnets.

### 2.5 FinOps Cost Guardrails (\$130 Credit Optimization)
- Single NAT Gateway deployed in `ap-southeast-1a` to avoid the duplicate \$0.045/hr charge in AZ-b.
- Gateway VPC Endpoint for Amazon S3 (`com.amazonaws.ap-southeast-1.s3`) attached to the private route table at \$0.00 cost, routing all container image layer downloads away from the NAT Gateway.

