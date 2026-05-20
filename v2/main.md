# openpkb — Sistem Spec'i

## Bölüm 0 — Tasarım Prensipleri

Bu prensipler tüm mimari kararları kısıtlar. Bir özellik bu prensiplerden
birini ihlal ediyorsa, ya yeniden tasarlanır ya da reddedilir.

**P1 — Self-hosted ve ücretsiz öncelik.** Paralel iki seçenek varsa
self-hosted/ücretsiz olanı seçilir.
- Web crawl: **Crawl4AI MCP** (`uysalsadi/crawl4ai-mcp-server`, Docker, free)
- Twitter: **twitterapi.io skill** (`npx skills add kaitoInfra/twitterapi-io`)
  — Twitter resmi API'sı pratik olmadığı için tek alternatif; ucuz ($1/100k credit)
- Graph analytics: **InfraNodus self-hosted** (Neo4j + Docker) — opsiyonel,
  yoksa gap-hunter grep+wikilink ile fallback
- Tavily, BrowserAct, Firecrawl gibi ücretli alternatifler **kullanılmaz**.

**P2 — Token tasarrufu birinci sınıf hedef.**
- Subagent → orchestrator akışında ham web fetch'leri **gönderilmez**.
  Subagent kendi içinde işler, sadece **unique + birden fazla kaynakta tekrar
  eden bulguları referanslarıyla** döner.
- Verifier 3+ kaynakta doğrulanmış iddiayı tekrar doğrulamaz.
- Wiki sayfaları arası okumada **frontmatter-first**: orchestrator önce
  metadata okur, gövdeyi sadece gerektiğinde açar.
- Cache mekanizması v2'ye atıldı (şimdilik aynı URL fetch'i sadece grep ile
  kontrol).

**P3 — CLI-only arayüz.** Telegram, Discord, mobil bildirim **yok**. Tüm
çıktılar dosyaya veya stdout'a. `/morning-digest` bir dosya üretir, mesaj
göndermez.

**P4 — Tek aktif konu.** Aynı anda birden fazla `status: active` veya
`in_progress` konu olamaz. Subagent paralelliği konu **içinde** geçerli,
konular arası değil.

**P5 — Resumability ve kota disiplini.**
- Her job başlamadan kota durumu kontrol edilir; yetmiyorsa hiç başlamaz.
- Job ortasında kotaya yaklaşılırsa **graceful stop**: yeni subagent dispatch
  edilmez, mevcutler bitirilir, checkpoint kaydedilir, durulur.
- Yarım kalan iş `in_progress` durumunda diskte bekler.
- **Otomatik retry yok.** Kullanıcı `/resume-topic` ile elle başlatır.
- Hata da `in_progress`'te kalır (silinmez, sen sabah görüp manuel
  müdahale edersin).
- Task durumları: `pending`, `in_progress`, `done`, `error`. **`paused` yok.**

**P6 — Selective branching ("next-to").** Sistem her boşluğu kovalamaz.
Yeni araştırma dalı sadece şu koşulda açılır:
1. Mevcut konu içinde bir direktif geçmiş olmalı (örn: "static IP kullan"),
2. O direktif **≥3 bağımsız kaynak** tarafından doğrulanmış olmalı,
3. Ancak o zaman next-to'su (örn: "en iyi static IP provider") yeni dal olur.

Konuyla ilgisiz hiçbir şey kovalanmaz. "Süngerbob metaforu" daraltıldı:
exhaustive değil, selective.

**P7 — Twitter-primary, web boşluk-doldurucu.** Twitter primary veri
kaynağı, web sadece boşluk doldurma.
- Veri (iddialar, pratikler, tanımlar) **Twitter'dan gelir**: tweet, thread,
  quote, reply
- Web (Crawl4AI) **sadece şu durumda** devreye girer:
  - Twitter'da iddiayı doğrulayacak ≥3 bağımsız hesap bulunamadı, VEYA
  - Twitter'da kavramın net açıklaması yok
- Web kaynağı ikinci sınıf. `trust_initial: medium` (Twitter `unverified`)
- `_raw/` çoğunluğu tweet/thread olmalı. %50'den fazla web ise — Twitter'da
  yeterince keşfedilmemiş demektir
- Kör keyword search yok. Kullanıcı `seeds.md`'de tohum verir, agent
  **seed-merkezli genişler** (benzer hesaplar, quote'lar, ilgili thread'ler,
  Twitter advanced search)
- Görünürlük filtresi: min **1000 like** (sabit)

