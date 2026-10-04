# AGENTS.md — Workspace Guidelines & Architecture Entry

Selamat datang di repositori `.gemini`. File ini adalah panduan utama bagi AI pair programmer dan subagent yang bekerja di repositori ini.

---

## 1. Quick Navigation & Project Memory (`.context/`)

Baseline memory proyek, arsitektur, dan keputusan teknis tersimpan rapi di dalam direktori [`.context/`](file:///Users/i/work/KAnggara75/.gemini/.context/):

- [`.context/PROJECT_CONTEXT.md`](file:///Users/i/work/KAnggara75/.gemini/.context/PROJECT_CONTEXT.md) — Gambaran umum tujuan sistem, batasan domain, aktor utama, dan environment runtime.
- [`.context/ARCHITECTURE.md`](file:///Users/i/work/KAnggara75/.gemini/.context/ARCHITECTURE.md) — Diagram arsitektur komponen, alur request/data flow, model konkurensi, dan mitigasi file write.
- [`.context/CODEBASE_MAP.md`](file:///Users/i/work/KAnggara75/.gemini/.context/CODEBASE_MAP.md) — Peta modul, responsibilitas per direktori, ketergantungan internal/eksternal, dan konsumen.
- [`.context/DECISIONS.md`](file:///Users/i/work/KAnggara75/.gemini/.context/DECISIONS.md) — Architecture Decision Records (ADR) historis (*append-only*).
- [`.context/TODO.md`](file:///Users/i/work/KAnggara75/.gemini/.context/TODO.md) — Daftar technical debt, pekerjaan tertunda, dan catatan perbaikan.

---

## 2. Core Operational Rules

### RTK (Rust Token Killer)
- Token-optimized CLI proxy aktif via hook untuk menghemat 60–90% token pada operasi dev.
- Perintah shell standar (`git status`, `ls`, `grep`, dll.) otomatis diproses lewat `rtk <cmd>`.
- Gunakan `rtk proxy <cmd>` untuk eksekusi perintah mentah tanpa filter jika diperlukan.

### Context7 MCP
- Gunakan Context7 MCP (`resolve-library-id`, `query-docs`) saat membutuhkan dokumentasi terkini untuk pustaka, framework, API, atau cloud service.

### Workspace Skills Catalog
Skill tersimpan di `skills/` dan disinkronkan ke `~/.agents/skills/`, `~/.gemini/antigravity-cli/skills/`, dan `~/.gemini/config/skills/`:
- **`ka-git-commit`**: Conventional Commit generator & runner (mendukung mode instan `commit A` / `commit 1/1` dan `commit B` / `commit all`).
- **`ka-pr`**: Otomasi pembuatan Pull Request ke Bitbucket Server On-Premise via REST API.
- **`ka-del-conversation`**: Utilitas inspeksi dan pembersihan database histori percakapan Antigravity/CLI/IDE via Python & SQLite.
- **`ka-context`**: Bootstrap project memory, arsitektur sistem, ADR, dan pelacakan technical debt ke direktori `.context/`.

---

## 3. Project & Dotfile Rules

- **Source of Truth**: File di dalam repositori ini adalah *single source of truth*. Selalu jalankan `./install.sh` untuk menyinkronkan konfigurasi ke `~/.gemini/` dan `~/.agents/`.
- **Sensitive Configurations**:
  - `antigravity-cli/settings.json` dilacak di git publik dan diproteksi oleh *self-healing symlink* di `statusline.sh`.
  - `config/config.json` dan `config/mcp_config.json` dilindungi dari kebocoran lokal via `git update-index --skip-worktree`.
  - Token kredensial lokal (`oauth_creds.json`, `~/.gemini/accounts/`) tidak boleh dilacak ke repositori publik.

---

## 4. Delivery Standards
- Gunakan Conventional Commits: `feat`, `fix`, `refactor`, `docs`, `test`, `chore`, `perf`, `ci`.
- Utamakan implementasi lokal (*contained*) daripada menambah runtime dependency pihak ketiga.
