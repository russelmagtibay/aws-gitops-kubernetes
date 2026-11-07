# Technical Blueprint & Implementation Plan: AGK-5

| Attribute | Details |
| :--- | :--- |
| **Jira Issue Key** | [AGK-5](https://rjcloudev.atlassian.net/browse/AGK-5) |
| **Parent Epic** | `[EPIC-GITOPS] 3-Tier Microservices, HPA Autoscaling & ArgoCD GitOps` |
| **Components** | `app/backend/`, `app/frontend/`, `k8s/`, `environments/dev/` |
| **Target AWS Region** | `ap-southeast-1` |

---

## 1. Files & Modules Affected

1. **`app/backend/`**:
   - `main.py`: FastAPI application exposing:
     - `GET /health` (probes)
     - `GET /api/leads` (DynamoDB scan)
     - `POST /api/leads` (Pydantic validation, DynamoDB put_item, SNS publish)
   - `requirements.txt`: `fastapi`, `uvicorn`, `pydantic`, `boto3`, `pytest`, `httpx`
   - `test_main.py`: Unit tests verifying `/health` and lead creation logic
   - `Dockerfile`: Multi-stage, non-root (`USER 10001`) container image
2. **`app/frontend/`**:
   - `index.html`: Responsive Lead Capture Web UI
   - `nginx.conf`: Nginx reverse proxy configuration running non-root on port 80
   - `Dockerfile`: Multi-stage build running unprivileged Nginx
3. **`k8s/`**:
   - `00-namespace.yaml`: Namespace `production`
   - `01-serviceaccount.yaml`: ServiceAccount `backend-sa` in `production`
   - `02-backend.yaml`: Backend Deployment (2 replicas, CPU/Memory requests & limits, `runAsNonRoot: true`, liveness/readiness probes) + Service
   - `03-frontend.yaml`: Frontend Deployment (2 replicas, security contexts, probes) + Service
   - `04-hpa.yaml`: HorizontalPodAutoscaler (`autoscaling/v2`) scaling `2` to `6` replicas at `70%` CPU target
   - `05-ingress.yaml`: Ingress (`ingressClassName: alb`) with direct-to-Pod IP routing (`target-type: ip`)
4. **`environments/dev/main.tf`**:
   - Add `aws_eks_pod_identity_association` binding `production:backend-sa` to `module.iam.backend_pod_role_arn`.
5. **`SPEC.md`**: Update `AGK-5` status to **Done**.

---

## 2. 3-Tier Application & Autoscaling Architecture

```
+---------------------------------------------------------------------------------------------------+
| Kubernetes Production Namespace (`production`)                                                    |
|                                                                                                   |
|  [Internet Traffic]                                                                               |
|         |                                                                                         |
|         v                                                                                         |
|  [AWS Application Load Balancer] (Target-type: IP)                                                |
|    |                                          |                                                   |
|    | / (Path)                                 | /api (Path)                                       |
|    v                                          v                                                   |
|  +-----------------------------+         +----------------------------------------------------+   |
|  | Frontend Service (Port 80)  |         | Backend Service (Port 80 -> 8000)                  |   |
|  +-----------------------------+         +----------------------------------------------------+   |
|    |                                       |                                                      |
|    v                                       v                                                      |
|  +-----------------------------+         +----------------------------------------------------+   |
|  | Frontend Pods (2 Replicas)  |         | Backend Pods (2 - 6 Replicas via HPA @ 70% CPU)    |   |
|  | - Unprivileged Nginx        |         | - FastAPI Backend (Non-Root UID 10001)             |   |
|  | - HTML5 / Tailwind Form     |         | - ServiceAccount: backend-sa                       |   |
|  +-----------------------------+         +----------------------------------------------------+   |
|                                                    |                                              |
|                                                    | Authenticated via EKS Pod Identity           |
|                                                    | (pods.eks.amazonaws.com)                     |
|                                                    v                                              |
|                                          +---------------------+    +-------------------------+   |
|                                          | DynamoDB: Leads     |    | SNS: Alerts Topic       |   |
|                                          | (PAY_PER_REQUEST)   |    | (Encrypted KMS)         |   |
|                                          +---------------------+    +-------------------------+   |
+---------------------------------------------------------------------------------------------------+
```

---

## 3. FinOps & Checkov Guardrails Matrix

| Guardrail ID | Objective | Implementation |
| :--- | :--- | :--- |
| **FIN-09** | Enforce Pod Resource Boundaries | CPU request `100m` / limit `250m`; Memory request `128Mi` / limit `256Mi` prevents node starvation. |
| **FIN-10** | Elastic HPA Bounded Ceiling | Autoscaler hard capped at `maxReplicas: 6` to remain within the 2-4 `t3.medium` cluster node budget. |
| **SEC-11** | Non-Root Pod Execution | `securityContext.runAsNonRoot: true`, `runAsUser: 10001`, `allowPrivilegeEscalation: false`. |
| **SEC-12** | Secretless Microservice Auth | Backend pod leverages EKS Pod Identity to write to DynamoDB and SNS without AWS credentials stored in secrets or environment variables. |

