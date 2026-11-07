# Implementation & Validation Checklist: AGK-1

- [x] **Task 1: Define `var.az_subnet_map` & Terraform Validation Rules**
  - Path: `modules/vpc/variables.tf`
  - Implement `az_subnet_map` (`map(object({ public_cidr = string, private_cidr = string }))`).
  - Add validation rule 1: Multi-AZ minimum (`length >= 2`).
  - Add validation rule 2: AZ key regex check (`ap-southeast-1[a-c]`).
  - Add validation rule 3: CIDR validity check (`can(cidrnetmask(...))`).
  - Add validation rule 4: Public vs Private CIDR collision check (`public_cidr != private_cidr`).
  - Add `var.nat_gateway_az` with validation ensuring key existence in `az_subnet_map`.

- [x] **Task 2: Refactor VPC Subnets and Route Tables to Deterministic `for_each`**
  - Path: `modules/vpc/main.tf`
  - Update `aws_subnet.public` to use `for_each = var.az_subnet_map`.
  - Update `aws_subnet.private` to use `for_each = var.az_subnet_map`.
  - Update `aws_nat_gateway.this` to reference `aws_subnet.public[var.nat_gateway_az].id`.
  - Update `aws_route_table_association.public` to use `for_each = aws_subnet.public`.
  - Update `aws_route_table_association.private` to use `for_each = aws_subnet.private`.

- [x] **Task 3: Update Module Outputs for Subnet Collections & Maps**
  - Path: `modules/vpc/outputs.tf`
  - Output `public_subnet_ids` as a list of strings (`[for s in aws_subnet.public : s.id]`).
  - Output `private_subnet_ids` as a list of strings (`[for s in aws_subnet.private : s.id]`).
  - Output `public_subnets` and `private_subnets` map objects for downstream module consumption.

- [x] **Task 4: Update Environment Integration & Outputs**
  - Path: `environments/dev/main.tf` and `environments/dev/outputs.tf`
  - Verify seamless module consumption without hardcoded index drift.

- [x] **Task 5: Execute Automated Formatting & Non-Destructive Validation**
  - Run `terraform fmt -recursive` across the workspace.
  - Run `terraform validate` inside `environments/dev`.

- [x] **Task 6: Update Documentation & Traceability Matrix**
  - Update `SPEC.md` to reflect `AGK-1` status as **Done**.
