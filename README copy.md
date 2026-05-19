# openPkb — Personal Knowledge Brain

Geceleri çalışan, otonom araştırma yapan, çelişkileri tartan, boşlukları
soru olarak açan, Obsidian'a graph şeklinde kaydeden kişisel bilgi sistemi.

**Mimari:** openPkb (scheduler) → Claude Code (orchestrator) →
5 subagent (researcher / verifier / contradiction-finder / gap-hunter /
source-trust) → Obsidian vault (LLM Wiki pattern).

---

## Ön koşullar

İndirmen gereken şeyler (sırayla):

1. **Node.js 20+** — `node -v` ile kontrol et. Yoksa: https://nodejs.org
2. **Git** — `git --version`. Mac/Linux'ta zaten var. Windows için git-scm.com
3. **Obsidian Desktop** — https://obsidian.md (ücretsiz)
4. **Bir terminal** — Mac Terminal, Windows Terminal, veya iTerm2 yeterli

API key'leri gerekenler:

5. **Anthropic API key veya Claude Max aboneliği**
   - Max abonen varsa key gerekmez, OAuth ile bağlanır
   - Yoksa: https://console.anthropic.com/ — bir key oluştur, biraz kredi yükle
6. **Tavily API key** (web arama için) — https://tavily.com — free tier var
7. **(Opsiyonel) BrowserAct API key** — Twitter/TikTok scraping için
8. **(Opsiyonel) InfraNodus API key** — graph gap analizi için

---

## Adım 1 — Repo'yu yerleştir

```bash
cd ~
# Bu paketi indirdiğin yerden:
unzip openpkb.zip
mv openpkb ~/openpkb
cd ~/openpkb

# Git init (rollback için kritik)
git init
git add -A
git commit -m "Initial openpkb skeleton"
```

## Adım 2 — Environment

`.env` dosyasını oluştur (gitignore'da olduğundan asla commit edilmez):

```bash
cp .env.example .env
nano .env
```

İçine:
```
ANTHROPIC_API_KEY=sk-ant-...      # veya boş bırak, OAuth kullan
TAVILY_API_KEY=tvly-...
BROWSERACT_API_KEY=...             # opsiyonel
INFRANODUS_API_KEY=...             # opsiyonel
```

## Adım 3 — Claude Code kurulumu

```bash
npm install -g @anthropic-ai/claude-code

# İlk auth (browser açılır):
claude

# Status doğrula:
claude auth status
```

Repo köküne gel, settings.json zaten orada olduğu için CC otomatik bulur:
```bash
cd ~/openpkb
claude  # interaktif moda gir, /agents komutu ile subagent'ların listesini gör
```

`/agents` çağırdığında 5 subagent görmen lazım: researcher, verifier,
contradiction-finder, gap-hunter, source-trust.

## Adım 4 — openPkb kurulumu

```bash
# (Repo'nun resmi kurulum talimatı değişebilir, son halini kontrol et:
# https://github.com/NousResearch/openPkb-agent)

# Tipik akış:
npm install -g openPkb-agent

# Anthropic provider'ını seç (CC credential'larını otomatik kullanır):
openPkb model
# → Anthropic OAuth seç

# Çalışma dizinini openpkb yap:
cd ~/openpkb
openPkb init --soul .openPkb/soul.md
```

## Adım 5 — MCP server'ları test

```bash
# Tavily çalışıyor mu:
cd ~/openpkb
claude -p "Use the tavily MCP to search for 'tiktok algorithm 2026' and report the top 3 results."

# Hata almıyorsan ✓
```

## Adım 6 — Obsidian'ı vault'a yönlendir

1. Obsidian'ı aç
2. "Open folder as vault"
3. `~/openpkb/vault/` klasörünü seç
4. `README.md` açılır, oradaki ilk açılış adımlarını izle (graph grupları,
   Dataview plugin)

## Adım 7 — Cron job'larını kur

```bash
# openPkb'e doğal dilden cron tarif et:
openPkb chat
> "Every night at 02:00 local time, run /topic-queue to get the
>  prioritized list, then for each active topic call /deep-research
>  with that topic's slug. Stop at 06:00 even if not all done."

# openPkb onaylayıp ~/.openPkb/cron/jobs.json'a yazacak.
# Doğrula:
openPkb cron list
```

## Adım 8 — İlk test

```bash
cd ~/openpkb

# Manuel olarak küçük bir konu aç:
cat > vault/_topics/test-topic.md << 'EOF'
---
type: topic
slug: test-topic
status: active
priority: high
description: "test araştırma — claude code function calling best practices"
---
# Test topic
EOF

# Manuel tetikle (gece beklemeden):
claude -p "/deep-research test-topic"

# 10-15 dakika sonra vault/_wiki/ altında sayfalar göreceksin
```

## Beklenen ilk koşu çıktısı

- `_raw/` altında 5-15 yeni `.md` dosyası (toplanan kaynaklar)
- `_wiki/` altında 3-8 concept sayfası
- `_topics/_open_questions.md` içine 2-5 yeni soru
- (Belki) `_wiki/contradictions/` altında 1-2 çelişki sayfası
- `vault/_topics/test-topic.md` güncellenecek: pages_added, gaps_opened, vb.

## Sorun giderme

**"Subagent not found"** → `.claude/agents/` doğru yerde mi, `claude` repo
kökünden çalıştırılıyor mu kontrol et.

**MCP server timeout** → API key'leri .env'de doğru mu, key'in bakiyesi
var mı.

**openPkb "no jobs"** → `openPkb cron list` ile gör, yeniden tarif et.

**Vault çorba oldu** → `git reset --hard HEAD~N` ile geri al. Bu yüzden
git başlangıçta init edildi.

## Maliyet

- Bir orta-boyut konu (deep-research tek koşu) ≈ 8-15 cent
- Gece 5 aktif konu × 1 koşu ≈ $0.40-0.75/gün
- Aylık tahmin: $15-25 API gideri (Max aboneliğin yoksa)

`--max-budget-usd 2.00` job başına default sınır. Üzerine çıkmaz.

## Sonraki adımlar

- Telegram bot bağla: `openPkb connect telegram <BotFather-token>`
- Daha fazla subagent ekle: `.claude/agents/` altına yeni .md
- InfraNodus plugin'i Obsidian'a yükle, graph gap analizi açılır
