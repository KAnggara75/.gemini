# Antigravity Workspace Guidelines

## RTK (Rust Token Killer)
Token-optimized CLI proxy (menghemat 60-90% token pada operasi dev).

### Usage & Meta Commands
- Semua perintah shell standar (misal: `git status`, `ls`, `grep`) otomatis ditulis ulang via hook (`rtk <cmd>`).
- Gunakan `rtk` langsung untuk meta-commands berikut:
  ```bash
  rtk gain              # Analisis penghematan token
  rtk gain --history    # Riwayat perintah dan penghematan
  rtk discover          # Temukan potensi penghematan
  rtk proxy <cmd>       # Eksekusi raw command tanpa filter
  ```

### Verification
```bash
rtk --version         # rtk X.Y.Z
which rtk             # Verifikasi binary RTK aktif
```

---

## Context7 MCP
Gunakan Context7 MCP saat membutuhkan dokumentasi terkini untuk library, framework, SDK, API, CLI tool, atau cloud service.

### Scope
- **Gunakan untuk**: API syntax, konfigurasi, migrasi versi, debugging spesifik library, setup/instalasi.
- **Jangan gunakan untuk**: Refactoring umum, logika bisnis dasar, code review, atau scripting scratch umum.

### Workflow
1. **Resolve ID**: Panggil `resolve-library-id` (`libraryName`, `query`) untuk mendapatkan library ID format `/org/project`.
2. **Select ID**: Pilih hasil terbaik berdasarkan kemiripan nama, deskripsi, snippet count, dan benchmark score.
3. **Query Docs**: Panggil `query-docs` dengan library ID spesifik dan query fokus per-konsep.
4. **Answer**: Jawab dengan merujuk dokumentasi resmi yang didapat.

---

## Workspace Skills Catalog
Skill tersimpan di `skills/` dan tertaut ke `~/.agents/skills/`:
- **`ka-git-commit`**: Conventional Commit generator & runner. Mendukung mode instan:
  - `commit A` / `commit 1/1` -> Langsung eksekusi commit per-file satu per satu tanpa dialog.
  - `commit B` / `commit all` -> Langsung eksekusi single combined commit tanpa dialog.
  - Single file changed -> Otomatis dieksekusi tanpa konfirmasi.
- **`ka-pr`**: Otomasi pembuatan Pull Request ke Bitbucket Server On-Premise via REST API tanpa hardcoding host/project/repo.
- **`ka-del-conversation`**: Inspeksi dan pembersihan database histori percakapan Antigravity/CLI/IDE via Python & SQLite.
- **`ka-context`**: Bootstrap project memory, arsitektur sistem, ADR, dan tracking technical debt.

---

## Project & Dotfile Rules
- **Configuration Tracking**:
  - `antigravity-cli/settings.json` dilacak di git publik dan dilindungi oleh *self-healing symlink* di `statusline.sh`.
  - `config/config.json` dan `config/mcp_config.json` dilindungi dari kebocoran lokal via `git update-index --skip-worktree`.
- **Symlinks & Linking**:
  - Selalu jalankan `./install.sh` untuk menyinkronkan konfigurasi repositori ke direktori `~/.gemini/` dan `~/.agents/`.
  - File di repositori adalah *single source of truth* (menimpa file target jika tidak identik).

---

## Delivery Standards
- Gunakan Conventional Commits: `feat`, `fix`, `refactor`, `docs`, `test`, `chore`, `perf`, `ci`.
- Utamakan implementasi lokal (*contained*) daripada menambah runtime dependency pihak ketiga.