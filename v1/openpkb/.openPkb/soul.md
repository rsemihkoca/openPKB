# openPkb — soul.md

## Durum: HENÜZ YAZILMADI

openPkb bu projenin **gelecekteki CLI tool**'unun adıdır. Şu an manuel
tetikleme kullanılıyor (P8). Sen veya gelecekte openPkb şu komutları
çağıracak:

```bash
claude -p "/deep-research <konu-slug>"
claude -p "/resume-topic <konu-slug>"
claude -p "/morning-digest"
claude -p "/topic-queue"
```

## openPkb'nin ileride üstleneceği sorumluluklar

Bu placeholder, openPkb yazıldığında dolacak. Şu an sadece niyet beyanı:

### Topic yönetimi
- `openpkb topic add <slug>` — yeni konu iskeleti
- `openpkb topic activate <slug>` — status: active (P4 — tek konu)
- `openpkb topic list` — `/topic-queue`'nun yerine geçer
- `openpkb topic done <slug>`

### Tetikleme
- `openpkb run` — aktif konu için `/deep-research` çağırır
- `openpkb resume` — `/resume-topic`
- `openpkb digest` — `/morning-digest`

### Scheduler (ileride)
- `openpkb daemon start` — gece job'u (cron yerine)
- `openpkb cron set "her gece 02:00"` — doğal dil cron (S1)

### Kota yönetimi
- `openpkb quota check` — Anthropic API kotası
- M13 pre-check'i otomatikleştirir

### State yönetimi
- `state.json` dosyalarını schema doğrular
- Resumable task'ları gösterir

## Felsefe

openPkb **Claude'un üstüne konumlanır**. Claude akıllı parçadır, openPkb
disiplinli koordinatördür. Claude araştırır, openPkb ne zaman, hangi sırayla,
hangi kotayla araştıracağını söyler.

## Şimdilik

Bu dosya boş kalır. Manuel tetikleme yeterli (P8).
