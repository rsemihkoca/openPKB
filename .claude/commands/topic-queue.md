---
description: vault/_topics/ altındaki aktif konuları listeler ve hangisinin sırada olduğunu söyler.
---

## Akış

1. `vault/_topics/` altındaki tüm `.md` dosyalarını tara (alt çizgiyle
   başlayanlar hariç — onlar kuyruk dosyaları, konu değil).

2. Her dosyanın frontmatter'ını oku:
   - status (active / paused / done)
   - priority (blocker / high / nice)
   - last_run (en son ne zaman işlendi)
   - next_run (ne zaman tekrar işlenmeli)

3. Tablo halinde göster:

```
SLUG                        STATUS    PRIORITY   LAST_RUN     NEXT_RUN     GAPS
tiktok-marketing            active    high       2026-05-19   2026-05-20   4
app-launch-strategy         active    blocker    2026-05-18   2026-05-19   2
twitter-growth              paused    nice       2026-05-10   —            0
```

4. Sıralama:
   1. active + blocker + next_run ≤ bugün
   2. active + high + next_run ≤ bugün
   3. geri kalan active
   4. paused (en sonda)

5. Sonunda gece cron'unun (launchd/crontab, 02:00) çalıştıracağı sıraya hazır olanı söyle:

```
TONIGHT'S QUEUE (cron 02:00 tarafından koşulacak):
1. app-launch-strategy (blocker, 2 gap open)
2. tiktok-marketing (high, 4 gap open)
```

## Kurallar

- `_open_questions.md`, `_warnings.md` gibi alt çizgiyle başlayan dosyalar
  konu DEĞİL, kuyruk. Bunları listeye dahil etme.
- next_run boş ise "—" yaz, "null" değil.
- Eğer bütün konular paused veya done ise, kullanıcıya "yeni bir konu
  eklemek ister misin" diye sor.
