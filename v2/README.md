# openpkb

Sen yokken senin için araştırma yapan kişisel bilgi tabanı (PKB).
Twitter-first akış, çapraz doğrulama, çelişki tespiti, scam taraması.
Sonuç Obsidian'da graph olarak hazır.

> **Durum:** İskelet hazır. `openpkb` CLI henüz yazılmadı — şu an her şey
> manuel tetikleniyor (`claude -p "/deep-research ..."`).

## Mimari (özet)

- **Claude Code** araştırma motoru. 6 subagent (researcher, verifier,
  contradiction-finder, source-trust, gap-hunter, outline-keeper) ve 4 slash komut.
- **twitterapi.io skill** — Twitter sörfü (P7 — **Twitter primary**).
- **Crawl4AI MCP** (Docker, self-hosted) — sadece Twitter'da bulunamayan
  boşlukları doldurmak için.
- **InfraNodus** (opsiyonel, Docker) — graph gap analysis.
- **Obsidian vault** — `vault/` altında, dört katman: `_raw` / `_wiki` /
  `_topics` / `_digests`. `_wiki/outline/` her konu için yapılandırılmış
  hiyerarşi (P9).

Detaylar: [`main.md`](./main.md) ve [`CLAUDE.md`](./CLAUDE.md).

## Kurulum

