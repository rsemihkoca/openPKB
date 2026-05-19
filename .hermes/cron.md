# Hermes cron jobs — openPkb

Bu dosya insan-okur. Gerçek cron job'ları Hermes tarafından
`~/.hermes/cron/jobs.json` altına yazılır. Bu dosya referans + doc.

## Aktif job'lar

### 1. Nightly topic research
- **Ne zaman:** Her gün 02:00 yerel saat
- **Ne yapar:** `_topics/` altındaki active konuları priority sırasına göre
  tek tek `/deep-research <slug>` ile işler.
- **Süre sınırı:** Konu başına 60 dakika, toplam pencere 4 saat (06:00'a kadar).
- **Hermes komutu:**
  ```
  Every night at 02:00 local time, run /topic-queue to get the
  prioritized list, then for each active topic in order call
  /deep-research with that topic's slug. Stop at 06:00 even if not
  all topics processed. Log to _topics/_run_log.md.
  ```

### 2. Morning digest
- **Ne zaman:** Her gün 07:00 yerel saat
- **Ne yapar:** `/morning-digest` çağırır, `_digests/YYYY-MM-DD.md` üretir.
- **Hermes komutu:**
  ```
  Every morning at 07:00 local time, run /morning-digest. If Telegram is
  connected, send the top half of the output to the configured chat.
  ```

### 3. Weekly lint
- **Ne zaman:** Her pazar 03:00
- **Ne yapar:** Orphan sayfaları, kırık linkleri, duplicate'leri bulur.
- **Hermes komutu:**
  ```
  Every Sunday at 03:00, run /wiki-lint and write report to
  _digests/_lint-YYYY-WW.md
  ```

### 4. Source re-check (3 ayda bir)
- **Ne zaman:** Her ayın 1'i, 03:00
- **Ne yapar:** `review_after` tarihi geçmiş source profile'larını yeniden tarar.
- **Hermes komutu:**
  ```
  On the 1st of every month at 03:00, find all pages in _wiki/sources/
  where review_after < today, and re-run source-trust subagent on each.
  ```

## Job hijyen kuralları

- Bir job çalışıyorken aynısını paralel başlatma. Hermes lock dosyası tutar.
- Job süre sınırını aşıyorsa SIGTERM at, partial=true ile commit at.
- Hata olursa 3 kez retry (5 dk arayla), sonra error queue'ya at.
- Her job kendi git branch'inde çalışsın (`night/YYYY-MM-DD`), sabah
  morning-digest job'u main'e merge etsin. Bu rollback'i kolaylaştırır.

## Manuel job tetikleme

Sen istersen terminalden:
```
hermes cron run nightly-topic-research --now
hermes cron run morning-digest --now
```
