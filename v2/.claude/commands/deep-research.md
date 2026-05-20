---
description: Verilen konuyu Twitter-first akışla araştırır. seeds.md'den başlar, paralel subagent dispatch eder, doğrular, çelişki ayıklar, scam tarar, next-to boşlukları açar. Manuel tetiklenir (P8).
argument-hint: <konu-slug>
---

Konu: $ARGUMENTS

Sen orchestrator'sın. Bu komut bir araştırma turnünün TAMAMINI yönetir.

## Ön kontrol

### Tek aktif konu kontrolü (P4)
`vault/_topics/*/topic.md` içinde `status: active` veya `status: in_progress`
olan başka konu var mı?
- Varsa ve bu komut farklı konuyu işliyorsa: **dur**, kullanıcıya bildir.
- "Şu an `<diğer-konu>` aktif. Bitirmeden veya `status: done` yapmadan yeni
  konuya başlayamazsın."

### Kota pre-check (M13 / P5)
- Mevcut Anthropic API kotasını kabaca tahmin et (kullanıcıdan veya `.openPkb/quota.json`'dan)
- Bu konu için tahmini kullanım: ~50K-150K token
- Yetmiyorsa: **dur**, kullanıcıya bildir, `error` olarak işaretle.

### State.json kontrolü (M12 — resumability)
`vault/_topics/<konu-slug>/state.json` var mı?
- Varsa ve `status: in_progress`: **kaldığı yerden devam et.** Plan zaten
  yapılmış, hangi alt-konu yarım kalmış oradan oku.
- Yoksa: **sıfırdan başla**, aşağıdaki Round 1'den.

---

## Round 1 — Mevcut bilgiyi haritala

1. `vault/_wiki/` altında konu ile ilgili sayfaları **grep** at.
   **Sadece frontmatter + summary oku, tam metni AÇMA** (P2 frontmatter-first).
2. `vault/_topics/<konu>/topic.md` varsa oku.
3. `vault/_topics/<konu>/_open_questions.md`'de bu konuya ait soru var mı bak.
4. `vault/_topics/<konu>/seeds.md` var mı kontrol et.
   - **Yoksa:** kullanıcıya "seeds.md gerekli (P7 Twitter-first). Lütfen
     tohum tweet/hesap linkleri ekleyin." diye dön. `status: error`, dur.

Sonunda 5-7 cümlelik "şu an ne biliyoruz" özeti çıkar.

---

## Round 2 — Dallandırma planı

Konuyu **3-6 alt-konuya** böl. Her birine:
- Slug
- Bir cümlelik kapsam
- Önceliği (blocker / high / nice)
- Hangi subagent'a delege edileceği

Bunu `vault/_topics/<konu>/topic.md` içine "plan" başlığı altında YAZ.

state.json'a flush (M12):
```json
{
  "status": "in_progress",
  "plan": {
    "subtopics": ["hijyen", "slideshow", "fyp"],
    "pending": ["hijyen", "slideshow", "fyp"],
    "in_progress": [],
    "done": []
  }
}
```

---

## Round 3 — Twitter-first dispatch (P7)

**PARALEL dispatch** — sıralı değil. Her alt-konu için **researcher**
subagent'ını ayrı çağır.

researcher'ın akışı (CLAUDE.md'de detaylı):
1. `seeds.md` oku (P7 tohumlar)
2. twitterapi.io ile Twitter sörfü (min 1000 like)
3. Snowball (derinlik 2)
4. crawl4ai ile web doğrulama
5. `_raw/`'a yaz
6. Formatlı bulgu döner

Her researcher bittiğinde:
- state.json'da `in_progress` → `done` flush et
- Bulgular orchestrator'a gelir (ham metin değil, formatlı — M10)

---

## Round 4 — Sırayla işleme

researcher'lar tamamlandıktan sonra **sırayla** (paralel değil):

### 4a — verifier
Her yeni claim için verifier subagent'ı çağır.
- Twitter-primary doğrulama (P7): önce Twitter'da bağımsız hesap arar.
- Skip kuralı: zaten `confirmations >= 3` olan claim'leri **atlama**.
- 3+ doğrulanırsa `next_to_eligible: true` işaretle.
- Twitter'da yok ama web'de var ise UYARI olarak orchestrator'a bildir.

