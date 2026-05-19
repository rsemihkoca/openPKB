openpkb/
├── .claude/
│   ├── agents/                    ← subagent tanımları
│   │   ├── researcher.md
│   │   ├── verifier.md
│   │   ├── contradiction-finder.md
│   │   ├── gap-hunter.md
│   │   └── source-trust.md
│   ├── commands/                  ← slash command'lar
│   │   ├── deep-research.md
│   │   ├── morning-digest.md
│   │   └── topic-queue.md
│   └── settings.json              ← MCP server allowlist
├── .hermes/
│   ├── soul.md                    ← agent kimliği
│   └── cron.md                    ← gece job'ları
├── vault/                         ← Obsidian buraya açılır
│   ├── _raw/                      ← immutable kaynaklar
│   ├── _wiki/                     ← LLM'in ürettiği sayfalar
│   ├── _topics/                   ← aktif araştırma konuları
│   ├── _digests/                  ← her sabahki özet
│   └── .obsidian/
├── CLAUDE.md                      ← schema + kurallar
├── README.md
└── .env.example