#!/usr/bin/env bash
# =============================================================================
# Evolution API - Deploy Script
# =============================================================================
# Run this on the server after initial setup to deploy/update:
#   sudo ./scripts/deploy.sh
# =============================================================================

set -euo pipefail

REPO_DIR="/opt/evolution"

if [ ! -d "$REPO_DIR" ]; then
  echo "=== Cloning repository for the first time ==="
  git clone https://github.com/mayankmishra0403/evolution-whatsapp-api.git "$REPO_DIR"
fi

cd "$REPO_DIR"

echo "=== Pulling latest changes ==="
git pull

if [ ! -f ".env" ]; then
  echo "=== Creating .env from template ==="
  cp .env.example .env
  echo ">>> WARNING: Edit .env with your secrets before continuing! <<<"
  exit 1
fi

echo "=== Pulling latest Docker images ==="
docker compose pull

echo "=== Recreating containers with zero downtime ==="
docker compose up -d --remove-orphans

echo "=== Cleaning up old images ==="
docker image prune -f

echo ""
echo "=============================================="
echo "  Evolution API deployed successfully!"
echo "  API:     https://$(grep SERVER_URL .env | cut -d= -f2 | tr -d '\"' | tr -d "'" | tr -d ' ')"
echo "  Manager: http://localhost:3000 (SSH tunnel or VPN required)"
echo "=============================================="
