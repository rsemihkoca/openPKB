İyi yakaladın — kod üretmeden önce "ne istiyorsun → bu sistem nasıl karşılıyor" diye düzgün bir spec çıkmadan ilerlemek aptalca olurdu. Geri çekiliyorum, repo iskeleti dursun ama henüz kullanma — önce şunu beraber netleştirelim.

Sana attığın metni dikkatli okudum, biraz da satır arasından çıkardım. Aşağıda istekleri ham haliyle değil, ürün spec'i gibi ayırıyorum.

---

## Bölüm 1 — Sen ne istiyorsun (senin metninden derlenmiş)

### Ana problem
Claude Code'la bir konu üzerinde çalışırken (mesela bir app tasarımı), bir sonraki adımı atabilmek için pek çok yan araştırma gerekiyor. Bu yan araştırmalar şu an manuel: sen soruyorsun, CC cevaplıyor, sen bir sonrakini soruyorsun. Bu hem yavaş, hem akış kesici, hem de CC'nin "boş" saatleri (gece) heba oluyor.

İstediğin şey, bir konu verdiğinde CC'nin **arka planda** o konuya dair **çevresel bilgi bulutunu** kendiliğinden oluşturması. Sen sabah uyandığında konunun etrafındaki "boş" alanlar dolmuş, kaynaklı, doğrulanmış, çelişkileri işaretlenmiş bir şekilde Obsidian'da hazır olsun.

### Hedef davranışı tek cümleyle
"Bir konu ver, kendi başına dallandırsın, doğrulasın, çelişkileri tartsın, scam kaynakları işaretlesin, Obsidian'a graph olarak yerleştirsin, gece çalışsın, sabaha hazır olsun."

### MUST'lar (sistemin bunlar olmadan değeri sıfır)

**M1 — Async / arka plan çalışma.** Sen oradayken değil, sen yokken de çalışmalı. Senin saat 14:00'te verdiğin bir konuyu gece 02:00'de işlemeli.

**M2 — Konu → otomatik dallandırma.** Sen "TikTok marketing araştır" dediğinde, sistem bunu kendiliğinden parçalara ayırmalı: hesap hijyeni, slideshow patternları, FYP algoritması, ilgili creator'lar, Twitter'daki tartışmalar. Sen tek tek listelemeden.

**M3 — Çoklu kaynak doğrulama.** Bir iddia tek bir yerde geçiyorsa "iddia". Üç bağımsız yerde geçiyorsa "doğrulanmış". Sistem bu farkı kendisi tutmalı, sen sormadan.

**M4 — Karşıt görüşleri silmeden saklama.** Eğer iki kaynak çelişiyorsa, biri ezilmemeli. İkisi de görünür kalmalı, hangi koşulda hangisinin geçerli olduğu işaretlenmeli.

**M5 — Scam / kaynak güvenilirliği taraması.** Bir bilgiyi creator X'ten aldıysa, sistem X'in güvenilir olup olmadığını kullanıcıya söylemeden ARAŞTIRIP işaretlemeli. Kullanıcı "bu adam gerçek mi" diye sormak zorunda kalmamalı.

**M6 — Boşluk avcılığı (sünger metaforu).** Bir konuyu işlerken "ama burası boş" diyen yerleri sistem kendi kendine fark etmeli ve cevaplamalı. "Üçüncü parti API kullan denildi → hangisi en iyi" gibi yan boşluk → otomatik araştırma konusu olmalı, sen sormadan.

**M7 — Bir sonraki adımı engelleyen boşluk öncelikli.** Tüm boşluklar eşit değil. Senin bir sonraki aksiyonu atamadığın boşluk birinci sırada. Geri kalan nice-to-have.

**M8 — Obsidian'a graph yapısında kaydetme.** Sayfa sayfa metin değil. Konular, alt başlıklar, kavramlar birbirine bağlı node'lar ve leaf'ler olarak. Obsidian'ın graph view'inde görsel olarak izlenebilmeli.

**M9 — Async subagent paralellik.** Farklı alt-konular birbirini beklemesin. researcher TikTok hijyeni bakarken, ayrı bir subagent slideshow patternlarını çekiyor olabilmeli. Bittiğinde context'i olan ana agent her birini doğru yere koyuyor.

