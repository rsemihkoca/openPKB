# CC Nights — Sistem Spec'i

## Bölüm 0 — Tasarım Prensipleri

Bu prensipler tüm mimari kararları kısıtlar. Bir özellik bu prensiplerden birini ihlal ediyorsa, ya yeniden tasarlanır ya da reddedilir.

**P1 — Self-hosted ve ücretsiz öncelik.** Paralel iki seçenek varsa self-hosted/ücretsiz olan tercih edilir. Spesifik tercihler:
- Web crawl: **Crawl4AI** (Tavily / paid search değil)
- Twitter: **twitterapi.io** (`npx skills add kaitoInfra/twitterapi-io`)
- Graph analytics: ücretsiz alternatif varsa o, yoksa InfraNodus
- Ücretli servis ancak ücretsiz muadili olmadığında ve net bir gerekçeyle kullanılır.

**P2 — Token tasarrufu birinci sınıf hedef.** Mekanizmalar:
- Subagent → orchestrator akışında ham web fetch'leri **gönderilmez**. Subagent kendi içinde işler, **sadece unique + birden fazla kaynakta tekrar eden bulguları referanslarıyla** döner.
- Aynı URL iki kere fetch edilmez (lokal cache).
- Verifier 3+ kaynakta doğrulanmış iddiayı tekrar doğrulamaz.
- Wiki sayfaları arası okumada **frontmatter-first**: orchestrator önce metadata okur, gövdeyi sadece gerektiğinde açar.

**P3 — CLI-only arayüz.** Telegram, Discord, mobil bildirim **yok**. Tüm çıktılar dosyaya veya stdout'a. `/morning-digest` bir dosya üretir, mesaj göndermez.

**P4 — Tek aktif konu.** Aynı anda birden fazla `status: active` konu olmaz. Subagent paralelliği **konu içinde** geçerli, konular arası değil.

**P5 — Resumability ve kota disiplini.**
- Her job başlamadan kota durumu kontrol edilir; yeterli değilse hiç başlamaz.
- Job ortasında kotaya yaklaşılırsa **graceful stop**: yeni subagent dispatch edilmez, mevcutler bitirilir, checkpoint kaydedilir, durulur.
- Yarım kalan iş `in_progress` durumunda diskte bekler.
- Otomatik retry **yoktur**. Kullanıcı elle başlatır.
- Task durumları: `pending`, `in_progress`, `done`, `error`. **`paused` yok.**

**P6 — Selective branching ("next-to").** Sistem her boşluğu kovalamaz. Yeni araştırma dalı sadece şu koşulda açılır:
- Mevcut konu içinde bir direktif geçmiş olmalı (örn: "static IP kullan"),
- O direktif **≥3 bağımsız kaynak** tarafından doğrulanmış olmalı (ağırlık eşiği),
- Ancak o zaman o direktifin next-to'su (örn: "en iyi static IP provider") yeni dal olur.

Konuyla ilgisiz hiçbir şey kovalanmaz. "TikTok marketing"i araştırırken "TikTok telefona nasıl indirilir" gibi düşük seviye, ilgisiz konular branch açmaz.

**P7 — Twitter-first akış.** Araştırma Twitter'da başlar, web doğrulamasıyla genişler. Kör keyword search ile değil — kullanıcı başlangıç tweet/hesap tohumu verir, agent oradan keşfeder. Görünürlük filtresi: **min 1000 like** (sabit eşik).

**P8 — Claude Code entegrasyonu.** Sen normal CC oturumunda "şunu araştır" dediğinde `_topics/<konu>.md` otomatik açılır, `status: active` olur. Manuel dosya yazmıyorsun.

---

## Bölüm 1 — MUST'lar

Sistemin bunlar olmadan değeri sıfır.

**M1 — Async / arka plan çalışma.** openPkb gece job'u tetikler. Sen yokken çalışır.

**M2 — Konu → otomatik dallandırma.** Orchestrator konuyu alt-konulara böler. Sen tek tek listelemiyorsun.

