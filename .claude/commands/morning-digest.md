---
description: Son 24 saatte vault'ta ne değişti, hangi blocker'lar açık, hangi çelişkiler çözülmedi — günlük özet üretir.
---

Bugünün tarihi: `date +%Y-%m-%d` ile al, $TODAY olarak kullan.

## Akış

1. Git log'undan son 24 saatte değişen dosyaları çek:
   `git -C vault log --since="24 hours ago" --name-status --pretty=format:""`

2. Yeni eklenen sayfaları say (status A), düzenleneni say (status M).
   Türüne göre dağılımı çıkar:
   - concept / entity / claim / question / contradiction kaç tane

3. `_open_questions.md` dosyasını oku.
   - Toplam soru
   - Priority: blocker olanlar
   - 3+ günden eski blocker'lar (acil işaret)

4. `_wiki/contradictions/` altında status: open olanları listele.

5. `_wiki/sources/` altında trust: scam-suspect yenileri çek.

6. `vault/_digests/$TODAY.md` dosyasını oluştur:

```yaml
---
date: $TODAY
generated: $TIMESTAMP
pages_added: N
contradictions_open: N
blockers_open: N
scam_warnings: N
---

# Günün özeti — $TODAY

## Eklenen sayfalar (N tane)
- [[sayfa-1]] — {bir cümlelik özet}
- [[sayfa-2]] — ...

## Açık blocker'lar ({N} tane)
1. [[soru-1]] (parent: {konu}, {kaç gün}'dür açık)
2. ...

## Çözülmemiş çelişkiler
- [[contradiction-1]] — A: ... / B: ... — status: open
- ...

## Scam uyarıları
- [[creator-x]] — {kırmızı sinyaller}

## Yarına öneriler
- {Hangi konuların gece job'una alınması mantıklı}
- {Hangi blocker'lar manuel kullanıcı kararı bekliyor}
```

7. Telegram'a bildirim isteniyorsa, launchd/cron tetikleyici dosyanın TOP HALF'ini
   `curl` ile Telegram Bot API'sine atar. Sen sadece dosyayı yazıyorsun.

## Kurallar

- Eğer bir blocker 7+ günden beri açıksa "URGENT" işareti at.
  Demek ki gece job'ları bu boşluğu kapatamıyor → kullanıcı müdahalesi.
- Dosyaları kendin yorumlama. Sadece say ve özetle.
- 24 saatte hiçbir değişiklik yoksa "quiet day" digest'i yaz — kuru ama dürüst.