**M10 — Context erime, meta kalıcı.** Sistem her şeyi sonsuza dek context'inde tutmasın (zaten kalmaz). Ama her dökümanın META bilgisi (özet, etiket, kaynak, trust derecesi) kalıcı olmalı — sonradan lazım olursa o nodeyi açıp tam metni okumak için.

**M11 — Twitter ve sosyal kaynak entegrasyonu.** Sadece makale değil. Twitter sörfü yapacak, tweet'leri ve thread'leri kaynak olarak işleyecek, TikTok hesaplarını analiz edecek.

### SHOULD'lar (olsa harika ama olmasa çalışır)

**S1 — Doğal dil cron.** Türkçe "her gece 02:00'de aktif konuları araştır" diyebilesin, sistem cron'a çevirsin.

**S2 — Mobil bildirim.** Sabah uyanmadan, sistem Telegram'a "gece şunlar değişti, şu çelişki açıldı" digest'i atsın.

**S3 — Learning loop.** Sistem zaman içinde senin tercihlerini öğrensin — hangi kaynaklara güvenmediğin, hangi formatı sevdiğin, hangi konuları geçtiğin gibi.

**S4 — Graph görselleştirme.** Sadece Obsidian native graph değil, konu kümeleri arası "burada boşluk var" diyen analytics de olsun (InfraNodus gibi).

**S5 — Manuel müdahale noktası.** Sistem otonom çalışsın ama sen bir trust kararını veya bir çelişki sayfasını manuel olarak override edebilmelisin.

**S6 — Geri alınabilirlik.** Bir gece kötü gitti diye vault çöp olmasın. Git history üzerinde olmalı, geri alabilmelisin.

### NICE-TO-HAVE'lar (sonraki versiyonlar)

