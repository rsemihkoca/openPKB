#!/usr/bin/env bash
# openPkb tek-tuş kurulum script'i
# Kullanım: bash setup.sh

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

ok() { echo -e "${GREEN}✓${NC} $1"; }
warn() { echo -e "${YELLOW}⚠${NC} $1"; }
fail() { echo -e "${RED}✗${NC} $1"; exit 1; }

echo "================================="
echo "openPkb setup"
echo "================================="
echo ""

# 1. Ön koşul kontrolü
echo "1. Ön koşullar kontrol ediliyor..."

command -v node >/dev/null 2>&1 || fail "Node.js bulunamadı. https://nodejs.org adresinden indir."
NODE_VERSION=$(node -v | sed 's/v//' | cut -d. -f1)
[ "$NODE_VERSION" -ge 20 ] || fail "Node.js 20+ gerekli, sende $NODE_VERSION var."
ok "Node.js $(node -v)"

command -v git >/dev/null 2>&1 || fail "Git bulunamadı."
ok "Git $(git --version | awk '{print $3}')"

command -v npm >/dev/null 2>&1 || fail "npm bulunamadı."
ok "npm $(npm -v)"

# 2. .env kontrolü
echo ""
echo "2. Environment dosyası..."

if [ ! -f .env ]; then
  cp .env.example .env
  warn ".env oluşturuldu. ŞİMDİ aç ve API key'lerini doldur:"
  warn "  nano .env"
  warn "Bittiğinde bu script'i tekrar çalıştır."
  exit 0
fi

source .env

[ -n "$TAVILY_API_KEY" ] || warn "TAVILY_API_KEY boş — web arama çalışmayacak"
[ -n "$ANTHROPIC_API_KEY" ] || warn "ANTHROPIC_API_KEY boş — Max OAuth ile bağlanacak"

# 3. Git init
echo ""
echo "3. Git repo başlatılıyor..."

if [ ! -d .git ]; then
  git init -q
  git add -A
  git commit -q -m "Initial openpkb skeleton"
  ok "Git repo oluşturuldu"
else
  ok "Git repo zaten var"
fi

# 4. Claude Code
echo ""
echo "4. Claude Code kontrol ediliyor..."

if ! command -v claude >/dev/null 2>&1; then
  echo "Claude Code yüklü değil. Şimdi yüklensin mi? [y/N]"
  read -r REPLY
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    npm install -g @anthropic-ai/claude-code
    ok "Claude Code yüklendi"
    warn "Şimdi 'claude' komutunu çalıştırıp OAuth ile bağlan."
    warn "Sonra bu script'i tekrar çalıştır."
    exit 0
  else
    warn "CC olmadan devam edilemez. Yükle ve tekrar gel."
    exit 1
  fi
else
  ok "Claude Code $(claude --version 2>/dev/null | head -1 || echo 'kurulu')"
fi

# 5. Hermes
echo ""
echo "5. Hermes Agent kontrol ediliyor..."

if ! command -v hermes >/dev/null 2>&1; then
  echo "Hermes Agent yüklü değil. Şimdi yüklensin mi? [y/N]"
  read -r REPLY
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    npm install -g hermes-agent || {
      warn "npm üzerinden Hermes yüklenemedi."
      warn "Manuel kurulum için: https://github.com/NousResearch/hermes-agent"
      exit 1
    }
    ok "Hermes yüklendi"
  else
    warn "Hermes opsiyonel — şimdilik manuel CC ile çalışabilirsin."
  fi
else
  ok "Hermes $(hermes --version 2>/dev/null | head -1 || echo 'kurulu')"
fi

# 6. Smoke test
echo ""
echo "6. Smoke test — subagent'lar görünüyor mu..."

AGENTS=$(ls .claude/agents/*.md 2>/dev/null | wc -l)
[ "$AGENTS" -eq 5 ] || fail "Sadece $AGENTS subagent bulundu, 5 olmalı"
ok "5 subagent yerinde: $(ls .claude/agents/*.md | xargs -n1 basename | sed 's/.md//' | tr '\n' ' ')"

COMMANDS=$(ls .claude/commands/*.md 2>/dev/null | wc -l)
[ "$COMMANDS" -eq 3 ] || fail "Sadece $COMMANDS slash command bulundu, 3 olmalı"
ok "3 slash command yerinde"

# 7. Vault hazır mı
echo ""
echo "7. Vault yapısı..."

for d in _raw _wiki _topics _digests; do
  [ -d "vault/$d" ] || fail "vault/$d klasörü eksik"
done
ok "Vault klasörleri yerinde"

[ -f "vault/_topics/_open_questions.md" ] || fail "Soru kuyruğu eksik"
[ -f "vault/_topics/_warnings.md" ] || fail "Uyarı kuyruğu eksik"
ok "Kuyruk dosyaları yerinde"

# 8. Sonuç
echo ""
echo "================================="
echo -e "${GREEN}Kurulum bitti.${NC}"
echo "================================="
echo ""
echo "Sıradaki adımlar:"
echo ""
echo "  1. Obsidian'ı aç → 'Open folder as vault' → $(pwd)/vault"
echo "  2. vault/README.md'deki ilk-açılış adımlarını yap (graph renkleri)"
echo ""
echo "  3. İlk konu için manuel test:"
echo "     cd $(pwd)"
echo "     claude -p '/deep-research test-topic'"
echo ""
echo "  4. Gece otomasyonu için Hermes'e cron tarif et:"
echo "     hermes chat"
echo "     > 'Every night at 02:00 local time, run /topic-queue then"
echo "        /deep-research for each active topic. Stop at 06:00.'"
echo ""
echo "Detaylı dökümantasyon: README.md"