**P8 — Manuel tetikleme.** Şu an scheduler/cron **yok**. Sen `claude -p
"/deep-research <konu>"` ile başlatırsın. **openPkb gelecekte yazılacak bir
CLI tool**, bu projenin adı; üzerine konumlanıp tetiklemeyi otomatikleştirecek.

**P9 — Outline-anchored knowledge.** Her konunun bir outline ağacı var:
`_wiki/outline/<konu>.md`.
- Konunun hiyerarşik görünümü (genelden özele)
- Tüm wiki sayfalarına wikilink → outline sayfası graph'ta merkezi büyük node
- Kategoriler otomatik sıralı (yoğunluk = yukarı)
- Outline değişebilir ama temkinli:
  - Ekleme + işaret güncelleme serbest
  - 15+ sayfa biriktirmiş kategori otomatik bölünür
  - **Birleştirme YASAK**, **kategori adı değiştirme YASAK** (wikilink kırar)
- Her güncelleme `revision++`. Geçmiş git history'de
- Amaç: kullanıcı graph view'i açtığında structured veriyi pick-up edebilsin

---

## Bölüm 1 — MUST'lar (M1–M13)

**M1 — Async / arka plan çalışma kapasitesi.** Şu an manuel tetikleme (P8)
ama mimari async'i destekliyor — openPkb yazıldığında zaten ekleyebilecek.

**M2 — Konu → otomatik dallandırma.** Orchestrator konuyu 3-6 alt-konuya
böler (`/deep-research` Round 2).

**M3 — Çoklu kaynak doğrulama.** Verifier her iddiayı bağımsız 2-3 domain'de
teyit eder. 3+ → "ağırlığı yüksek" (P6 eşiği).

**M4 — Karşıt görüşleri silmeden saklama.** `_wiki/contradictions/` + Obsidian
callout. Hangi koşulda hangisi geçerli işaretlenir.

**M5 — Scam / kaynak güvenilirliği taraması.** source-trust her yeni
creator/domain/hesap için profil çıkarır. `_wiki/sources/`.

**M6 — Selective gap-hunting.** P6'nın koşulunu geçen direktiflerin
next-to'su kovalanır. Süngerbob daraltıldı.

**M7 — Blocker önceliği.** Açık sorular `_open_questions.md`'de
blocker → high → nice sırasıyla.

**M8 — Obsidian graph yapısı.** `_raw` / `_wiki` / `_topics` üç katmanı,
wikilink'li, native graph view. 3D plugin yok (mecazi anlam).

**M9 — Async subagent paralellik (konu içinde).** Her subagent izole context.
Konular arası paralellik yok (P4).