**N1** — Marp slide üretimi (araştırma sonucundan sunum çıkarma).
**N2** — Çoklu vault (iş / kişisel ayrımı).
**N3** — Çoklu dil kaynakları (Türkçe + İngilizce harmanlanmış research).
**N4** — Sesli özet (Telegram'a sabah voice note olarak).

---

## Bölüm 2 — Bu istekler nasıl karşılanıyor

Her MUST'u hangi mekanizmanın karşıladığını eşliyorum. Burası "kod" değil, mimari mantık.

### M1 (Async çalışma) → **openPkb** karşılıyor
openPkb built-in scheduler'la geliyor. Gateway daemon 60 saniyede bir tick atıyor, gece 02:00'de bekleyen job'u çalıştırıyor, Claude Code'u headless modda tetikliyor. CC normalde sen yazana kadar bekleyen bir TUI — openPkb onu "sen olmadan da iş başlat" yapan üst katman.

### M2 (Konu → dallandırma) → **`/deep-research` slash command + plan turn'ü**
Bir konuyu işlerken CC ilk turn'ünde sadece **plan** çıkartır: "Bu konuyu 5 alt-konuya böldüm, ilk üçü blocker, son ikisi nice-to-have." Sonraki turn'lerde her alt-konuyu paralel subagent'lara delege eder. Sen tek tek listelemiyorsun çünkü orchestrator agent bu dallandırmayı kendi yapıyor.

### M3 (Çoklu kaynak doğrulama) → **`verifier` subagent**
Researcher topladıktan sonra, verifier her iddiayı tek başına alıyor, primary source dışındaki en az 2 bağımsız domain'de teyit aramaya gidiyor. Sonucu sayfa frontmatter'ındaki `trust:` değerine yazıyor. Sen sormuyorsun, o yapıyor.

### M4 (Karşıt görüşler) → **`contradiction-finder` subagent + `[!contradiction]` callout**
Iki kaynak çelişiyorsa, ana sayfaya callout düşüyor, ayrıca `_wiki/contradictions/` altında ayrı bir sayfa açılıyor. Iki pozisyon yan yana, kim hangi koşulda haklı. Kullanıcı için karar verilmez — sadece bilgi sunulur.

### M5 (Scam taraması) → **`source-trust` subagent**
Her yeni creator/domain/hesap için tek seferlik bir trust profili çıkarıyor. Yeşil/sarı/kırmızı sinyaller. Sonuç `_wiki/sources/` altında bir sayfa olarak duruyor; o kaynaktan gelen sonraki bilgiler bu trust derecesine göre işlem görüyor.

### M6 + M7 (Boşluk avcılığı) → **`gap-hunter` subagent + `_open_questions.md` kuyruğu**
Bu sistemin **kalbi**. Diğer subagent'lar bilgi getirir; gap-hunter mevcut wiki'yi tarayıp **hangi soruların açıkta kaldığını** buluyor. Her boşluk bir `type: question` sayfası, priority alanı blocker/high/nice-to-have. Kuyruk işlenirken blocker'lar başa alınıyor. Senin "bir sonraki adımı atamıyorsam orası doldurulmalı" cümlesinin birebir karşılığı bu.

### M8 (Graph yapısı) → **LLM Wiki pattern + Obsidian wikilinks + InfraNodus MCP**
Üç katmanlı: `_raw` (ham kaynak, dokunulmaz), `_wiki` (kavram/entity/claim/question sayfaları), `CLAUDE.md` (şema). Her sayfa diğer sayfalara `[[wikilink]]` ile bağlanıyor — Obsidian bunu otomatik graph view'de gösteriyor. InfraNodus MCP ek olarak "küme arası eksik bağlantı" analizini yapıyor (graph üzerinden gap detection).

### M9 (Paralel subagent) → **Claude Code subagents (`.claude/agents/`)**
Her subagent kendi izole context window'unda çalışıyor. Ana orchestrator "researcher TikTok hijyeni, researcher slideshow, source-trust @creator-x'i incele" diye paralel dispatch ediyor. Hepsi bittiğinde sadece özetleri orchestrator'a dönüyor — orchestrator'ın context'i şişmiyor.

### M10 (Context erime, meta kalıcı) → **Frontmatter + index + hot cache**
Her sayfanın frontmatter'ında summary, sources, tags, trust var. Orchestrator bir konuyu açtığında önce tüm sayfaların frontmatter'larını okuyor (cheap), sadece gerçekten lazım olanın gövdesini açıyor (expensive). Tam metin context'e girmiyor, meta hep elinin altında.

### M11 (Twitter / sosyal) → **BrowserAct MCP veya X API MCP**
Twitter'ın API'sı kısıtlı. İki yol var: ya official X API MCP'si (rate-limited, ücretli), ya da BrowserAct gibi headless browser MCP'si (anti-bot katmanları aşar, scraping yapar). researcher subagent bu MCP'leri kullanarak tweet ve thread çekiyor.

### S1 (Doğal dil cron) → openPkb'in cron özelliği
Türkçe "her gece 02:00'de" yazıyorsun, openPkb cron expression'a çeviriyor, `~/.openPkb/cron/jobs.json` altına yazıyor.

### S2 (Telegram digest) → openPkb gateway
openPkb'in Telegram/Discord/Slack gateway'i var. `/morning-digest` slash command çıktısı Telegram'a otomatik gidiyor.

### S3 (Learning loop) → openPkb'in skill-creation döngüsü
openPkb her ~15 tool call'da bir kendini reviewlayıp yeni bir skill dosyası üretiyor. Senin sürekli tekrarladığın kararlar (kaynak whitelist, format tercihi) zamanla skill dosyalarına dönüşüyor.

### S4 (Graph analytics) → InfraNodus MCP
Sadece Obsidian'ın native graph view'i değil, küme bazlı gap analizi de var.

### S5 (Manuel override) → Frontmatter `status: locked` alanı
Bir sayfayı manuel düzelttiğinde `status: locked` koyuyorsun, agent bir daha üstüne yazmıyor.

### S6 (Geri alınabilirlik) → Git
Vault zaten bir git repo. Her gece job'u başlangıçta commit atıyor, kötü gittiyse `git reset` yetiyor.

---

## Bölüm 3 — Klasör ağacındaki her şey neden var

Sen "neden gerekli" diye sorduğun için her klasörün karşıladığı MUST'u/SHOULD'u eşliyorum.

```
openpkb/
├── CLAUDE.md             → Claude Code'un her oturumda okuduğu ANAYASA.
│                            Sayfa türlerini, kuralları, dosya disiplinini buraya yazıyoruz.
│                            Karşıladığı: M4, M10, sistemin tutarlılığı.
│                            Bu dosya olmadan CC her oturumda farklı format yazar,
│                            wiki çorbaya döner.
│
├── .claude/
│   ├── agents/           → Subagent tanımları. Her .md dosyası bir uzman.
│   │   ├── researcher.md          → M2, M11 (toplama)
│   │   ├── verifier.md            → M3 (doğrulama)
│   │   ├── contradiction-finder.md → M4 (çelişki)
│   │   ├── gap-hunter.md          → M6, M7 (boşluk)
│   │   └── source-trust.md        → M5 (scam)
│   │
│   │   Neden ayrı dosyalar? Çünkü her biri farklı tool izniyle çalışıyor.
│   │   Mesela researcher web'e çıkar (WebFetch izinli), ama gap-hunter
│   │   web'e çıkmaz (WebFetch yasak) — sadece mevcut wiki'yi tarar.
│   │   Bu izolasyon M9'u (paralellik) ve güvenliği (M5'in yan etkisi) sağlıyor.
│
│   ├── commands/         → Sen veya openPkb'in tetikleyeceği slash command'lar.
│   │   ├── deep-research.md       → "/deep-research tiktok marketing" → tam akış
│   │   ├── morning-digest.md      → Gece sonu özet üretir
│   │   └── topic-queue.md         → Açık konuları listeler
│   │
│   │   Bunlar olmadan her gece openPkb'in CC'ye uzun uzun prompt yazması
│   │   gerekirdi. Slash command'lar tekrar eden iş akışlarını isimlendiriyor.
│
│   └── settings.json     → Hangi MCP server'ların açık olduğu, hangi tool'ların
│                            global yasak olduğu. Güvenlik katmanı.
│
├── .openPkb/
│   ├── soul.md           → openPkb agent'ın "kimliği". Hangi karakterde, hangi
│   │                       önceliklerle çalıştığı. M1'in kalitesini etkiler.
│   └── cron.md           → Hangi job hangi saatte. S1'in tanımı.
│
├── vault/                → Obsidian buraya açılır. M8'in fiziksel karşılığı.
│   ├── _raw/             → Ham kaynaklar. Asla edit edilmez.
│   │                       M3 için zorunlu: bir iddiayı tartışırken
│   │                       orijinal kaynağa geri dönebilmeliyiz.
│   │
│   ├── _wiki/            → LLM'in ürettiği sayfalar. Concept, entity, claim,
│   │                       question, contradiction tipinde sayfalar.
│   │                       M4, M6, M8, M10'un birleşim yeri.
│   │
│   ├── _topics/          → Aktif araştırma konuları. _open_questions.md ve
│   │                       _warnings.md burada. Gece job'u sadece status:active
│   │                       olanları işliyor → M7'nin önceliklendirmesi.
│   │
│   ├── _digests/         → 2026-05-20.md gibi günlük özetler. S2'nin kaynağı.
│   │
│   └── .obsidian/        → Obsidian uygulamasının config'i (plugin'ler,
│                            graph view ayarları). Sen Obsidian'da açtığında
│                            graph hazır gelsin diye.
```

---

## Akış birkaç cümleyle

Sen saat 14:00'te diyorsun ki "TikTok marketing araştır, tarih app'im için." `_topics/tiktok-marketing.md` açılıyor, status: active.

Saat 02:00'de openPkb uyanıyor. `_topics/` altında active olan dosyaları listeliyor. Her biri için CC'yi headless modda tetikliyor: `claude -p "/deep-research tiktok-marketing"`.

CC orchestrator olarak çalışıyor. Önce konuyu dallandırıyor (hijyen, slideshow, FYP, creator'lar). Sonra researcher'ı 4 paralel kopya halinde fırlatıyor — her biri bir alt-konuya. Tweetler, makaleler, transcriptler `_raw/`'a düşüyor.

Sonra sırayla: verifier her iddiayı tarıyor, çapraz doğrulama. contradiction-finder çelişen iddiaları yakalayıp ayrı sayfalara koyuyor. source-trust her yeni creator için scam profili çıkarıyor. gap-hunter her şey bittiğinde tüm mahsulü tarayıp "burada açık soru var" diyen yerleri `_open_questions.md`'ye blocker/high/nice-to-have sırasıyla diziyor.

Sabah 07:00'de openPkb `/morning-digest`'i çağırıyor. Çıktı Telegram'a düşüyor: "Gece TikTok marketing için 12 sayfa eklendi, 2 çelişki açıldı (biri open, biri context-dependent), 4 blocker soru hâlâ açık, creator X için trust: scam-suspect."

Sen uyanıyorsun, Obsidian'ı açıyorsun, graph view'inde gece büyümüş ağı görüyorsun. Blocker sorulara bakıyorsun — bir sonraki adımını ona göre atıyorsun.

---
