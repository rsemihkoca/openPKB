---
description: in_progress durumunda kalmış bir konuyu state.json'dan kaldığı yerden devam ettirir. Kullanıcı manuel tetikler (P5 — otomatik retry yok).
argument-hint: <konu-slug>
---

Konu: $ARGUMENTS

## Ön kontrol

### state.json var mı?
`vault/_topics/<konu-slug>/state.json` yoksa: **dur**, kullanıcıya bildir.
"Bu konu için state.json bulunamadı. `/deep-research <slug>` ile baştan
başla."

### Durum kontrolü
state.json'daki `status` `in_progress` değilse:
- `done` → "Bu konu zaten tamamlanmış. Resume gereksiz."
- `error` → "Konu hata durumunda. state.json'daki `error` alanını oku,
  problem gerçekten çözüldü mü? Çözüldüyse manuel olarak `status: pending`
  yap ve `/deep-research <slug>` çağır."
- `pending` → "Henüz başlamamış. `/deep-research <slug>` çağır."

### Diğer aktif konu var mı? (P4)
`vault/_topics/*/topic.md`'de başka `in_progress` varsa: **dur**.
"Şu an `<diğer>` aktif görünüyor. Aynı anda iki konu aktif olamaz (P4).
Önce onu bitir veya `status: done` yap."

### Kota pre-check (M13)
Yeterli kota var mı? Yoksa "kota yenilenince çağır" diye dön.

---

## Resume akışı

### Adım 1 — State'i oku
```json
{
  "status": "in_progress",
  "plan": {
    "subtopics": ["hijyen", "slideshow", "fyp", "creators"],
    "done": ["hijyen", "slideshow"],
    "in_progress": ["fyp"],
    "pending": ["creators"]
  },
  "subagent_results": {
    "researcher_fyp": "in_progress"
  }
}
```

### Adım 2 — Kaldığı yerden devam
- `in_progress` olan subagent varsa: yeniden tetikle (idempotent çalışmalı,
  cache var olan kaynakları atlar)
- `pending` olan alt-konular için yeni subagent dispatch et
- Plan zaten var, **yeni plan yapma** — sadece kaldığı yerden ilerle

### Adım 3 — Wiki işleme + topic kapama
deep-research'ün Round 4-5-6 akışını uygula:
- verifier, source-trust, contradiction-finder, gap-hunter sırayla
- Wiki sayfaları güncelle
- topic.md frontmatter güncelle
- state.json final flush

### Adım 4 — Graceful stop hâlâ olabilir
Yine kota yetmezse yine graceful stop. Tekrar `in_progress`, tekrar resume
gerekebilir.

---

## Çıktı

```
Resume sonucu — tiktok-marketing
  - Yeni eklenen sayfa: N
  - Yeni blocker: M
  - Status: done | in_progress (devam)
  - Devam gerekiyorsa: /resume-topic tiktok-marketing
```

## Kurallar

- **Yeni plan yapma.** state.json'daki planı kullan.
- **Cache'i kullan** (gelecekteki P2). Aynı URL'i yeniden fetch etme.
- **Otomatik retry yok** (P5). Hata olursa yine `in_progress`'te kal,
  kullanıcı tekrar çağırsın.
- **state.json'a her major adımdan sonra flush** (M12). Crash güvenliği.