### 4b — source-trust
Her yeni creator/domain için source-trust çağır.
- Skip kuralı: 90 günden yeni profil varsa atla.

### 4c — contradiction-finder
İki+ kaynak arasında çelişki sinyali varsa contradiction-finder çağır.

### 4d — gap-hunter
gap-hunter'ı çağır. Diğer agent'lar `confirmations` ve `next_to_eligible`
alanlarını güncelliyor — gap-hunter o güncel state'i okumalı.

gap-hunter sadece P6 koşulunu geçen direktiflerin next-to'larını açar.

### 4e — outline-keeper (EN SON)
outline-keeper'ı çağır. Bütün diğer agent'lar bittikten sonra çalışmalı
çünkü outline güncel `confirmations`, `trust`, yeni question'ları
göstermek zorunda (P9).

outline-keeper:
- Yeni sayfaları doğru kategoriye ekler
- İşaretleri günceller (conf, trust, status)
- 15+ sayfa biriktirmiş kategorileri otomatik böler
- Kategorileri yoğunluğa göre sıralar
- **Birleştirme/ad değiştirme YAPMAZ**

---

## Round 5 — Wiki'ye işleme

Subagent'ların dönen formatlı bulgularını oku ve `vault/_wiki/`'ye işle:
- Concept'ler → `_wiki/concepts/`
- Iddialar → `_wiki/claims/` (verifier'ın güncellediği `confirmations`'la)
- Çelişkiler → `_wiki/contradictions/`
- Sorular → `_wiki/questions/`
- Trust profilleri → `_wiki/sources/`

Wikilink'leri unutma — her sayfa diğerlerine bağlı olmalı.

---

## Round 6 — Topic dosyasını kapat

`vault/_topics/<konu>/topic.md` frontmatter:
```yaml
status: done                       # veya in_progress (graceful stop ise)
last_run: 2026-05-20
pages_added: N
contradictions_open: N
gaps_opened: N
blockers_open: N
outline_revision: 8                # outline-keeper'ın son revision'ı
```

state.json final flush:
```json
{
  "status": "done",
  "finished_at": "2026-05-20T03:45:00"
}
```

---

## Kota yaklaşımı (P5 graceful stop)

Turn 40'a yaklaşırsan veya kota tükeniyorsa:
- **Yeni subagent dispatch ETME.**
- Mevcut çalışanları bitir.
- state.json'a flush et: `status: in_progress`, hangi alt-konu yarım kaldı.
- `topic.md`'ye partial işareti ekle.
- Kullanıcıya "kota yetmedi, `_topics/<konu>/state.json` kaldığı yer.
  `/resume-topic <konu>` ile devam edebilirsin." de.

Otomatik retry YOK (P5). Kullanıcı elle başlatır.

---

## Hata davranışı

Bir subagent başarısız olursa:
- Konuyu **çökertme.** O dalı `partial: true` ile işaretle.
- state.json'a yaz: hangi subagent hata verdi.
- `status: in_progress` kalır (hata yüzünden, `error` değil — error sistem
  hatası demek; subagent failure resumable).
- Diğer subagent'lar devam eder.

Sistem hatası (örn: docker MCP down): `status: error`, dur.

---

## Çıktı

Sonunda kullanıcıya **5 cümleyi geçmeyen** özet ver:
- Kaç sayfa eklendi
- Kaç boşluk açıldı, kaçı blocker
- Hangi çelişkiler open kaldı
- Hangi kaynaklar scam-suspect işaretlendi
- Status: done mu in_progress mı (in_progress ise resume nasıl)

---

## Kurallar

- **ASLA tek seferde tüm subagent'ları kendi context'ine çağırma** (M9).
  Sırayla dispatch et, formatlı çıktıyı al, kendinden çıkar.
- **Tam web fetch'leri kendi context'ine alma** (P2). Subagent'lar formatlı
  bulgu döner, sen onu işlersin.
- **Token bütçesi 50 turn.** 40'a geldiğinde graceful stop.
