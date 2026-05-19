#!/usr/bin/env bash
# openpkb bootstrap — projeyi kurar, bağımlılıkları yükler.
# Kullanım: ./scripts/bootstrap.sh
set -euo pipefail

cd "$(dirname "$0")/.."
ROOT="$(pwd)"

echo "=========================================="
echo "openpkb bootstrap"
echo "Root: $ROOT"
echo "=========================================="

# 1. Ön kontroller
echo ""
echo "[1/5] Ön kontroller..."

if ! command -v docker >/dev/null 2>&1; then
  echo "HATA: docker bulunamadı. https://docs.docker.com/engine/install/ kur."
  exit 1
fi

if ! docker compose version >/dev/null 2>&1; then
  echo "HATA: 'docker compose' bulunamadı. Docker Compose v2 gerekli."
  exit 1
fi

if ! command -v claude >/dev/null 2>&1; then
  echo "UYARI: 'claude' CLI bulunamadı. https://docs.claude.com/en/docs/claude-code"
  echo "        kurulumu yapılmadan headless tetikleme çalışmaz."
fi

if ! command -v npx >/dev/null 2>&1; then
  echo "HATA: npx bulunamadı. Node.js kur (twitterapi.io skill için gerekli)."
  exit 1
fi

echo "  ✓ docker, docker compose mevcut"

# 2. .env dosyası
echo ""
echo "[2/5] .env kontrolü..."

if [ ! -f .env ]; then
  cp .env.example .env
  echo "  ✓ .env oluşturuldu (.env.example'dan)"
  echo "  ! .env'i aç ve API anahtarlarını doldur:"
  echo "      - ANTHROPIC_API_KEY"
  echo "      - TWITTERAPI_IO_API_KEY"
else
  echo "  ✓ .env mevcut"
fi

# 3. twitterapi.io skill kurulumu
echo ""
echo "[3/5] twitterapi.io skill kurulumu..."

if [ ! -d .claude/skills/twitterapi-io ]; then
  npx -y skills add kaitoInfra/twitterapi-io
  echo "  ✓ twitterapi.io skill yüklendi: .claude/skills/twitterapi-io/"
else
  echo "  ✓ twitterapi.io skill zaten yüklü"
fi

# 4. Docker image pre-pull (Crawl4AI MCP)
echo ""
echo "[4/5] Crawl4AI MCP image pre-pull..."
docker pull uysalsadi/crawl4ai-mcp-server:latest
echo "  ✓ uysalsadi/crawl4ai-mcp-server:latest hazır"

# 5. Vault git init
echo ""
echo "[5/5] Vault git kontrolü..."

if [ ! -d vault/.git ]; then
  (
    cd vault
    git init -q
    git add -A
    git commit -qm "openpkb: initial vault" || true
  )
  echo "  ✓ vault git init edildi (P5 S6 — geri alınabilirlik)"
else
  echo "  ✓ vault zaten git repo"
fi

echo ""
echo "=========================================="
echo "Kurulum tamam."
echo ""
echo "Sonraki adımlar:"
echo "  1. .env içindeki API anahtarlarını doldur"
echo "  2. vault/_topics/<konu>/seeds.md dosyana Twitter tohumları ekle"
echo "  3. Konuyu başlat:  claude -p '/deep-research <konu-slug>'"
echo ""
echo "Komutlar:"
echo "  /deep-research <slug>   — yeni araştırma"
echo "  /resume-topic <slug>    — in_progress task'ı devam ettir"
echo "  /topic-queue            — konuları listele"
echo "  /morning-digest         — günlük özet"
echo ""
echo "InfraNodus (opsiyonel, graph gap analysis):"
echo "  docker compose --profile graph up -d"
echo "=========================================="
