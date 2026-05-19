---
description: Verilen bir konuyu üç roundda derinlemesine araştırır. Mevcut wiki'yi sorgular, web/sosyal medyadan kaynak toplar, doğrular, çelişkileri ayıklar, boşlukları soru olarak açar.
argument-hint: <konu-slug>
---

Konu: $ARGUMENTS

Bu komut bir araştırma turnünün TAMAMINI yönetir. Sen orchestrator'sın.

## Round 1 — Mevcut bilgiyi haritala

1. `vault/_wiki/` altında konu ile ilgili sayfaları grep at.
   Sadece frontmatter ve summary oku, tam metni AÇMA.
2. `vault/_topics/<konu>.md` varsa oku, status ve önceki notları gör.
3. `vault/_topics/_open_questions.md`'de bu konuya ait soru var mı bak.
4. Bir "şu an ne biliyoruz" özeti çıkar — 5-7 cümleyi geçmesin.

## Round 2 — Dallandırma planı

Konuyu 3-6 alt-konuya böl. Her birine:
- Slug
- Bir cümlelik kapsam
- Önceliği (blocker / high / nice)
- Hangi subagent'a delege edileceği

Bunu `vault/_topics/<konu>.md` içine "plan" başlığı altında YAZ.
Plan'a sığmayan dalları aç kalsın, sonraki turnde işlenir.

## Round 3 — Paralel dispatch

PARALELE göre — sıralı değil:
- Her alt-konu için `researcher` subagent'ı ayrı çağır
- researcher'lar bitince:
  - Yeni kaynaklar üzerinde `verifier` subagent'ı çalıştır
  - Yeni creator/domain'ler için `source-trust` çağır
  - İki+ kaynak arasında çelişki sinyali varsa `contradiction-finder` çağır

Subagent'lardan dönen özetleri tek tek wiki'ye işle.
Tam metinleri SENİN context'ine alma — sadece subagent'ın özet çıktısını oku.

## Round 4 — Boşluk taraması

Tüm bilgi geldikten sonra `gap-hunter` subagent'ı çağır.
Çıktısı `_open_questions.md`'ye eklenecek yeni sorular.

## Round 5 — Topic dosyasını kapat

`vault/_topics/<konu>.md` frontmatter'ında:
- last_run: bugünün tarihi
- pages_added: sayı
- contradictions_open: sayı
- gaps_opened: sayı
- next_run: en az 1 gün sonra (boşluklar dolana kadar tekrar koşulacak)

## Kurallar

- ASLA tek seferde tüm subagent'ları kendi context'ine çağırma.
  Hepsini sırayla dispatch et, özetlerini al, kendinden çıkar.
- Bir subagent başarısız olursa konuyu çökertme — o dalı `partial: true`
  ile işaretle, gece tekrar dene.
- Token bütçesi: orchestrator için 50 turn. 40'a geldiğinde durup
  o ana kadarki çıktıyı topic dosyasına yaz, geri kalanı bir sonraki
  koşuya bırak.

## Çıktı formatı

Sonunda kullanıcıya 5 cümleyi geçmeyen özet ver:
- Kaç sayfa eklendi
- Kaç boşluk açıldı, kaçı blocker
- Hangi çelişkiler open kaldı
- Hangi kaynaklar scam-suspect işaretlendi
- Bir sonraki koşu için ne kaldı
