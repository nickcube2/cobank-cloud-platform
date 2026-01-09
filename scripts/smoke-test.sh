#!/usr/bin/env bash
set -euo pipefail

echo "==> Testing Docker Compose..."
docker compose down --remove-orphans >/dev/null 2>&1 || true
docker compose up -d --build

sleep 2
curl -fsS http://localhost:3000/api/health >/dev/null
curl -fsSI http://localhost:8080/ >/dev/null
echo "✅ Docker Compose OK"

echo "==> Testing kind Kubernetes..."
kind delete cluster --name cobank >/dev/null 2>&1 || true
kind create cluster --name cobank >/dev/null

docker build -t cobank-backend:dev apps/backend >/dev/null
docker build -t cobank-frontend:dev apps/frontend >/dev/null

kind load docker-image cobank-backend:dev --name cobank >/dev/null
kind load docker-image cobank-frontend:dev --name cobank >/dev/null

kubectl apply -k k8s/overlays/local >/dev/null

kubectl -n cobank rollout status deploy/backend --timeout=120s
kubectl -n cobank rollout status deploy/frontend --timeout=120s
echo "✅ Kubernetes deployments rolled out"

echo "==> All tests passed"
