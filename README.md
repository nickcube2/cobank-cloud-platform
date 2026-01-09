# CoBank Cloud Platform

An end‑to‑end, cloud‑native sample platform showing **Local Dev → Kubernetes → AWS EKS** with:

- **Docker Compose** for fast local iteration
- **Kubernetes (kind/minikube)** for local cluster testing
- **Terraform** for AWS infra (VPC + EKS + ECR)
- **Ansible** to build/scan/push images and deploy
- **ArgoCD** for GitOps continuous delivery
- **Istio** for ingress routing

This repo is designed to align with the **CoBank Cloud Platform Deployment Flow** diagram (see `Cobank-architectural diagram.png`).


---

## Prerequisites

### Local (Docker / kind)
- Docker Desktop
- `kubectl`
- `kind` (recommended) or `minikube`

### AWS
- AWS CLI (`aws configure`)
- Terraform >= 1.5
- Ansible

Optional:
- Trivy
- `istioctl`
- `argocd` CLI

---

## Smoke Test (Recommended)

The quickest way to verify the repo works **both locally and on Kubernetes** is to run the smoke test:

```bash
chmod +x scripts/smoke-test.sh
./scripts/smoke-test.sh
```

What it does:

- Runs **Docker Compose** (build + start), then checks:
  - Backend: `http://localhost:3000/api/health`
  - Frontend: `http://localhost:8080/`
- Recreates a **kind** cluster named `cobank`, then:
  - Builds `cobank-backend:dev` and `cobank-frontend:dev`
  - Loads images into kind (prevents `ImagePullBackOff`)
  - Applies `k8s/overlays/local`
  - Waits for `backend` and `frontend` rollouts

If it finishes with “All tests passed”, you’re good to go.


---

# 1) Local Development (Docker Compose)

Fastest way to run everything locally.

```bash
docker compose up --build
```

- Frontend: http://localhost:8080
- Backend health: http://localhost:3000/api/health

Stop:
```bash
docker compose down
```

---

# 2) Local Kubernetes (kind / minikube)

This path is **the closest to production** without AWS.

## 2.1 Create a local cluster

### kind (recommended)
```bash
kind create cluster --name cobank
kubectl cluster-info
```

### minikube
```bash
minikube start
kubectl config use-context minikube
```

## 2.2 Build images locally

```bash
docker build -t cobank-backend:dev apps/backend
docker build -t cobank-frontend:dev apps/frontend
```

## 2.3 (kind only) Load images into the cluster

> This is the #1 cause of **ImagePullBackOff** on kind.

```bash
kind load docker-image cobank-backend:dev --name cobank
kind load docker-image cobank-frontend:dev --name cobank
```

Verify the node can see them:
```bash
docker exec -it cobank-control-plane crictl images | grep cobank || true
```

## 2.4 Deploy using the local overlay

```bash
kubectl apply -k k8s/overlays/local
kubectl -n cobank get pods
```

Expected:
- `backend-*` Running
- `frontend-*` Running

## 2.5 Access the services (port-forward)

Terminal 1:
```bash
kubectl -n cobank port-forward svc/backend 3000:3000
```

Terminal 2:
```bash
kubectl -n cobank port-forward svc/frontend 8080:80
```

Test:
```bash
curl -i http://localhost:3000/api/health
curl -I http://localhost:8080/
```

---

## Local Kubernetes Troubleshooting (the issues we hit)

### A) `ImagePullBackOff` on kind
Cause: the image exists in Docker Desktop but **not inside kind’s node runtime**.

Fix:
```bash
kind load docker-image cobank-backend:dev --name cobank
kind load docker-image cobank-frontend:dev --name cobank
kubectl -n cobank delete pod -l app=backend
kubectl -n cobank delete pod -l app=frontend
```

### B) Frontend `CrashLoopBackOff` / nginx permission errors
The base manifests run nginx as non-root and keep the root FS read-only; nginx needs writable cache/run dirs.

Fix: already baked into `k8s/base/frontend-deployment.yaml` via:
- emptyDir mounts: `/var/cache/nginx`, `/var/run`
- `fsGroup: 101`

### C) Port-forward “connection refused”
Cause: port-forward tries to connect to the container port; if the pod isn’t ready yet, it can fail.

Fix:
```bash
kubectl -n cobank wait --for=condition=ready pod -l app=frontend --timeout=120s
kubectl -n cobank port-forward svc/frontend 8080:80
```

---

# 3) AWS Cloud Deployment (Terraform → ECR → EKS → Istio → ArgoCD)

This follows the lower half of the diagram:
- Terraform provisions AWS infra
- CI/CD (Ansible or Jenkins/GitHub Actions) builds & pushes images to ECR
- ArgoCD continuously deploys manifests into EKS
- Istio routes traffic to frontend/backend

## 3.1 Provision AWS infrastructure (Terraform)

```bash
cd terraform
terraform init
terraform apply
```

When complete, configure kubectl for the cluster:
```bash
aws eks update-kubeconfig --name cobank-eks --region us-east-1
kubectl get nodes
```

> If you changed `cluster_name` or `aws_region`, update them in `ansible/group_vars/all.yml`.

## 3.2 Build, scan, and push images to ECR (Ansible)

From repo root:

```bash
ansible-playbook ansible/playbook.yml
```

What it does (high level):
- Determines an immutable image tag from Git
- Logs into ECR
- Builds frontend/backend images
- Runs Trivy scans (HIGH/CRITICAL)
- Pushes images to ECR
- Applies Kubernetes manifests (namespace, deployments, services, HPA, Istio)

## 3.3 GitOps continuous delivery (ArgoCD)

ArgoCD apps are in:
- `gitops/argo/application-base.yaml` (deploys platform)
- `gitops/argo/application-istio.yaml` (deploys istio gateway/virtualservice)

1) Install ArgoCD (one-time):
```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

2) Apply the applications:
```bash
kubectl apply -f gitops/argo/application-istio.yaml
kubectl apply -f gitops/argo/application-base.yaml
```

> Update `repoURL` inside the ArgoCD Application manifests to your fork.

## 3.4 Access on AWS

If you expose Istio ingress (LoadBalancer), you can reach the app via the ingress external address.

Check:
```bash
kubectl -n istio-system get svc
kubectl -n cobank get svc
```

---

# 4) Environments and Image Tags

- **Local Kubernetes:** `k8s/overlays/local` → `cobank-frontend:dev`, `cobank-backend:dev` (loaded into kind)
- **AWS Dev:** `k8s/overlays/dev` → ECR images tagged `:dev`
- **AWS Prod:** `k8s/overlays/prod` → ECR images tagged `:prod`

---

# 5) Cleanup

### Local
```bash
kubectl delete -k k8s/overlays/local || true
kind delete cluster --name cobank || true
```

### AWS
```bash
cd terraform
terraform destroy
```

---

## Notes

- The diagram shows Jenkins/GitHub Actions; this repo includes a `Jenkinsfile` example and uses Ansible as the automation entrypoint.
- If you want GitHub Actions added as the CI/CD runner, we can add workflows that call the same build/push steps and then let ArgoCD sync.
