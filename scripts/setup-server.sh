#!/usr/bin/env bash
# =============================================================================
# Evolution API - Server Setup Script
# =============================================================================
# Run this ONCE on a fresh Ubuntu 24.04 / 22.04 VPS:
#   curl -fsSL https://raw.githubusercontent.com/<YOUR_USER>/evolution/main/scripts/setup-server.sh | bash
# Or copy & run manually.
# =============================================================================

set -euo pipefail

echo "=== Updating system packages ==="
sudo apt-get update -y && sudo apt-get upgrade -y

echo "=== Installing Docker ==="
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker "$USER"

echo "=== Installing Nginx ==="
sudo apt-get install -y nginx

echo "=== Installing Certbot (Let's Encrypt) ==="
sudo apt-get install -y certbot python3-certbot-nginx

echo "=== Installing other utilities ==="
sudo apt-get install -y git curl openssl

echo ""
echo "=============================================="
echo "  Server setup complete!"
echo ""
echo "  Next steps:"
echo "  1. Log out and back in (or run: newgrp docker)"
echo "  2. Clone your repo:"
echo "     git clone https://github.com/mayankmishra0403/evolution-whatsapp-api.git /opt/evolution"
echo "  3. cd /opt/evolution && cp .env.example .env"
echo "  4. Edit .env with your domain, API key, and passwords"
echo "  5. Run: docker compose up -d"
echo "  6. Run the SSL setup: sudo ./scripts/setup-ssl.sh"
echo "=============================================="
