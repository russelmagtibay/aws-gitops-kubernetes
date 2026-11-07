# Implementation & Validation Checklist: AGK-5

- [x] **Task 1: Build FastAPI Backend Microservice**
  - Path: `app/backend/` (`main.py`, `requirements.txt`, `test_main.py`, `Dockerfile`)
  - Implement `/health`, `GET /api/leads`, and `POST /api/leads` with DynamoDB & SNS integration.
  - Implement Dockerfile with multi-stage non-root build (`USER 10001`).

- [x] **Task 2: Build Responsive Frontend Web UI**
  - Path: `app/frontend/` (`index.html`, `nginx.conf`, `Dockerfile`)
  - Implement modern lead capture form and responsive leads table.
  - Implement unprivileged Nginx Dockerfile.

- [x] **Task 3: Create Kubernetes Manifests**
  - Path: `k8s/`
  - `00-namespace.yaml`: Namespace `production`.
  - `01-serviceaccount.yaml`: ServiceAccount `backend-sa`.
  - `02-backend.yaml`: Backend Deployment (probes, non-root, resources) + ClusterIP Service.
  - `03-frontend.yaml`: Frontend Deployment + ClusterIP Service.
  - `04-hpa.yaml`: HorizontalPodAutoscaler `autoscaling/v2` (min 2, max 6, 70% CPU).
  - `05-ingress.yaml`: ALB Ingress with `target-type: ip` and path routing.

- [x] **Task 4: Bind Backend Workload Identity in Terraform**
  - Path: `environments/dev/main.tf`
  - Add `aws_eks_pod_identity_association` linking `production:backend-sa` to `module.iam.backend_pod_role_arn`.

- [x] **Task 5: Execute Automated Validation & SDD Documentation Update**
  - Verify backend test coverage (`test_main.py`).
  - Run `terraform fmt -recursive`.
  - Run `terraform validate` in `environments/dev`.
  - Mark tasks complete in `tasks.md` and update `SPEC.md` to **Done**.
