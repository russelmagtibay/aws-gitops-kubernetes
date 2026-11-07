# Specification: AGK-5 Deploy 3-Tier Microservices & Horizontal Pod Autoscaler (HPA)

| Attribute | Details |
| :--- | :--- |
| **Jira Issue Key** | [AGK-5](https://rjcloudev.atlassian.net/browse/AGK-5) |
| **Jira Issue URL** | `https://rjcloudev.atlassian.net/browse/AGK-5` |
| **Parent Epic** | `[EPIC-GITOPS] 3-Tier Microservices, HPA Autoscaling & ArgoCD GitOps` |
| **Epic Goal** | Deploy a production 3-Tier application (UI + FastAPI Backend + DynamoDB/SNS) with Horizontal Pod Autoscaling (HPA) and direct-to-Pod Ingress routing. |
| **Target AWS Region** | `ap-southeast-1` (Singapore) |
| **AWS Account ID** | `570515227299` |
| **FinOps Guardrail** | Pod CPU/Memory requests & limits enforced; HPA scaling bounded between 2 and 6 pods |

---

## 1. User Story Statement

> **As a** Full-Stack Cloud & DevOps Engineer,  
> **I want** to implement and deploy a 3-tier microservices application (Frontend UI, FastAPI Backend Lead Capture, and DynamoDB/SNS persistence) with Kubernetes security contexts and an HPA autoscaler,  
> **So that** customer lead submissions are securely captured and alerted with automated elastic autoscaling and high availability across the private EKS cluster subnets.

---

## 2. Acceptance Criteria & Architecture Requirements

### 2.1 Microservices Application Architecture (`app/`)
- [x] **Backend API (`app/backend/`):**
  - Python FastAPI application (`main.py`, `requirements.txt`, `Dockerfile`, `test_main.py`).
  - Endpoints:
    - `GET /health`: Health check probe endpoint returning status `healthy`.
    - `GET /api/leads`: Fetches leads from the DynamoDB leads table.
    - `POST /api/leads`: Validates lead payload (name, email, company, notes), writes to DynamoDB leads table, and publishes an SNS notification to the alerts topic.
  - Authentication: Uses AWS SDK (`boto3`) authenticated transparently via EKS Pod Identity (no hardcoded static keys).
- [x] **Frontend Web UI (`app/frontend/`):**
  - Modern responsive lead capture form (`index.html`, `nginx.conf`, `Dockerfile`).
  - Communicates with `/api/leads` seamlessly via Kubernetes Ingress path routing.

### 2.2 Kubernetes Manifests (`k8s/`)
- [x] **Namespace (`k8s/00-namespace.yaml`):** Dedicated namespace `production`.
- [x] **ServiceAccount (`k8s/01-serviceaccount.yaml`):** `backend-sa` configured for EKS Pod Identity.
- [x] **Backend Workload (`k8s/02-backend.yaml`):**
  - `Deployment`: 2 replicas, `runAsNonRoot: true`, resource `requests` (100m CPU, 128Mi RAM) and `limits` (250m CPU, 256Mi RAM).
  - Health probes: HTTP `livenessProbe` and `readinessProbe` targeting `/health`.
  - `Service`: ClusterIP routing port 80 to container port 8000.
- [x] **Frontend Workload (`k8s/03-frontend.yaml`):**
  - `Deployment`: 2 replicas, non-root security context, resource requests and limits.
  - `Service`: ClusterIP routing port 80 to container port 80.
- [x] **Horizontal Pod Autoscaler (`k8s/04-hpa.yaml`):**
  - API version: `autoscaling/v2`.
  - Scale Target: `backend` deployment.
  - Boundaries: `minReplicas: 2`, `maxReplicas: 6`.
  - Metric: Average CPU utilization target of `70%`.
- [x] **Cloud-Native Ingress (`k8s/05-ingress.yaml`):**
  - `ingressClassName: alb`.
  - Annotations: `scheme: internet-facing`, `target-type: ip`, `listen-ports: '[{"HTTP": 80}]'`.
  - Path rules: `/api` -> `backend:80`, `/` -> `frontend:80`.

### 2.3 EKS Pod Identity Workload Binding
- [x] Terraform `aws_eks_pod_identity_association` binding `production:backend-sa` to `module.iam.backend_pod_role_arn`.

### 2.4 Validation Criteria
- [x] Automated unit test suite passes for the backend microservice.
- [x] `terraform fmt -recursive` passes with zero discrepancies.
- [x] `terraform validate` in `environments/dev` passes with zero errors.

