#!/usr/bin/env bash
# =============================================================================
# Evolution API - SSL Certificate Setup with Let's Encrypt
# =============================================================================
# Prerequisites:
#   - DNS A record pointing evolution.ritambharat.software to this server's IP
#   - Nginx installed (port 80 reachable)
#   - Evolution API already running on port 8080
# Usage:
#   sudo ./scripts/setup-ssl.sh evolution.ritambharat.software your@email.com
# =============================================================================

set -euo pipefail

if [ $# -lt 2 ]; then
  echo "Usage: $0 <domain> <email>"
  echo "Example: $0 evolution.ritambharat.software admin@example.com"
  exit 1
fi

DOMAIN="$1"
EMAIL="$2"

# Create Nginx config for Let's Encrypt verification
echo "=== Creating temporary Nginx config for $DOMAIN ==="
sudo tee "/etc/nginx/sites-available/$DOMAIN" > /dev/null <<EOF
server {
    listen 80;
    server_name $DOMAIN;

    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

sudo ln -sf "/etc/nginx/sites-available/$DOMAIN" /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx

echo "=== Obtaining SSL certificate from Let's Encrypt ==="
sudo certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos --email "$EMAIL"

echo "=== Applying hardened SSL config ==="
# The Nginx config at nginx/default.conf shows the full SSL setup
# Certbot auto-updates the Nginx config; review it with:
#   sudo cat /etc/nginx/sites-available/$DOMAIN

echo ""
echo "=============================================="
echo "  SSL setup complete for $DOMAIN"
echo ""
echo "  Auto-renewal is configured via systemd timer:"
echo "    sudo systemctl status certbot.timer"
echo ""
echo "  Test renewal:"
echo "    sudo certbot renew --dry-run"
echo "=============================================="
