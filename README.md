
---

# CoBank Cloud Platform

**End-to-End Cloud-Native Deployment with Terraform, Ansible, EKS & GitOps**

---

## 📌 Overview

**CoBank Cloud Platform** is a production-style **cloud-native application** deployed on **AWS EKS**, leveraging **Terraform** for infrastructure provisioning, **Ansible** for automated build and deployment, and **ArgoCD** for GitOps-driven continuous delivery.

This project demonstrates:

* Infrastructure as Code (IaC) best practices
* Secure, immutable container builds with scanning
* Kubernetes-based deployments
* GitOps workflow automation
* End-to-end CI/CD on AWS

> Designed as a **real-world demo platform**, it showcases modern DevOps, cloud-native, and GitOps practices.

---

## 🖥️ Step 0: Local Deployment & Testing (Optional)

Run and test the application **locally without AWS**:

### 1. Prerequisites

* Docker & Docker Compose
* Python 3.10+
* Minikube or kind (optional, for Kubernetes testing)
* kubectl

### 2. Build and Run with Docker Compose

```bash
docker-compose build
docker-compose up
```

*Frontend:* [http://localhost:3000](http://localhost:3000)
*Backend:* [http://localhost:5000](http://localhost:5000)

> Docker Compose simulates the deployed environment locally.

### 3. Run Kubernetes Locally (Optional)

1. Start a local cluster:

```bash
minikube start
```

2. Configure kubectl:

```bash
kubectl config use-context minikube
```

3. Apply manifests:

```bash
kubectl apply -f k8s/
```

4. Check pods & services:

```bash
kubectl get pods
kubectl get svc
```

5. Access frontend via NodePort:

```bash
minikube service frontend
```

### 4. Test Application

* Verify frontend and backend endpoints.
* Optional: run backend tests:

```bash
cd apps/backend
pytest
```

> Local deployment is ideal for **fast iteration and testing** before cloud deployment.

---

## 🧱 Architecture (High-Level)

```
Developer
   |
   v
GitHub Repo
   |
   v
CI/CD Pipeline (Jenkins / GitHub Actions)
   |
   +--> Terraform → AWS VPC + EKS
   |
   +--> Ansible → Build, Scan, Push Images
   |
   v
Amazon ECR
   |
   v
EKS Cluster
   |
   +--> ArgoCD (GitOps)
   |
   v
Frontend + Backend (Istio Ingress)
```

**Key Points:**

* Code → Pipeline → Infrastructure → Kubernetes → GitOps sync
* Immutable deployments with versioned Docker images
* Zero-trust service mesh via Istio (optional)

---

## 📂 Repository Structure

```
.
├── ansible/                # Build, scan, push, deploy automation
├── infra/terraform/        # AWS VPC + EKS provisioning
├── apps/                   # Frontend & backend code
├── k8s/                    # Kubernetes manifests
├── gitops/argo/            # ArgoCD applications
├── istio-1.28.2/           # Istio configuration
├── Jenkinsfile             # Optional Jenkins CI pipeline
├── docker-compose.yml      # Local development
└── README.md               # This file
```

---

## ✅ Prerequisites (Cloud Deployment)

Install locally:

* AWS CLI
* Terraform **>= 1.5**
* Ansible
* Docker
* kubectl
* Python 3.10+
* Trivy (optional, for image scanning)
* istioctl (optional)
* argocd CLI (optional)

Configure AWS credentials:

```bash
aws configure
```

---

## 🏗️ Step 1: Provision Infrastructure (Terraform)

```bash
cd infra/terraform
terraform init -upgrade
terraform plan -var "cluster_name=my-eks-cluster" -var "region=us-east-1"
terraform apply -var "cluster_name=my-eks-cluster" -var "region=us-east-1"
```

**Terraform provisions:**

* VPC with public & private subnets
* Internet/NAT Gateways
* EKS cluster with managed node groups
* IAM roles & security groups

---

## 🔑 Step 2: Configure kubectl for EKS

```bash
aws eks update-kubeconfig --name my-eks-cluster --region us-east-1
kubectl get nodes
```

---

## 🔧 Step 3: Ansible – Build, Scan, Push & Deploy

### 1. Setup Python Virtual Environment

```bash
python3 -m venv ansible-venv
source ansible-venv/bin/activate
pip install ansible requests docker
```

### 2. Run Ansible Playbook

```bash
cd ansible
ansible-playbook main.yml \
  -i inventory/localhost.yml \
  -e aws_region=us-east-1 \
  -e cluster_name=my-eks-cluster \
  -e app_namespace=cobank
```

**Ansible tasks include:**

1. Environment validation
2. Generate immutable image tags (Git SHA)
3. Authenticate Docker to ECR
4. Build frontend & backend images
5. Scan images with Trivy
6. Push images to ECR
7. Apply Kubernetes manifests
8. Verify pods & services

---

## 🌀 Step 4: GitOps with ArgoCD

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl apply -f gitops/argo/application.yaml
```

ArgoCD automatically:

* Watches Git repo for changes
* Syncs manifests to Kubernetes
* Reconciles drift

---

## 🌐 Step 5: Access the Application

```bash
kubectl get pods -n cobank
kubectl port-forward svc/istio-ingressgateway 8080:80 -n istio-system
```

Access frontend at: [http://localhost:8080](http://localhost:8080)

---

## 🔁 Step 6: CI/CD on AWS

**Option A: Jenkins**

* Deploy Jenkins on EC2 or EKS
* Install Docker, Terraform, Ansible, AWS CLI plugins
* Configure Multibranch Pipeline using `Jenkinsfile`

**Option B: GitHub Actions (Recommended)**

* Triggered on push
* Terraform provisions infra
* Ansible builds & pushes images
* ArgoCD syncs cluster

---

## 🔄 Full End-to-End Flow

```text
Git Push
   ↓
CI/CD Pipeline
   ↓
Terraform → AWS Infra
   ↓
Ansible → Build & Push Images
   ↓
ECR
   ↓
EKS
   ↓
ArgoCD (GitOps)
   ↓
Running Application
```

---

## 🧹 Cleanup

```bash
cd infra/terraform
terraform destroy -var "cluster_name=my-eks-cluster" -var "region=us-east-1"
```

---

## 🛡️ Best Practices Applied

* Immutable Docker images
* Git-based versioning & auditability
* Infrastructure as Code
* GitOps deployment model
* Security scanning (Trivy)
* Separation of infrastructure & application layers

---

## 📌 Summary

This repository demonstrates a **real-world AWS production workflow**, combining:

* **Terraform** → Infrastructure
* **Ansible** → Build & Deploy
* **Kubernetes** → Runtime
* **ArgoCD** → GitOps
* **Jenkins/GitHub Actions** → CI/CD

It is designed to be **scalable, auditable, secure, and cloud-native**, with optional **local testing for faster development**.

---

