# openpkb — CLAUDE.md

Bu dosya Claude Code'un her oturumda okuduğu **anayasadır**. Tüm subagent'lar,
slash komutlar ve manuel çağrılar bu kurallara uymak zorundadır. Şüphede bu
dosya kazanır.

---

## Sistem nedir

Sen yokken senin için araştırma yapan bir kişisel bilgi tabanı (PKB).
Bir konu verilir → araştırma tetiklenir → **Twitter-first** bilgi toplanır →
çapraz doğrulama, çelişki tespiti, scam taraması yapılır → Obsidian vault'unda
graph olarak yapılandırılır.

**Önemli:** Bu repo'da Python/Node uygulaması YOKTUR. openPkb bir CLI tool
olarak gelecekte yazılacak. Şu an her şey **manuel tetiklenir** — sen veya
gelecekte openPkb `claude -p "/deep-research <konu>"` çağırır.

---

## Tasarım Prensipleri (P1–P8)

Bu prensipler tüm mimari kararları kısıtlar. İhlal eden bir özellik ya
yeniden tasarlanır ya reddedilir.

### P1 — Self-hosted ve ücretsiz öncelik

Paralel iki seçenek varsa self-hosted/ücretsiz olanı seçilir.
- Web crawl: **Crawl4AI MCP** (Tavily/Firecrawl değil)
- Twitter: **twitterapi.io skill** (X resmi API'sı çok pahalı, alternatif yok)
- Graph analytics: **InfraNodus self-hosted** veya fallback (grep + Obsidian wikilink)
- Ücretli servis ancak ücretsiz muadili olmadığında ve net gerekçeyle kullanılır.

### P2 — Token tasarrufu birinci sınıf

- Subagent → orchestrator akışında **ham web fetch'leri gönderilmez**.
  Subagent kendi context'inde işler, sadece **unique + birden fazla kaynakta
  tekrar eden bulguları referanslarıyla** döner.
- Verifier 3+ kaynakta doğrulanmış iddiayı tekrar doğrulamaya kalkmaz.
- Wiki sayfaları arası okuma **frontmatter-first**: orchestrator önce
  metadata okur, gövdeyi sadece gerektiğinde açar.

### P3 — CLI-only

Telegram, Discord, mobil bildirim **yok**. Tüm çıktılar dosyaya veya stdout'a.
`/morning-digest` bir dosya üretir, mesaj göndermez.

### P4 — Tek aktif konu

Aynı anda birden fazla `status: active` konu olmaz. Subagent paralelliği
**konu içinde** geçerli, konular arası değil.

### P5 — Resumability ve kota disiplini

- Her job başlamadan kota durumu kontrol edilir; yetmiyorsa hiç başlamaz.
- Job ortasında kotaya yaklaşılırsa **graceful stop**: yeni subagent dispatch
  edilmez, mevcutler bitirilir, checkpoint kaydedilir, durulur.
- Yarım kalan iş `in_progress` durumunda diskte bekler.
- **Otomatik retry yoktur.** Kullanıcı `/resume-topic` ile elle başlatır.
- Task durumları: `pending`, `in_progress`, `done`, `error`. **`paused` yok.**
- Hata da `in_progress`'te kalır (silinmez, kullanıcı görür).

### P6 — Selective branching ("next-to")

Sistem her boşluğu kovalamaz. Yeni araştırma dalı **sadece** şu koşulda açılır:

1. Mevcut konu içinde bir **direktif** geçmiş olmalı (örn: "static IP kullan"),
2. O direktif **≥3 bağımsız kaynak** tarafından doğrulanmış olmalı,
3. Ancak o zaman direktifin next-to'su (örn: "en iyi static IP provider")
   yeni dal olur.

Konuyla ilgisiz hiçbir şey kovalanmaz. "TikTok marketing" araştırılırken
"TikTok telefona nasıl indirilir" gibi alakasız boşluklar atlanır.

### P7 — Twitter-first akış

Araştırma Twitter'da başlar, web doğrulamasıyla genişler. **Kör keyword
search yok.** Kullanıcı `seeds.md` dosyasında başlangıç tweet/hesap tohumu
verir, agent oradan keşfeder.

**Görünürlük filtresi:** min **1000 like** (sabit eşik).

### P8 — Manuel tetikleme

Şu an gece job'u, scheduler, cron **yok**. Sen istediğinde `claude -p
"/deep-research <konu>"` çağırırsın. openPkb gelecekte bu tetiklemeyi
otomatikleştirecek ama şimdilik manuel.

---

## Sayfa tipleri (vault şeması)

### `_raw/YYYY-MM-DD-{slug}.md`

Ham kaynak. Tweet, makale, transcript. **Asla edit edilmez** (researcher
hariç). Diğer agent'lar buraya yazmaz, sadece okur.

Frontmatter:
```yaml
---
url: https://...
fetched: 2026-05-20T02:13:00
source_type: article|tweet|video_transcript|github|paper
author: ...
published: 2026-04-12
language: tr|en|...
trust_initial: high|medium|low|unverified
sponsored: false
---
```

### `_wiki/concepts/<slug>.md`

Soyut kavram (örn: "TikTok FYP algoritması"). Çok kaynak buraya işlenir.

```yaml
---
type: concept
created: 2026-05-20
updated: 2026-05-20
tags: [tiktok, algorithm]
parent_topic: tiktok-marketing
---
```

### `_wiki/entities/<slug>.md`

Kişi, ürün, hesap, domain.

```yaml
---
type: entity
subtype: person|product|account|domain
created: 2026-05-20
---
```

### `_wiki/claims/<slug>.md`

Doğrulanmış iddia. **`confirmations` alanı kritik** — P6'nın eşiği buradan
okunur.

```yaml
---
type: claim
created: 2026-05-20
trust: high|medium|low
confirmations: 4                    # Kaç bağımsız kaynak doğruladı
confirming_sources:
  - [[2026-05-19-tiktok-blog]]
  - [[2026-05-17-creator-john]]
  - [[2026-05-15-marketing-dive]]
  - [[2026-05-12-techcrunch]]
directive: true                     # Bu bir "şunu yap" iddiası mı (next-to adayı)
next_to_spawned: false              # gap-hunter bunun next-to'sunu açtı mı
---
```

### `_wiki/questions/<slug>.md`

Açık soru (gap-hunter üretir).

```yaml
---
type: question
created: 2026-05-20
parent_topic: tiktok-marketing
priority: blocker|high|nice-to-have
spawned_from: [[claim-static-ip-kullan]]    # Hangi direktifin next-to'su
blocks: [strateji_yazma]
---
```

### `_wiki/contradictions/<slug>.md`

Çelişki sayfası (contradiction-finder üretir).

```yaml
---
type: contradiction
created: 2026-05-20
about: tiktok-posting-frequency
positions: 2
status: open|partially-resolved|context-dependent
---
```

### `_wiki/sources/<slug>.md`

Trust profili (source-trust üretir).

```yaml
---
type: entity
subtype: source-profile
created: 2026-05-20
trust: high|medium|low|scam-suspect
last_checked: 2026-05-20
review_after: 2026-08-20
---
```

### `_topics/<konu>/topic.md`

Aktif araştırma konusu.

```yaml
---
type: topic
slug: tiktok-marketing
status: pending|in_progress|done|error
created: 2026-05-20
last_run: 2026-05-20
pages_added: 12
contradictions_open: 2
gaps_opened: 4
blockers_open: 2
---
```

### `_topics/<konu>/state.json`

Checkpoint dosyası (M12). Her major adımdan sonra flush.

```json
{
  "slug": "tiktok-marketing",
  "status": "in_progress",
  "started_at": "2026-05-20T02:00:00",
  "last_checkpoint": "2026-05-20T02:34:00",
  "plan": {
    "subtopics": ["hijyen", "slideshow", "fyp", "creators"],
    "done": ["hijyen", "slideshow"],
    "in_progress": ["fyp"],
    "pending": ["creators"]
  },
  "subagent_results": {
    "researcher_hijyen": "done",
    "researcher_slideshow": "done",
    "researcher_fyp": "in_progress",
    "verifier_hijyen": "done"
  },
  "error": null
}
```

### `_topics/<konu>/seeds.md`

Kullanıcının verdiği Twitter tohumları (P7). Format:

```markdown
# Seeds for tiktok-marketing

## Tweets
- https://twitter.com/user1/status/123 — neden: FYP açıklaması var
- https://twitter.com/user2/status/456

## Accounts
- @creator_x — TikTok marketing uzmanı
```

### `_topics/<konu>/_open_questions.md`

gap-hunter'ın ürettiği soru kuyruğu. Priority sıralı: blocker → high → nice.

### `_topics/<konu>/_warnings.md`

source-trust'ın scam-suspect işaretlediği kaynaklar.

---

## Dosya disiplini

- **`_raw/` sadece researcher tarafından yazılır.** Diğer agent'lar buraya
  yazmaz, sadece okur.
- **Wikilink her zaman çift köşeli:** `[[2026-05-20-some-page]]`.
- **Frontmatter zorunlu.** Frontmatter'sız sayfa açma.
- **`status: locked` olan sayfaya dokunma.** Kullanıcı manuel düzeltmiş demektir.
- **Aynı URL iki kez `_raw/`'a yazılmaz.** Yazmadan önce grep at.
- **Aynı sorunun rewording'i için iki question sayfası açma.** Grep at.

---

## Subagent çıktı sözleşmesi (M10 + P2)

Subagent → orchestrator akışı **standart formatlı**:

```markdown
## Bulgular

### B1 — {Kısa başlık}
**Ağırlık:** {N} bağımsız kaynak
**Referanslar:**
- [[_raw/...]] — {rol: orijinal kaynak | gözlem | analiz}
- [[_raw/...]]
- [[_raw/...]]
**Direktif:** {evet/hayır — bu bir "şunu yap" iddiası mı}
**Özet:** {Subagent'ın kendi cümlesi, 2-3 satır}
**Kilit alıntılar:**
> "{Kaynak A'dan tam alıntı}" — [[2026-...]]
> "{Kaynak B'den tam alıntı}" — [[2026-...]]

### B2 — ...
```

Subagent **ham web sayfasını** orchestrator'a göndermez. Sadece bu formatlı
bulgu listesini. Orchestrator bunu okur, `_wiki/`'ye işler.

---

## Subagent → tool eşlemesi

| Agent | Built-in | MCP | Skill | Yasak |
|---|---|---|---|---|
| researcher | WebSearch, WebFetch, Read, Write, Glob, Grep | crawl4ai | twitterapi-io | Edit |
| verifier | WebSearch, WebFetch, Read, Edit, Glob, Grep | crawl4ai | — | Write |
| contradiction-finder | Read, Write, Edit, Glob, Grep | — | — | WebFetch, WebSearch |
| source-trust | WebSearch, WebFetch, Read, Write, Edit, Glob, Grep | crawl4ai | twitterapi-io | — |
| gap-hunter | Read, Write, Edit, Glob, Grep | infranodus (opsiyonel) | — | WebFetch, WebSearch |

---

## Kısıtlamalar (asla unutma)

1. **Tek aktif konu** (P4). Birden fazla `_topics/*/topic.md` `status: active`
   olamaz.
2. **Subagent ham metni context'e koymaz** (P2). Sadece formatlı bulgu döner.
3. **Verifier confirmations ≥3 → trust: high + P6 next-to adayı.**
4. **gap-hunter sadece P6 koşulunu geçen claim'lerin next-to'sunu kovalar.**
   Rastgele boşluk değil.
5. **min 1000 like** Twitter filtresi (P7), sabit eşik.
6. **Hata → `in_progress`'te kalır** (P5), otomatik retry yok.
7. **`_raw/` immutable** — sadece researcher yazar.