**M3 — Çoklu kaynak doğrulama.** Verifier her iddiayı bağımsız 2+ domain'de teyit eder. 3+'a ulaşan iddia "ağırlığı yüksek" sayılır (P6'nın eşiği).

**M4 — Karşıt görüşleri silmeden saklama.** Çelişen iddialar `[!contradiction]` callout + `_wiki/contradictions/` sayfası. Hangi koşulda hangisi geçerli işaretlenir.

**M5 — Scam / kaynak güvenilirliği taraması.** Her yeni creator/domain/hesap için tek seferlik trust profili. `_wiki/sources/` altında sayfa.

**M6 — Selective gap-hunting.** Boşluk değil, **ağırlığı geçen direktiflerin next-to'su** kovalanır (bkz. P6). Süngerbob metaforu daraltıldı: her boşluk değil, **graph'taki ağır kenarların next-to'ları**.

**M7 — Blocker önceliği.** Açık sorular `_open_questions.md`'de blocker / high / nice-to-have sırasıyla. Senin "bir sonraki adımı atamadığın boşluk" başta.

**M8 — Obsidian graph yapısı.** Üç katman: `_raw` (dokunulmaz), `_wiki` (LLM ürünü, wikilink'li), `_topics` (aktif konular). Obsidian native graph view'de görünür. 3D plugin yok (3D ifadesi mecazi).

**M9 — Async subagent paralellik (konu içinde).** Farklı alt-konular paralel subagent'larda. Her biri kendi context window'unda. Konular arası paralellik yok (P4).

**M10 — Context erime, meta kalıcı.**
- Subagent ham web'i kendi context'inde tutar, dışarı çıkmaz.
- Subagent → orchestrator: **işlenmiş, unique, ağırlıklı bulgular + referanslar** (tam metin değil özet de değil — *seçilmiş detay*).
- Wiki sayfaları frontmatter-first okunur.

**M11 — Twitter ve sosyal kaynak.** twitterapi.io kullanılır. **Twitter-first akış (P7):** kullanıcı tohum tweet/hesap verir → agent oradan thread, quote, ilgili creator'ları keşfeder → ≥1000 like filtresi → bulgular web'de doğrulanır.

**M12 — Resumability + checkpoint.**
- Her `_topics/<konu>/` altında `state.json`: hangi alt-konular `done`, hangileri `in_progress`, hangileri `pending`.
- Her N işlem adımında state'e flush.
- Job başlangıcında state.json okunur, kaldığı yerden devam edilir.

**M13 — Kota pre-check + graceful stop.**
- v1: Job başlangıcında kota kontrolü. Yetmiyorsa hiç başlamaz (P5).
- Mid-flight kotaya yaklaşılırsa: yeni dispatch yok, mevcutler biter, checkpoint, dur (P5).
- Otomatik retry yok. `in_progress` kalır, kullanıcı elle başlatır.

---

## Bölüm 2 — Mekanizma eşleşmeleri

| MUST | Mekanizma |
|------|-----------|
| M1 | openPkb scheduler + headless CC tetikleme |
| M2 | `/deep-research` slash command — orchestrator önce plan turn'ü, sonra paralel dispatch |
| M3 | `verifier` subagent, frontmatter `trust:` ve `confirmations:` (kaynak sayısı) |
| M4 | `contradiction-finder` subagent + Obsidian callout |
| M5 | `source-trust` subagent + `_wiki/sources/` sayfaları |
| M6, M7 | `gap-hunter` subagent, P6 eşik kuralı, `_open_questions.md` |
| M8 | LLM Wiki pattern, Obsidian wikilinks, ücretsiz graph analytics MCP |
| M9 | `.claude/agents/` altında izole subagent tanımları |
| M10 | Frontmatter şeması, subagent çıktı şablonu (referanslı bulgu listesi) |
| M11 | twitterapi.io skill, Crawl4AI (web doğrulama tarafı) |
| M12 | `state.json` per topic, atomic flush |
| M13 | openPkb cron pre-check hook, in-flight quota monitor |

---

## Bölüm 3 — Klasör ağacı

```
openpkb/
├── CLAUDE.md                       → Anayasa: sayfa tipleri, P0–P8 prensipleri, format kuralları
│
├── .claude/
│   ├── agents/
│   │   ├── researcher.md           → M2, M11 — web + twitterapi.io
│   │   ├── verifier.md             → M3 — 3+ confirmation eşiği
│   │   ├── contradiction-finder.md → M4
│   │   ├── gap-hunter.md           → M6, M7 — P6 next-to eşiği uygular
│   │   └── source-trust.md         → M5
│   │
│   ├── commands/
│   │   ├── deep-research.md        → Tam akış
│   │   ├── morning-digest.md       → Dosyaya yazar, mesaj göndermez (P3)
│   │   ├── topic-queue.md          → Açık konuları listeler
│   │   └── resume-topic.md         → `in_progress` task'ı elle başlatır (P5)
│   │
│   └── settings.json               → MCP server izinleri, tool yasakları
│
├── .openPkb/
│   ├── soul.md                     → Agent kimliği, P0–P8 referansı
│   ├── cron.md                     → Job tanımları (doğal dil cron)
│   └── quota.json                  → Pre-check için kota state
│
├── .cache/
│   └── fetch/                      → URL-hash anahtarlı, tekrar fetch önler (P2)
│
├── vault/
│   ├── _raw/                       → Ham tweet/article/transcript, dokunulmaz
│   │
│   ├── _wiki/
│   │   ├── concepts/               → Soyut kavramlar
│   │   ├── entities/               → Kişi, ürün, hesap
│   │   ├── claims/                 → Doğrulanmış iddialar (trust + confirmations)
│   │   ├── questions/              → Açık sorular
│   │   ├── contradictions/         → Çelişki sayfaları (M4)
│   │   └── sources/                → Trust profilleri (M5)
│   │
│   ├── _topics/
│   │   └── <konu>/
│   │       ├── topic.md            → status, ana sayfa
│   │       ├── state.json          → M12 checkpoint
│   │       ├── seeds.md            → Kullanıcının verdiği başlangıç tweet/hesap (P7)
│   │       ├── _open_questions.md  → M7 öncelikli kuyruk
│   │       └── _warnings.md        → trust düşük kaynak uyarıları
│   │
│   ├── _digests/
│   │   └── 2026-05-20.md           → Günlük CLI özeti (P3)
│   │
│   └── .obsidian/                  → Plugin & graph ayarları
```

---

## Bölüm 4 — Akış (Twitter-first, tek konu)

**T0 (manuel).** Sen CC ile konuşurken "TikTok marketing araştır, şu tweetlerden başla: [linkler]" diyorsun.

**T1 (otomatik).** CC `_topics/tiktok-marketing/` açar. `seeds.md`'ye tweet linklerini yazar. `topic.md` status `active`. `state.json` başlangıç durumu.

**T2 (gece, openPkb).** 02:00'de scheduler tick.
- Önce **kota pre-check** (M13). Yetmiyorsa job atlanır, log düşülür, sabaha kalır.
- Yetiyorsa `claude -p "/deep-research tiktok-marketing"` headless tetikleme.

**T3 (orchestrator plan turn'ü).** Konuyu dallara böler: hijyen, slideshow, FYP, creator analizi.

**T4 (Twitter-first dispatch, M11 + P7).** 
- `researcher` subagent `seeds.md`'deki tweet'lerden başlar.
- Thread'leri, quote'layanları, mention edilen hesapları takip eder.
- **≥1000 like** filtresi.
- Bulduğu post/article/creator → `_raw/` altına.

**T5 (web doğrulama, Crawl4AI).** Twitter'da çıkan iddialar Crawl4AI ile bağımsız web kaynaklarında aranır. Sonuçlar `_raw/`'a.

**T6 (verifier).** Her iddia için confirmation sayısı. 3+ ulaşan → "ağırlığı yüksek" işareti (P6 için kritik).

**T7 (contradiction-finder).** Çelişen iddialar → callout + ayrı sayfa.

**T8 (source-trust).** Yeni creator/domain için trust profili.

**T9 (gap-hunter, selective).** Sadece confirmation ≥3 olan direktiflerin next-to'larını açık soru olarak kuyruğa atar. Konuyla ilgisiz boşluklar atlanır (P6).

**T10 (checkpoint).** Her major adımdan sonra `state.json` flush (M12).

**T11 (kota izleme).** Mid-flight kotaya yaklaşılırsa graceful stop, `state.json` `in_progress` olarak donduurulur.

**T12 (sabah).** openPkb `/morning-digest`'i çağırır. Çıktı `_digests/<tarih>.md` dosyasına yazılır. **Mesaj gönderimi yok** (P3). Sen sabah dosyayı açar veya CLI'dan okursun.

**T13 (resume).** Yarım kalan `in_progress` varsa, sen elle `/resume-topic tiktok-marketing` çalıştırırsın. Otomatik retry yok (P5).

---

## Değişiklik özeti (v1 → v2)

Önceki main.md'den farklar:

- **Yeni:** Bölüm 0 (Tasarım Prensipleri P1–P8).
- **Yeni MUST:** M12 (resumability), M13 (kota disiplini).
- **Daraltıldı:** M6/M7'nin "süngerbob" yorumu → P6'nın selective branching kuralına bağlandı. Sistem artık her boşluğu kovalamıyor, sadece ≥3 kaynakta doğrulanmış direktiflerin next-to'larını.
- **Değişti:** M10 — subagent → orchestrator akışı tam metin değil, *seçilmiş referanslı bulgu*.
- **Değişti:** M11 — Twitter primary, web verification. Tohum manuel.
- **Çıktı:** S2 (Telegram), S3 (learning loop — şu an scope dışı), S4 InfraNodus zorunluluğu (ücretsiz alternatif yoksa).
- **Çıktı:** N1–N4 nice-to-have'lar (Marp, çoklu vault, çok dil, sesli özet) — şu an scope dışı.
- **Spesifikleşti:** Crawl4AI, twitterapi.io, min 1000 like, ≥3 confirmation eşiği.
- **CLI-only:** Tüm bildirim/mesajlaşma katmanı çıkarıldı (P3).
- **Tek konu:** P4 ile sınırlandı.

---

## Hâlâ açık olan şeyler (sonraki iterasyon)

Bu dökümana koymadım ama sen istersen ele alırız:

1. `state.json` şemasının kesin alanları (hangi field'lar zorunlu).
2. `seeds.md` formatı — sadece link mi, link + neden ekledin notu mu.
3. Verifier'ın "bağımsız kaynak" tanımı — aynı domain'in iki sayfası bir mi sayılır iki mi.
4. Cache invalidation — fetch cache ne kadar yaşar (sonsuz mu, 7 gün mü).
5. CC'nin `_topics/<konu>.md`'yi otomatik açma davranışının tetik kelimesi ("araştır" yeter mi, daha net bir komut mu).
6. Graph analytics için ücretsiz alternatif araştırması (InfraNodus yerine).
