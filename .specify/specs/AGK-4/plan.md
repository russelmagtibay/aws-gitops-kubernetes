# Technical Blueprint & Implementation Plan: AGK-4

| Attribute | Details |
| :--- | :--- |
| **Jira Issue Key** | [AGK-4](https://rjcloudev.atlassian.net/browse/AGK-4) |
| **Parent Epic** | `[EPIC-ING] Cloud-Native Layer-7 Ingress & Traffic Routing` |
| **Components** | `modules/alb_controller/`, `environments/dev/helm.tf`, `environments/dev/providers.tf` |
| **Target AWS Region** | `ap-southeast-1` |

---

## 1. Files & Modules Affected

1. **`environments/dev/providers.tf`**:
   - Configure the `helm` provider with Kubernetes credentials dynamically derived from `module.eks`:
     - `host = module.eks.cluster_endpoint`
     - `cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)`
     - `token = data.aws_eks_cluster_auth.this.token`
2. **`modules/alb_controller/`**:
   - `variables.tf`: `cluster_name`, `vpc_id`, `aws_region`, `alb_controller_role_arn`, `chart_version`
   - `main.tf`:
     - `aws_eks_pod_identity_association`: Binds `kube-system:aws-load-balancer-controller` to `var.alb_controller_role_arn`.
     - `helm_release`: Deploys `aws-load-balancer-controller` from `https://aws.github.io/eks-charts` into `kube-system`.
   - `outputs.tf`: `helm_release_status`, `helm_release_version`
3. **`environments/dev/helm.tf`**:
   - Instantiate `module.alb_controller` passing cluster outputs and IAM role ARN.
4. **`environments/dev/outputs.tf`**:
   - Export ALB Controller release metadata.
5. **`SPEC.md`**: Update `AGK-4` status to **Done**.

---

## 2. Ingress & Controller Traffic Routing Topology

```
+---------------------------------------------------------------------------------------------------+
| Kubernetes Ingress Controller Architecture (Direct-to-Pod IP Routing)                             |
|                                                                                                   |
|  1. Developer applies `Ingress` (ingressClassName: alb)                                            |
|                                                                                                   |
|  2. AWS Load Balancer Controller (in kube-system)                                                 |
|     - Authenticated via EKS Pod Identity (role: <project>-<env>-alb-controller-role)              |
|     - Discovers public subnets via `kubernetes.io/role/elb = "1"` tags                             |
|     - Creates Internet-Facing AWS Application Load Balancer in public subnets                     |
|     - Creates Target Group with `target-type: ip`                                                 |
|     - Registers Private Pod IPs (10.0.11.x, 10.0.12.x) directly as targets                        |
|                                                                                                   |
|  +-----------------------------+        +-----------------------------+                           |
|  | AWS Application Load Balancer| =====> | Private Pod IP (Frontend UI)|                           |
|  | (Public Subnets: 1a, 1b)     | =====> | Private Pod IP (Backend API)|                           |
|  +-----------------------------+        +-----------------------------+                           |
+---------------------------------------------------------------------------------------------------+
```

---

## 3. FinOps & Checkov Guardrails Matrix

| Guardrail ID | Objective | Implementation |
| :--- | :--- | :--- |
| **FIN-07** | On-Demand ALB Provisioning | ALB is only provisioned when an Ingress resource exists; zero idle charges during infrastructure-only sprints. |
| **FIN-08** | Single Controller Deployment | Single replica deployment with resource limits keeps cluster compute footprint minimal. |
| **SEC-10** | Workload Identity (No IAM Secret) | EKS Pod Identity mounts short-lived AWS tokens into controller pods without static credentials. |

