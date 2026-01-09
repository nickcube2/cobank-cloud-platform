#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

log() { printf "\n%s\n" "$*"; }

log "==> Testing Docker Compose..."
cd "$ROOT_DIR"

docker compose down --remove-orphans >/dev/null 2>&1 || true
docker compose up -d --build

sleep 3
curl -fsS http://localhost:3000/api/health >/dev/null
curl -fsSI http://localhost:8080/ >/dev/null
log "✅ Docker Compose OK"

log "==> Testing kind Kubernetes..."
kind delete cluster --name cobank >/dev/null 2>&1 || true
kind create cluster --name cobank >/dev/null

docker build -t cobank-backend:dev apps/backend >/dev/null
docker build -t cobank-frontend:dev apps/frontend >/dev/null

kind load docker-image cobank-backend:dev --name cobank >/dev/null
kind load docker-image cobank-frontend:dev --name cobank >/dev/null

kubectl apply -k k8s/overlays/local >/dev/null

kubectl -n cobank rollout status deployment/backend --timeout=180s
kubectl -n cobank rollout status deployment/frontend --timeout=180s

log "✅ Kubernetes deployments rolled out"
log "==> All tests passed"
