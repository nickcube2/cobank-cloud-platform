# 🏦 CoBank Cloud Platform

> **End-to-end cloud-native platform demonstrating a full banking workload deployment pipeline — from local dev to production AWS EKS — with GitOps, service mesh, and observability built in.**

[![Terraform](https://img.shields.io/badge/IaC-Terraform-623CE4.svg)](https://www.terraform.io/)
[![Kubernetes](https://img.shields.io/badge/Orchestration-Kubernetes-326CE5.svg)](https://kubernetes.io/)
[![ArgoCD](https://img.shields.io/badge/GitOps-ArgoCD-EF7B4D.svg)](https://argoproj.github.io/cd/)
[![Istio](https://img.shields.io/badge/ServiceMesh-Istio-466BB0.svg)](https://istio.io/)
[![Prometheus](https://img.shields.io/badge/Monitoring-Prometheus-E6522C.svg)](https://prometheus.io/)
[![Ansible](https://img.shields.io/badge/Automation-Ansible-EE0000.svg)](https://www.ansible.com/)

---

## 💡 What This Demonstrates

A production-grade cloud platform architecture aligned with banking infrastructure requirements — observability-first, GitOps-driven, and compliant-ready. Built to show the full deployment lifecycle from a developer's laptop to AWS EKS.

> Designed to reflect the operational and regulatory expectations of financial services engineering teams.

---

## 🏗️ Architecture

```
Local Dev (Docker Compose)
        │
        ▼
Local Kubernetes (kind / minikube)
        │
        ▼
AWS Cloud (Terraform → ECR → EKS)
        │
   ┌────┴────────────────────────┐
   │                             │
   ▼                             ▼
ArgoCD (GitOps CD)          Istio (Ingress + Service Mesh)
   │                             │
   ▼                             ▼
EKS Workloads              Frontend / Backend Services
        │
        ▼
Prometheus + Grafana (Observability)
```

---

## ✨ Stack

| Layer | Technology |
|-------|-----------|
| **Local Dev** | Docker Compose |
| **Local K8s** | kind / minikube |
| **Cloud Infra** | Terraform (VPC + EKS + ECR) |
| **CI/CD** | Ansible (build → scan → push → deploy) |
| **GitOps** | ArgoCD |
| **Service Mesh** | Istio (ingress routing) |
| **Monitoring** | Prometheus + Grafana |
| **Security Scanning** | Trivy (HIGH/CRITICAL image scan) |
| **Container Registry** | AWS ECR |

---

## 🚀 Quick Start

### Prerequisites

**Local:**
- Docker Desktop
- `kubectl`
- `kind` (recommended) or `minikube`

**AWS:**
- AWS CLI (`aws configure`)
- Terraform >= 1.5
- Ansible

**Optional:** Trivy, `istioctl`, `argocd` CLI

---

### Fastest Path — Smoke Test

```bash
chmod +x scripts/smoke-test.sh
./scripts/smoke-test.sh
```

Validates Docker Compose + local Kubernetes in one pass. If it ends with **"All tests passed"** — you're good.

---

## 1️⃣ Local Development (Docker Compose)

```bash
docker compose up --build
```

| Service | URL |
|---------|-----|
| Frontend | http://localhost:8080 |
| Backend health | http://localhost:3000/api/health |

```bash
docker compose down   # stop
```

---

## 2️⃣ Local Kubernetes (kind)

```bash
# Create cluster
kind create cluster --name cobank

# Build images
docker build -t cobank-backend:dev apps/backend
docker build -t cobank-frontend:dev apps/frontend

# Load into kind (prevents ImagePullBackOff)
kind load docker-image cobank-backend:dev --name cobank
kind load docker-image cobank-frontend:dev --name cobank

# Deploy
kubectl apply -k k8s/overlays/local
kubectl -n cobank get pods

# Access (two terminals)
kubectl -n cobank port-forward svc/backend 3000:3000
kubectl -n cobank port-forward svc/frontend 8080:80
```

**Expected:** `backend-*` and `frontend-*` both Running.

---

## 3️⃣ AWS Deployment (Terraform → ECR → EKS → ArgoCD)

### Provision Infrastructure
```bash
cd terraform
terraform init && terraform apply
aws eks update-kubeconfig --name cobank-eks --region us-east-1
kubectl get nodes
```

### Build & Push to ECR (Ansible)
```bash
ansible-playbook ansible/playbook.yml
```
Ansible handles: image tagging → ECR login → Docker build → Trivy scan → ECR push → K8s manifest apply.

### GitOps Delivery (ArgoCD)
```bash
# Install ArgoCD (one-time)
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Deploy applications
kubectl apply -f gitops/argo/application-istio.yaml
kubectl apply -f gitops/argo/application-base.yaml
```

---

## 📊 Observability

The monitoring stack follows patterns used in regulated financial environments — observability as a first-class concern, not an afterthought.

### Local (Docker)
```bash
docker compose -f monitoring/docker-compose.monitoring.yml up
```

| Tool | URL | Credentials |
|------|-----|-------------|
| Prometheus | http://localhost:9090 | — |
| Grafana | http://localhost:3001 | admin / admin |

### Kubernetes
```bash
kubectl apply -f monitoring/k8s/namespace.yaml
kubectl apply -f monitoring/k8s/prometheus/
kubectl apply -f monitoring/k8s/grafana/
```

### Backend Metrics (Prometheus-compatible)
Endpoint: `/metrics`

- HTTP request rate
- Request latency (p95)
- Process CPU usage
- Node.js heap usage
- Pod availability indicators

```bash
# Validate monitoring
./scripts/smoke-test-monitoring.sh
```

---

## 🌍 Environments

| Environment | Overlay | Image Tag |
|-------------|---------|-----------|
| Local K8s | `k8s/overlays/local` | `cobank-*:dev` (kind-loaded) |
| AWS Dev | `k8s/overlays/dev` | ECR `:dev` |
| AWS Prod | `k8s/overlays/prod` | ECR `:prod` |

---

## 🧹 Cleanup

```bash
# Local
kubectl delete -k k8s/overlays/local || true
kind delete cluster --name cobank || true

# AWS
cd terraform && terraform destroy
```

---

## 🔧 Troubleshooting

| Issue | Cause | Fix |
|-------|-------|-----|
| `ImagePullBackOff` on kind | Image not loaded into kind runtime | `kind load docker-image cobank-backend:dev --name cobank` |
| Frontend `CrashLoopBackOff` | nginx permission error (read-only FS) | Already fixed in `k8s/base/frontend-deployment.yaml` via emptyDir mounts |
| Port-forward "connection refused" | Pod not ready | `kubectl -n cobank wait --for=condition=ready pod -l app=frontend --timeout=120s` |

---

## 👤 Author

**Nicholas Awuni** — Senior DevOps / Cloud Engineer  
AWS Certified Solutions Architect | HashiCorp Terraform Associate

[![LinkedIn](https://img.shields.io/badge/LinkedIn-Nicholas%20Awuni-0077B5?style=flat&logo=linkedin)](https://www.linkedin.com/in/nicholas-awuni-6018041b1/)
[![GitHub](https://img.shields.io/badge/GitHub-nickcube2-181717?style=flat&logo=github)](https://github.com/nickcube2)
