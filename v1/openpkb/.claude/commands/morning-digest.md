---
description: Son N saatte vault'ta ne değişti, hangi blocker'lar açık, hangi çelişkiler çözülmedi — günlük özet üretir. CLI-only, dosyaya yazar, mesaj göndermez (P3).
argument-hint: [hours, default 24]
---

Saat aralığı: $ARGUMENTS (boşsa 24)

Bugünün tarihi: `date +%Y-%m-%d` ile al.

## Akış

### Adım 1 — Git log
Son N saatte değişen dosyaları çek:
```bash
git -C vault log --since="${HOURS} hours ago" --name-status --pretty=format:""
```

### Adım 2 — Değişiklikleri tipine göre say
- Yeni eklenenler (status A) ve düzenleneneler (status M)
- Türlerine göre dağılım:
  - concept / entity / claim / question / contradiction / source

### Adım 3 — Aktif konunun durumu
`_topics/*/topic.md` içinde `status: active` veya `in_progress` olanı bul.
- Slug, last_run, gaps_opened, blockers_open

### Adım 4 — Open questions
`vault/_topics/<aktif-konu>/_open_questions.md` oku.
- Toplam soru
- Priority: blocker olanlar
- 3+ günden eski blocker'lar (acil işaret)
- 7+ günden eski blocker → **URGENT**

### Adım 5 — Açık çelişkiler
`vault/_wiki/contradictions/` altında `status: open` olanları listele.

### Adım 6 — Scam uyarıları
`vault/_wiki/sources/` altında **son N saatte eklenen** `trust: scam-suspect`
profilleri çek.

### Adım 7 — Digest dosyasını yaz
`vault/_digests/<YYYY-MM-DD>.md` oluştur:

```yaml
---
date: 2026-05-20
generated: 2026-05-20T08:00:00
hours_window: 24
pages_added: N
contradictions_open: N
blockers_open: N
scam_warnings: N
active_topic: tiktok-marketing
---

# Günün özeti — 2026-05-20

## Aktif konu
**tiktok-marketing** — status: in_progress
last_run: 2026-05-20, 4 blocker açık

## Eklenen sayfalar (N tane)
- [[sayfa-1]] — {bir cümlelik özet}
- [[sayfa-2]] — ...

## Açık blocker'lar (N tane)
1. [[soru-1]] (3 gündür açık)
2. [[soru-2]] (URGENT — 7 gün+)
3. ...

## Çözülmemiş çelişkiler
- [[contradiction-1]] — status: open — A: ... / B: ...
- [[contradiction-2]] — status: context-dependent — ...

## Scam uyarıları
- [[creator-x]] — kırmızı sinyaller: anonim + para isteme
- ...

## Yarına öneriler (manuel kullanıcı için)
- {Hangi blocker'lar manuel kullanıcı kararı bekliyor}
- {Hangi konuların next-to'su açılmaya hazır}
- {Resume gereken in_progress task var mı}
```

### Adım 8 — Kullanıcıya stdout özeti
Dosyayı yazdıktan sonra **stdout'a 5 satırlık özet** yaz (P3 — CLI-only,
mesaj yok):

```
Digest yazıldı: vault/_digests/2026-05-20.md
- Eklenen sayfa: 12
- Açık blocker: 4 (1 URGENT)
- Çözülmemiş çelişki: 2
- Scam uyarısı: 1
```

## Kurallar

- **URGENT işareti.** 7+ günden açık blocker varsa "URGENT" yaz. Demek ki
  next-to açılmıyor veya kullanıcı müdahalesi bekliyor.
- **Dosyaları kendin yorumlama.** Sadece say ve özetle. Strateji önerisi
  vermek senin işin değil.
- **N saat değişiklik yoksa "quiet day" digest'i yaz.** Kuru ama dürüst.
- **Telegram yok, mesaj yok** (P3). Sadece dosya + stdout özeti.
