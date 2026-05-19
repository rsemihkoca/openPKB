---
type: queue
purpose: gap-hunter tarafından açılan tüm sorular, priority sırasında
last_processed: never
---

# Open Questions Queue

Bu dosya kuyruktur. gap-hunter subagent'ı her koşusunda buraya yeni satır ekler.
İşlenmiş sorular silinmez, `status: answered` flag'i ile altta kalır.

## Format

```
- [ ] [blocker]  [[soru-sayfasi]] (parent: <konu>, opened: <tarih>, age: Nd)
- [ ] [high]     [[soru-sayfasi]] (parent: ..., opened: ..., age: ...)
- [x] [answered] [[soru-sayfasi]] (answered: <tarih> by <subagent>)
```

## Aktif sorular

_(Henüz açık soru yok. İlk konu işlendiğinde gap-hunter buraya yazacak.)_

## Cevaplanmış (son 7 gün)

_(boş)_

## Arşiv (7+ gün)

_(boş)_
