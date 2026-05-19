# openPkb vault

Bu vault'u Obsidian ile aç. Sol panelde aşağıdaki yapıyı göreceksin.

## Klasörler

- `_raw/` — Ham kaynaklar. Agent buraya yazıyor, sen okuyabilirsin
  ama edit etme. Bir iddiayı tartışırken orijinal kaynağa bakmak için.
- `_wiki/` — Agent'ın senin için yazdığı sayfalar. Concept, entity, claim,
  question, contradiction sayfaları. Birbirine wikilinks ile bağlı.
- `_topics/` — Aktif araştırma konuların. Bir konu açmak için `example-*.md`
  şablonunu kopyala, status'u `active` yap.
- `_digests/` — Her sabah agent'ın bıraktığı özet. `YYYY-MM-DD.md`.

## İlk açılışta yap

1. **Graph view'i aç.** Sağ üstte üç-daire ikonu, ya da `Ctrl+G` / `Cmd+G`.
2. **Group renkleri kur.** Graph ayarlarında "Groups" → yeni grup ekle:
   - `["type":"concept"]` → mavi
   - `["type":"question"]` → sarı
   - `["type":"contradiction"]` → kırmızı
   - `["type":"entity"]` → gri
   Bu sayede graph'a baktığında sarılar (boşluklar) ve kırmızılar
   (çelişkiler) hemen göze çarpar.
3. **Dataview plugin'i yükle** (Community plugins → Dataview).
   `_open_questions.md` ve `_digests/` dosyaları Dataview query'leri kullanır.
4. **(Opsiyonel) InfraNodus plugin'i yükle.** Graph'ta küme analizi ve
   "burada bağlantı eksik" tespiti için.

## İlk konu nasıl açılır

`_topics/example-tiktok-marketing.md` dosyasını kopyala, ismini değiştir,
içindeki frontmatter'da:
- `slug:` dosya adıyla aynı yap
- `status:` → `active`
- `description:` → ne araştırmak istediğin

Sonraki gece 02:00'de cron (launchd/crontab) bu konuyu işlemeye başlayacak.
Sabah `_digests/` altında o gün ne olduğunu göreceksin.

## Manuel komut

Eğer beklemek istemiyorsan, terminalde:
```bash
cd ~/openpkb
claude -p "/deep-research <senin-konu-slug>"
```

## Senin asla dokunmaman gereken yerler

- `_raw/` — ajan'ın kanıt deposu
- `.obsidian/` (kendi config'in tabii, ama agent buna dokunmaz)

## Senin tek başına yapacağın şeyler

- Yeni topic dosyası açmak
- Bir sayfayı `status: locked` işaretlemek (agent üstüne yazmaz)
- Çelişki sayfasında "ben bunu çözdüm, A doğru" diye karar vermek
- Scam-suspect olarak işaretlenen birinin aslında güvenilir olduğunu
  söylemek (`verified-safe: true`)
