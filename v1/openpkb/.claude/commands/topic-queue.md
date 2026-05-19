---
description: vault/_topics/ altındaki konuları durumlarıyla listeler. P4 — tek aktif konu (in_progress) olmalı.
---

## Akış

### Adım 1 — Tara
`vault/_topics/` altındaki tüm `*/topic.md` dosyalarını oku.
Alt çizgiyle başlayan klasörler (`_template`) **dahil etme** — onlar şablon.

### Adım 2 — Her dosyanın frontmatter'ını oku
- slug
- status (`pending` / `in_progress` / `done` / `error` — **`paused` yok** P5)
- last_run
- gaps_opened
- blockers_open

### Adım 3 — state.json kontrolü
`_topics/<slug>/state.json` varsa, `last_checkpoint`'i oku. Resumable mi?

### Adım 4 — Tablo halinde göster

```
SLUG                        STATUS         LAST_RUN     BLOCKERS   RESUMABLE
tiktok-marketing            in_progress    2026-05-20   4          evet
app-launch-strategy         pending        —            —          —
twitter-growth-v2           done           2026-05-15   0          —
old-research                error          2026-05-10   2          hayır
```

### Adım 5 — Sıralama
1. `in_progress` (P4 — sadece 1 olmalı; daha çoksa **uyarı ver**)
2. `pending` (kullanıcının manuel `/deep-research` çağırması bekleniyor)
3. `error` (resume mümkün değil, kullanıcı bakmalı)
4. `done` (geçmiş, referans için)

### Adım 6 — Aktif konu işareti
Eğer `in_progress` varsa:

```
AKTİF KONU: tiktok-marketing
  - last_run: 2026-05-20
  - 4 blocker açık
  - state.json mevcut → /resume-topic tiktok-marketing ile devam et
```

Eğer yoksa:

```
Aktif konu yok. /deep-research <konu-slug> ile yeni bir araştırma başlatabilirsin.
Bekleyen pending konular: [liste]
```

## Kurallar

- **Alt çizgili klasörleri listeye alma** (`_template` gibi). Onlar şablon,
  konu değil.
- **`paused` durumu yok** (P5). Görürsen frontmatter hatalı, kullanıcıya
  bildir.
- **1'den fazla `in_progress` görürsen** (P4 ihlali): kırmızı uyarı ver,
  kullanıcıya hangisi gerçek aktif konu seçtir.
- **Bütün konular `done` veya `error` ise:** "Yeni bir konu eklemek ister
  misin?" diye sor.
- **last_run boşsa "—" yaz**, "null" değil.