**M10 — Context erime, meta kalıcı.**
- Subagent ham web'i kendi context'inde tutar.
- Orchestrator'a: **işlenmiş, unique, ağırlıklı bulgular + referanslar +
  kilit alıntılar** (CLAUDE.md'deki standart format).
- Wiki sayfaları frontmatter-first okunur.

**M11 — Twitter ve sosyal kaynak.**
- **twitterapi.io skill** (Twitter sörfü)
- Twitter-first (P7): kullanıcı tohum verir → agent thread/quote/mention
  keşfeder → min 1000 like → bulgular **Crawl4AI MCP** ile web'de doğrulanır.

**M12 — Resumability + checkpoint.**
- `_topics/<konu>/state.json` her major adımdan sonra flush.
- Plan ve subagent_results state'te.
- Job başında state.json varsa kaldığı yerden devam.

**M13 — Kota pre-check + graceful stop.**
- `/deep-research` başında kota kontrolü; yetmiyorsa hiç başlama.
- Mid-flight yaklaşırsa graceful stop, checkpoint, dur.
- Otomatik retry yok. `/resume-topic` ile elle başlat.

**M14 — Outline yönetimi.**
- `outline-keeper` subagent her `/deep-research` run'ının **en son** adımı
  olarak çalışır.
- `_wiki/outline/<konu>.md` dosyası tek source-of-truth.
- Otomatik ekleme, işaret güncelleme, 15+ sayfa kategorisi bölme.
- Birleştirme ve ad değiştirme **yasak** (P9).
- Kategori sıralaması içerdiği sayfa sayısına göre otomatik (yoğun = yukarı).
- Outline = graph view'da merkezi büyük node, kullanıcı pick-up'ı için.

---

## Bölüm 2 — Mekanizma eşleşmeleri

| MUST | Mekanizma |
|------|-----------|
| M1 | Manuel `claude -p` (P8). openPkb v2'de scheduler. |
| M2 | `/deep-research` slash command — orchestrator Round 2 |
| M3 | `verifier` subagent — Twitter-primary doğrulama (twitterapi.io), Twitter <3 ise Crawl4AI fallback |
| M4 | `contradiction-finder` subagent + `[!contradiction]` callout |
| M5 | `source-trust` subagent + Crawl4AI + twitterapi.io |
| M6 | `gap-hunter` subagent — P6 eşiği (`next_to_eligible: true`) |
| M7 | `_open_questions.md` (blocker/high/nice) |
| M8 | `vault/` katmanlı yapı, Obsidian wikilink, `_wiki/outline/` |
| M9 | `.claude/agents/` altında izole subagent tanımları (6 agent) |
| M10 | CLAUDE.md'deki "Subagent çıktı sözleşmesi" |
| M11 | researcher — Twitter-primary (twitterapi.io); Crawl4AI sadece boşluk için |
| M12 | `state.json` per topic, JSON flush her round'da |
| M13 | `/deep-research` Ön kontrol bölümü |
| M14 | `outline-keeper` subagent — Round 4e (en son), `_wiki/outline/<konu>.md` |

---

## Bölüm 3 — Klasör ağacı

```
openpkb/
├── CLAUDE.md                       # Anayasa
├── main.md                         # Bu dosya
├── README.md                       # Kurulum + kullanım
├── docker-compose.yml              # Crawl4AI + InfraNodus
├── .env.example                    # ANTHROPIC_API_KEY, TWITTERAPI_IO_API_KEY
├── .gitignore
│
├── scripts/
│   ├── bootstrap.sh                # docker pull + skill add + git init
│   └── teardown.sh
│
├── .claude/
│   ├── settings.json               # MCP + permissions
│   ├── agents/
│   │   ├── researcher.md           # M2, M11 — Twitter-PRIMARY, web boşluk
│   │   ├── verifier.md             # M3 — Twitter-primary doğrulama
│   │   ├── contradiction-finder.md # M4 — lokal, internet yasak
│   │   ├── source-trust.md         # M5 — crawl4ai + twitterapi.io
│   │   ├── gap-hunter.md           # M6, P6 — lokal, infranodus opsiyonel
│   │   └── outline-keeper.md       # M14, P9 — lokal, taxonomy yöneticisi
│   ├── commands/
│   │   ├── deep-research.md        # Ana orchestrator (Round 4e: outline)
│   │   ├── resume-topic.md         # P5 manuel resume
│   │   ├── morning-digest.md       # P3 dosya çıktısı
│   │   └── topic-queue.md
│   └── skills/                     # bootstrap.sh kuruyor
│       └── twitterapi-io/          # (gitignore'da)
│
├── .openPkb/
│   └── soul.md                     # Placeholder — CLI gelecekte
│
└── vault/
    ├── _raw/                       # Immutable, sadece researcher yazar
    ├── _wiki/
    │   ├── concepts/
    │   ├── entities/
    │   ├── claims/                 # confirmations alanı P6 için kritik
    │   ├── questions/              # gap-hunter ürünü
    │   ├── contradictions/         # contradiction-finder ürünü
    │   ├── sources/                # source-trust ürünü
    │   └── outline/                # outline-keeper ürünü (P9, M14)
    ├── _topics/
    │   └── _template/              # Yeni konu açarken kopyala
    │       ├── topic.md
    │       ├── state.json
    │       ├── seeds.md            # P7 Twitter tohumları
    │       ├── _open_questions.md
    │       └── _warnings.md
    ├── _digests/                   # P3 günlük dosya
    └── .obsidian/
        └── graph.json              # Graph view config (node size by conn)
```

---

## Bölüm 4 — Akış (Twitter-first, manuel, tek konu)

**T0 (manuel kurulum).** Sen `cp -r vault/_topics/_template vault/_topics/<slug>`
yaparsın. `topic.md`'deki slug ve başlığı düzelt. `seeds.md`'ye Twitter
tohum linklerini ekle. `topic.md` status `pending`.

**T1 (manuel tetikleme — P8).** Sen istediğinde:
```
claude -p "/deep-research <slug>"
```

**T2 (ön kontroller).**
- Tek aktif konu kontrolü (P4). Başka in_progress varsa dur.
- Kota pre-check (M13). Yetmiyorsa dur, `status: error`.
- `seeds.md` var mı? Yoksa dur.
- state.json var mı? Varsa kaldığı yerden devam.

**T3 (Round 1 — haritalama).** Mevcut `_wiki/`'yi grep, frontmatter-first
oku. "Şu an ne biliyoruz" 5-7 cümle.

**T4 (Round 2 — plan).** Konuyu 3-6 alt-konuya böl. `topic.md`'ye yaz.
state.json'a flush: `status: in_progress`.

**T5 (Round 3 — paralel researcher dispatch, P7).**
- Her alt-konu için **researcher** ayrı dispatch
- researcher: seeds.md → Twitter sörfü → snowball (derinlik 2) → web doğrulama
  (Crawl4AI) → `_raw/`'a yaz
- min 1000 like filtresi
- Her bitende state.json flush

**T6 (Round 4 — sıralı işleme).** Sırayla:
- **verifier**: her yeni claim, **Twitter-primary** doğrulama (Twitter <3 ise
  web fallback), skip @ 3+ conf
- **source-trust**: her yeni creator/domain, skip @ <90 gün profil
- **contradiction-finder**: çelişki sinyali varsa
- **gap-hunter**: P6 koşulu geçen direktiflerin next-to'sunu açar
- **outline-keeper** (EN SON): `_wiki/outline/<konu>.md` günceller — yeni
  sayfaları kategorilere ekler, işaretleri günceller, 15+ kategorileri böler

**T7 (Round 5 — wiki'ye işle).** Subagent bulgularını
`_wiki/{concepts,claims,...}/`'ye yaz. Wikilink'leri unutma.

**T8 (Round 6 — topic kapama).**
- `topic.md` frontmatter: status (done/in_progress), counters
- state.json final flush
- Stdout özet: 5 cümle

**T9 (graceful stop — gerekirse, P5).** Kota yaklaşırsa: yeni dispatch yok,
mevcutler biter, state.json `in_progress`. Kullanıcıya "kota yetmedi,
`/resume-topic <slug>` ile devam" de.

**T10 (manuel digest).** Sen istediğinde:
```
claude -p "/morning-digest"
```
`vault/_digests/<tarih>.md` üretilir. Telegram yok (P3).

**T11 (resume — gerekirse).**
```
claude -p "/resume-topic <slug>"
```
state.json'dan kaldığı yer, plan değişmez, sadece kalan iş.

---

## Değişiklik özeti (önceki versiyondan)

### Tur 2 (bu güncelleme)
- **P7 sertleştirildi:** Twitter primary, web sadece boşluk doldurucu.
  Twitter <3 hesap yoksa veya kavram tanımı yoksa web devreye girer.
  `_raw/` çoğunluğu tweet/thread olmalı.
- **P9 eklendi:** Outline-anchored knowledge. `_wiki/outline/<konu>.md`
  her konu için yapılandırılmış hiyerarşik görünüm.
- **M14 eklendi:** Outline yönetimi mekanizması.
- **6. agent eklendi:** `outline-keeper.md` — taxonomy yöneticisi,
  her `/deep-research` Round 4e (en son) çalışır.
- **researcher.md ve verifier.md baştan yazıldı:** Twitter-primary kuralı
  net, web sadece tespit edilen boşluklar için.
- **graph.json eklendi** (`vault/.obsidian/`): node boyutu = bağlantı
  sayısı, outline turuncu vurgulu.
- **deep-research Round 4'e 4e (outline-keeper) eklendi.**

### Tur 1 (önceki)
- **Crawl4AI MCP eklendi** (Tavily çıktı). `uysalsadi/crawl4ai-mcp-server`.
- **twitterapi.io skill eklendi** (BrowserAct çıktı).
- **InfraNodus opsiyonel** — self-hosted, yoksa fallback.
- **openPkb scope çekildi.** Sadece bir isim — gelecekte yazılacak CLI.
- **`scripts/bootstrap.sh` + `docker-compose.yml`** eklendi.
- **5 subagent + 4 komut + CLAUDE.md** prensiplere uyacak şekilde yazıldı.

## Açık konular (sonraki iterasyon)

1. Cache mekanizması (`.cache/fetch/`) — şu an kapalı, gerektiğinde aç.
2. Doğal dil cron (S1) — openPkb yazılınca.
3. Mid-flight kota monitör (P5 sadece pre-check + graceful stop) —
  iyileştirilebilir.
4. InfraNodus self-hosted entegrasyonu — `docker compose --profile graph up`
   ile testlenmedi henüz.
5. İlk gerçek konu testi.
