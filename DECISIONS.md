# Architecture Decision Records (ADR)

Dokumen ini mencatat keputusan-keputusan arsitektur penting yang diambil dalam pengembangan repositori `.gemini`. Format bersifat **append-only** (dilarang menimpa atau menghapus keputusan yang telah disetujui sebelumnya).

---

## ADR-001: Sanitasi Konfigurasi Publik dan Perlindungan Git Worktree

- **Status**: Accepted
- **Date**: 2026-09-02
- **Source**: Developer request & Git history commit `16ebfd9` / `3924888`
- **Context**: File konfigurasi runtime seperti `config/config.json` dan `config/mcp_config.json` mengandung hostname mesin lokal dan konfigurasi internal yang rentan bocor saat repositori di-push ke GitHub publik.
- **Decision**: Menghapus hostname lokal hardcoded dan mengosongkan permission grants default pada file git, serta menggunakan `git update-index --skip-worktree` pada `install.sh` untuk file konfigurasi lokal.
- **Consequences**: Konfigurasi lokal di mesin pengembang tetap aktif tanpa risiko bocor atau ter-commit secara tidak sengaja ke publik.

---

## ADR-002: Notifikasi Suara Sistem macOS pada Permintaan Keputusan Agent

- **Status**: Accepted
- **Date**: 2026-09-09
- **Source**: Developer request & Git history commit `5a43f69` / `5d33396` / `c032c0d`
- **Context**: Developer membutuhkan penanda suara yang jelas saat agent berhenti dan memerlukan interaksi/keputusan (baik prompt perizinan shell command yang belum di-whitelist maupun tool `ask_question`).
- **Decision**: Mengintegrasikan `afplay /System/Library/Sounds/Glass.aiff` dan `osascript display notification` pada hook `BeforeTool` (`notify-decision.sh`, `rtk-hook-gemini.sh`) serta pada `statusline.sh` dengan debounce rate-limit 4 detik.
- **Consequences**: Setiap kali prompt konfirmasi atau dialog pilihan muncul, pengembang segera mendapat sinyal audio tanpa memblokir rendering proses terminal.

---

## ADR-003: Prioritas Atomic Commit (1 per 1) dan Direct Mode Trigger pada `ka-git-commit`

- **Status**: Accepted
- **Date**: 2026-09-13
- **Source**: Developer request & Git history commit `f1a24dd`
- **Context**: Menyajikan commit gabungan untuk banyak file menyulitkan review dan proses revert. Selain itu, proses konfirmasi interaktif memakan waktu ketika developer sudah mengetahui mode yang diinginkan.
- **Decision**: Menjadikan Mode A (commit atomic per-file satu per satu) sebagai rekomendasi utama default, mengotomasi auto-commit jika hanya 1 file berubah, dan mendukung direct mode triggers (misal: `commit A`, `commit 1/1`, `commit B`, `commit all`) yang langsung mengeksekusi commit secara instan tanpa dialog konfirmasi.
- **Consequences**: Riwayat git lebih bersih, terstruktur rapi per komponen file, dan alur commit jauh lebih cepat bagi developer.

---

## ADR-004: Self-Healing Symlink dan Indikator Status Sinkronisasi pada Statusline

- **Status**: Accepted
- **Date**: 2026-09-13
- **Source**: Developer request & Git history commit `9f00fda` / `de7c268`
- **Context**: Antigravity CLI menggunakan operasi atomic write (`rename()`) saat memperbarui perizinan, yang secara otomatis memutus symbolic link `settings.json` dan menjadikannya file reguler mandiri sehingga konfigurasi repo tertinggal.
- **Decision**: Menanamkan *self-healing watcher* di background subshell `statusline.sh` untuk mendeteksi pemutusan link, menyalin izin terbaru ke repo, dan memulihkan symlink secara otomatis, serta menampilkan badge status `🔗 synced` atau `⚠️ unsynced` pada statusline terminal.
- **Consequences**: Integritas dotfile terjaga secara real-time tanpa perlu intervensi manual dari developer.

---

## ADR-005: Indikator Real-Time Skill dan MCP pada Terminal Statusline

- **Status**: Accepted
- **Date**: 2026-09-13
- **Source**: Developer request & Git history commit `de7c268`
- **Context**: Pengembang ingin mengetahui secara transparan di terminal apakah agent saat ini sedang mengeksekusi skill tertentu atau sedang mengakses server MCP eksternal.
- **Decision**: Mengekstrak invocations skill dan MCP tool calls dari log transkrip percakapan terakhir dan menampilkannya di statusline baris pertama (`⚡ <skill>` dan `🔌 <mcp>`), serta menampilkan tanda strip `-` saat tidak ada skill atau MCP yang aktif di turn tersebut.
- **Consequences**: Visibilitas eksekusi agent meningkat drastis dengan overhead I/O minimal berkat sistem file caching 2 detik.
