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

## Project & Dotfile Rules
- **Sensitive Configs**: Jaga agar `config/config.json`, `config/mcp_config.json`, dan `antigravity-cli/settings.json` tetap disanitasi di git publik dan gunakan `git update-index --skip-worktree` untuk konfigurasi lokal.
- **Symlinks**: Gunakan `install.sh` untuk menghubungkan konfigurasi repositori ke direktori `~/.gemini/`.
