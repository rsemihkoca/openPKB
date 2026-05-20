#!/usr/bin/env bash
# openpkb teardown — Docker container'ları durdurur.
# Vault dosyaları silinmez, sadece runtime container'lar.
set -euo pipefail

cd "$(dirname "$0")/.."

echo "openpkb teardown"

docker compose --profile graph --profile prefetch down 2>/dev/null || true
echo "  ✓ Container'lar durduruldu"
echo ""
echo "Vault dokunulmadı. Tamamen silmek için: rm -rf vault/"