### Gereksinimler
- Docker + Docker Compose v2
- Node.js (twitterapi.io skill için npx)
- Claude Code CLI (`claude` komutu host'ta kurulu)
- Anthropic API anahtarı
- twitterapi.io API anahtarı

### Adımlar

```bash
git clone <bu-repo>
cd openpkb

# Bootstrap: docker pull + skill install + git init
./scripts/bootstrap.sh

# API anahtarlarını doldur
nano .env
```

`.env` içine:
```
ANTHROPIC_API_KEY=sk-ant-...
TWITTERAPI_IO_API_KEY=...
```

## Kullanım — manuel tetikleme

### 1. Konu oluştur

`_template` klasörünü kopyala:

```bash
cp -r vault/_topics/_template vault/_topics/tiktok-marketing
cd vault/_topics/tiktok-marketing
# topic.md'deki slug ve başlığı düzelt
# seeds.md'ye Twitter tohumları ekle (P7)
```

### 2. Araştırmayı başlat

```bash
claude -p "/deep-research tiktok-marketing"
```

Bu komut orchestrator olarak çalışır. Sırayla:
- Round 1: mevcut wiki'yi haritalar
- Round 2: konuyu 3-6 alt-konuya böler, plan yapar
- Round 3: paralel researcher dispatch (Twitter-first)
- Round 4: verifier → source-trust → contradiction-finder → gap-hunter
- Round 5: bulguları wiki'ye işler
- Round 6: topic.md ve state.json'ı kapatır

### 3. Yarım kalırsa devam et

Kota tükendi, hata oldu — task `in_progress`'te kalır.

```bash
claude -p "/resume-topic tiktok-marketing"
```

### 4. Günlük özet

```bash
claude -p "/morning-digest"
# vault/_digests/<bugün>.md dosyası oluşur
```

### 5. Konu listesi

```bash
claude -p "/topic-queue"
```

## Obsidian'ı aç

```bash
# Obsidian → Open vault → vault/ klasörünü seç
# Graph view ile araştırma ağını görsel olarak gez
```

### Graph view'u okumak (P9)

vault/.obsidian/graph.json ile renkler ve node boyutları önceden ayarlı:

- **Turuncu büyük node** — Outline sayfaları (`_wiki/outline/<konu>.md`).
  Her konu için **buradan başla.** Outline tüm sayfalara wikilink veriyor,
  bu yüzden doğal olarak en büyük node.
- **Mavi node'lar** — Concepts (kavram tanımları)
- **Yeşil node'lar** — Claims (doğrulanmış iddialar). **Boyut = confirmations
  + incoming wikilinks.** Büyük yeşil = ağırlığı yüksek iddia.
- **Sarı node'lar** — Open questions (gap-hunter ürünü)
- **Kırmızı node'lar** — Contradictions ve scam-suspect sources
- **Gri sönük** — `_raw/` ham kaynaklar (genelde arka planda)

### Pick-up workflow

1. Konunun outline sayfasını aç (`_wiki/outline/<konu>.md`)
2. Kategoriler **yoğunluğa göre sıralı** — yukarıdan başla
3. En yoğun kategoriyi seç → ondaki büyük node'lara odaklan
4. Hangi claim daha çok doğrulandıysa (büyük yeşil) → ona git
5. Detaya inmek için: claim sayfası → `confirming_sources` → `_raw/`

### Outline değişimi
Her `/deep-research` run'ı sonunda outline-keeper outline'ı günceller:
- Yeni sayfaları kategorilere ekler
- Confirmations değişti → işaret güncellenir
- 15+ sayfa biriktirmiş kategori → otomatik bölünür
- **Birleştirme ve ad değiştirme YOK** (wikilink kırılır)

Geçmiş outline'ları görmek için: `cd vault && git log _wiki/outline/<konu>.md`

## Felsefe

`main.md` ve `CLAUDE.md`'deki **9 tasarım prensibi** tüm kararları kısıtlar:

1. **P1** — Self-hosted/ücretsiz öncelik
2. **P2** — Token tasarrufu birinci sınıf
3. **P3** — CLI-only (Telegram yok)
4. **P4** — Tek aktif konu
5. **P5** — Resumability + kota disiplini, otomatik retry yok
6. **P6** — Selective branching (3+ doğrulanmış direktiflerin next-to'su)
7. **P7** — **Twitter PRIMARY, web sadece boşluk doldurma**, manuel tohum, min 1000 like
8. **P8** — Manuel tetikleme (openPkb CLI yazılana kadar)
9. **P9** — Outline-anchored knowledge (her konu için yapılandırılmış hiyerarşi)

## Dosya yapısı

```
openpkb/
├── CLAUDE.md                     # Anayasa (her CC oturumunda okunur)
├── main.md                       # Spec
├── README.md                     # Bu dosya
├── docker-compose.yml            # Crawl4AI + InfraNodus
├── .env.example
├── .gitignore
│
├── scripts/
│   ├── bootstrap.sh              # Kurulum
│   └── teardown.sh
│
├── .claude/
│   ├── settings.json             # MCP servers + tool izinleri
│   ├── agents/                   # 6 subagent
│   │   ├── researcher.md
│   │   ├── verifier.md
│   │   ├── contradiction-finder.md
│   │   ├── source-trust.md
│   │   ├── gap-hunter.md
│   │   └── outline-keeper.md     # YENİ (P9, M14)
│   ├── commands/                 # 4 slash command
│   │   ├── deep-research.md
│   │   ├── resume-topic.md
│   │   ├── morning-digest.md
│   │   └── topic-queue.md
│   └── skills/                   # bootstrap.sh kuruyor
│       └── twitterapi-io/        # npx skills add ile gelir
│
├── .openPkb/
│   └── soul.md                   # Gelecekteki CLI placeholder
│
└── vault/
    ├── _raw/                     # Ham kaynak (immutable)
    ├── _wiki/
    │   ├── concepts/
    │   ├── entities/
    │   ├── claims/               # confirmations alanı kritik (P6)
    │   ├── questions/
    │   ├── contradictions/
    │   ├── sources/              # Trust profilleri
    │   └── outline/              # YENİ — konu başına outline ağacı (P9)
    ├── _topics/
    │   └── _template/            # Yeni konu açarken kopyala
    ├── _digests/                 # Günlük özetler
    └── .obsidian/
        └── graph.json            # Graph view config (renkler, boyutlar)
```

## Sorun giderme

### `docker compose` çalışmıyor
Docker Compose v2 gerekli (v1 değil). `docker compose version` ile kontrol et.

### `npx skills add` hata veriyor
Node.js güncel mi (v18+)? `npm cache clean --force` deneyip tekrar dene.

### Subagent'lar tetiklenmiyor
`.claude/settings.json`'ı kontrol et — `mcpServers` ve `permissions` doğru mu?
Claude Code'un `.claude/` klasörünü gördüğünden emin ol (proje root'unda olmalı).

### Twitter rate limit
twitterapi.io 100k credits = $1. researcher subagent'ı `maxTurns: 25` ile
sınırlı. Hâlâ tüketiyorsa snowball derinliğini düşür (researcher.md'de).

### vault çöp oldu (kötü gece)
```bash
cd vault
git log --oneline
git reset --hard <önceki-commit>
```

## Roadmap

### Şu an
- ✅ İskelet repo
- ✅ 6 subagent + 4 komut
- ✅ Crawl4AI MCP + twitterapi.io skill
- ✅ Manuel tetikleme
- ✅ Twitter-PRIMARY akış (P7)
- ✅ Outline yönetimi (P9, M14)
- ✅ Obsidian graph config

### Sıradakiler
- ⏳ İlk gerçek konu testi (tiktok-marketing veya başka)
- ⏳ Cache mekanizması (P2 — şu an "siktir et" denildi, sonra eklenecek)
- ⏳ InfraNodus self-hosted test (Docker'ı aç, gap-hunter ile kullan)
- ⏳ Outline'da manuel kategori birleştirme workflow'u (sen yapıyorsun, agent değil)

### openPkb CLI (gelecek)
- ⏳ `openpkb topic add/activate/list`
- ⏳ `openpkb daemon` — scheduler
- ⏳ Doğal dil cron
- ⏳ Otomatik kota pre-check + graceful stop
