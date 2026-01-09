# CoBank Cloud Platform

Enterprise-grade cloud-native deployment platform demonstrating:
- Secure CI/CD
- Zero-trust service mesh (Istio)
- GitOps (ArgoCD)
- Policy-driven deployments
- AWS EKS production patterns

## Architecture Highlights
- Immutable Docker images
- Trivy vulnerability scanning
- AWS ECR image registry
- Kubernetes autoscaling
- Istio ingress + traffic control
- Git commit–based versioning

## Deployment Flow
Developer → Git → Jenkins → Ansible → ECR → EKS → Istio → ArgoCD

## Prerequisites
- AWS CLI
- Docker
- Ansible
- kubectl
- Trivy
