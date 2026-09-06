---
name: ka-context
description: "Skill ini bertujuan untuk membangun baseline dokumentasi project memory dari repositori kode yang ada. Anda akan menganalisis struktur direktori, mengidentifikasi modul inti, dan menyusun dokumentasi arsitektur serta keputusan teknis yang telah dibuat. Hasilnya akan mencakup peta codebase, diagram arsitektur, keputusan teknis, dan daftar tugas yang perlu diselesaikan."
user-invocable: true
license: MIT
compatibility: Designed for Antigravity AI, Claude Code, and git-based repositories.
metadata:
  version: "2.1.0"
allowed-tools: Bash(git:*) Bash(rtk:*) Read Grep Glob
---

# Skill: Bootstrap Project Memory & Documentation

Anda bertindak sebagai Staff Software Architect. Tugas Anda adalah menganalisis repositori ini dan menyusun baseline dokumentasi project memory.

Lakukan eksekusi dalam urutan berikut:

### Langkah 1: Eksplorasi Codebase (Read-Only)
- Analisis struktur direktori hingga kedalaman 3 level.
- Identifikasi build manifest (misal: go.mod, pom.xml, package.json).
- Deteksi framework, layer arsitektur (clean architecture, ports/adapters, MVC), dan entry point.

### Langkah 2: Generate CODEBASE_MAP.md
Buat daftar modul inti dan tanggung jawabnya secara padat:
- `cmd/` atau entry points: fungsi utama bootstrap/lifecycle.
- `internal/core` atau domain logic.
- Integrasi eksternal (Database, Kafka consumer/producer, HTTP client).

### Langkah 3: Generate Draft ARCHITECTURE.md
- Diagram relasi komponen (ASCII art/Mermaid).
- Model concurrency atau threading (jika ada).
- Mekanisme error handling, observability/telemetry, dan boundary data.

### Langkah 4: Wawancara untuk DECISIONS.md & PROJECT_CONTEXT.md
JANGAN mengarang keputusan bisnis. Ajukan 3-5 pertanyaan spesifik kepada developer:
1. "Library/framework apa yang secara tegas DILARANG digunakan di repo ini?"
2. "Apa pattern utama penanganan concurrency dan transaksi database?"
3. "Keputusan arsitektural apa yang paling krusial yang sudah disepakati?"
Setelah developer menjawab, simpan dalam format ADR ringkas di `DECISIONS.md`.

### Langkah 5: Generate TODO.md
- Kumpulkan `// TODO:` atau `// FIXME:` yang ada di code.
- Buat checklist target jangka pendek (Immediate Tasks) dan teknikal debt.