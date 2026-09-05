---
name: ka-del-conversation
description: "Pembersih dan pengelola riwayat percakapan Antigravity (CLI, IDE, dan Core). Mendukung daftar percakapan, filter umur (misal: > 30 hari), simulasi dry-run, seleksi nomor individual/rentang, dan penghapusan permanen artefak percakapan."
user-invocable: true
license: MIT
compatibility: Designed for Antigravity AI, Antigravity CLI, and macOS/Linux shells.
metadata:
  version: "1.0.0"
allowed-tools: Bash(clean-conversations:*) Bash(python3:*) Read Grep Glob
---

# Antigravity Conversation Cleaner & Manager

Skill ini digunakan untuk menginspeksi, memfilter, dan menghapus percakapan dari Antigravity (`antigravity`, `antigravity-cli`, `antigravity-ide`) secara aman dan terstruktur.

Skill ini memanfaatkan wrapper CLI `clean-conversations` (atau backend script internal skill `clean-conversations.sh` / `scripts/clean_conversations.py`).

## Lingkup Artefak yang Dikelola
Saat percakapan dihapus, skill/script membersihkan seluruh jejak percakapan terkait:
1. Database SQLite percakapan & WAL/SHM (`conversations/<id>.db*`).
2. Folder artefak dan brain AI (`brain/<id>/`).
3. Database ringkasan global (`antigravity-cli/conversation_summaries.db`).
4. File anotasi & thumbnail jika ada (`annotations/<id>*`).

---

## Cara Penggunaan & Workflow

### 1. Menampilkan Daftar Percakapan Aktif
Gunakan flag `-l` atau `--list` untuk melihat daftar percakapan tanpa menghapus:
```bash
clean-conversations --list
```
Atau jika binary belum terpasang di PATH:
```bash
skills/ka-del-conversation/clean-conversations.sh --list
```

### 2. Menghapus Percakapan Berdasarkan Umur (Misal: > 30 Hari)
Hapus percakapan yang tidak aktif lebih dari 30 hari:
```bash
# Simulasi terlebih dahulu (Dry-run)
clean-conversations -o 30 -n

# Eksekusi langsung dengan konfirmasi
clean-conversations -o 30

# Eksekusi langsung tanpa tanya (Force)
clean-conversations -o 30 -f
```

### 3. Filter Berdasarkan Sub-Aplikasi Tertentu
- **Hanya Antigravity CLI**:
  ```bash
  clean-conversations --cli -l
  ```
- **Hanya Antigravity IDE**:
  ```bash
  clean-conversations --ide -l
  ```
- **Hanya Antigravity Core / Hub**:
  ```bash
  clean-conversations --core -l
  ```

### 4. Mode Interaktif (TUI / Terminal)
Jika dijalankan tanpa argumen penghapusan langsung, tool akan membuka menu interaktif:
```bash
clean-conversations
```

#### Kontrol Navigasi Cepat (Tanpa Perlu Tekan Enter):
- `n`: Pindah ke halaman berikutnya (*Next page*)
- `p`: Pindah ke halaman sebelumnya (*Previous page*)
- `o`: Otomatis cari & pilih semua percakapan yang lebih lama dari 30 hari
- `d`: Masuk mode input nomor percakapan untuk dihapus
- `1-9` (angka langsung): Ketik angka langsung untuk memilih nomor percakapan
- `q` atau `Esc`: Keluar dari program

#### Format Pemilihan Nomor:
- Nomor tunggal: `3`
- Multiple: `1, 4, 7`
- Rentang (Range): `2-5`
- Kombinasi: `1, 3-5, 8`
- Semua percakapan: `all`

#### Konfirmasi Penghapusan:
- Tekan `Enter` atau `y`: Langsung hapus
- Tekan `Esc`, `q`, atau `n`: Batalkan dan kembali ke daftar

---

## Opsi Perintah Lengkap (CLI Reference)

| Parameter | Alias | Deskripsi |
| :--- | :--- | :--- |
| `-l` | `--list` | Hanya tampilkan daftar percakapan |
| `-o <DAYS>` | `--older-than <DAYS>` | Pilih percakapan yang lebih lama dari `DAYS` hari |
| `--delete-all` | - | Pilih SEMUA percakapan sekaligus untuk dihapus |
| `-n` | `--dry-run` | Simulasi target tanpa menghapus file fisik |
| `-f` | `-y`, `--force` | Eksekusi langsung tanpa konfirmasi interaktif |
| `--cli` | - | Batasi target hanya pada Antigravity CLI |
| `--ide` | - | Batasi target hanya pada Antigravity IDE |
| `--core` | - | Batasi target hanya pada Antigravity Core/Hub |
| `--all` | - | Targetkan seluruh aplikasi (default) |
