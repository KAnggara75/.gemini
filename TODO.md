# Project TODO & Technical Debt

Dokumen ini menginventarisasi technical debt, peluang peningkatan arsitektur, dan item pekerjaan yang perlu diperhatikan di repositori `.gemini`.

---

## 1. Immediate Tasks
_Peningkatan atau perbaikan yang relevan dengan stabilitas dan konsistensi sistem saat ini._
- [ ] [`install.sh`](file:///Users/i/work/KAnggara75/.gemini/install.sh): Uji perilaku instalasi pada mesin baru jika direktori `~/.gemini/` belum ada sama sekali untuk memastikan pembuatan parent direktori berjalan mulus.
- [ ] [`antigravity-cli/statusline.sh`](file:///Users/i/work/KAnggara75/.gemini/antigravity-cli/statusline.sh): Tambahkan pembersihan berkala untuk file cache sementara di `/tmp/antigravity_*` agar tidak menumpuk saat session berganti ID.

---

## 2. Existing Code Annotations (TODO / FIXME)
_Catatan perbaikan atau peringatan teknis dari source code:_
- Tidak ditemukan marker `TODO` atau `FIXME` yang belum diselesaikan pada source code shell scripts dan python scripts repositori ini (kode dalam status clean).

---

## 3. Technical Debt & Structural Improvements
_Pekerjaan arsitektural jangka panjang untuk meningkatkan keandalan dan fleksibilitas dotfile:_
- [ ] **Cross-Platform Compatibility**: Saat ini pemutaran audio di hooks dan statusline mengandalkan `afplay` bawaan macOS. Jika di kemudian hari digunakan di Linux, perlu ditambahkan fallback (misalnya `aplay` atau `paplay`).
- [ ] **Multi-Session Isolation**: Pastikan cache `/tmp/antigravity_skill_mcp_${CLEAN_ID}.json` selalu terikat unik dengan `$TMUX_PANE` atau `$CONV_ID` saat menjalankan beberapa sesi CLI paralel secara bersamaan.
- [ ] **Automated Linting**: Pertimbangkan untuk menambahkan script linting bash (`shellcheck`) ke dalam pipeline lokal atau skill untuk memvalidasi script shell secara otomatis sebelum commit.
