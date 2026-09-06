---
name: ka-context
description: "Membangun baseline project memory dari repository kode dengan menganalisis struktur, dependency, arsitektur, integrasi, keputusan teknis, dan technical debt. Menghasilkan CODEBASE_MAP.md, ARCHITECTURE.md, PROJECT_CONTEXT.md, DECISIONS.md, dan TODO.md."
user-invocable: true
license: MIT
compatibility: Designed for Antigravity AI, Claude Code, and git-based repositories.
metadata:
  version: "1.0.0"
  purpose: "Project memory bootstrap and architectural documentation"
  mode: "read-only analysis with documentation generation"
allowed-tools: Bash(git:*) Bash(rtk:*) Read Grep Glob
---

# Skill: Bootstrap Project Memory & Documentation

Anda bertindak sebagai Staff Software Architect yang bertugas membangun baseline project memory dari repository yang sedang aktif.

Tujuan utama:
1. Memahami struktur dan arsitektur repository.
2. Membuat dokumentasi yang grounded pada source code.
3. Mengidentifikasi knowledge gap.
4. Mengumpulkan keputusan developer tanpa mengarang business rule.
5. Membuat dokumentasi yang dapat digunakan AI agent berikutnya
   tanpa perlu melakukan discovery dari awal.

---

## PRINCIPLES

- Repository adalah source of truth untuk technical facts.
- Developer adalah source of truth untuk business decisions dan constraints
  yang tidak dapat dibuktikan dari repository.
- Jangan mengarang informasi.
- Jangan menyimpulkan architecture pattern hanya berdasarkan nama folder.
- Bedakan setiap informasi menjadi:
  - CONFIRMED — terbukti dari repository.
  - INFERRED — kesimpulan dari evidence repository.
  - UNKNOWN — tidak dapat dipastikan.
- Prioritaskan evidence dari source code, configuration, dependency manifest,
  CI/CD, dan deployment configuration.
- Jangan melakukan perubahan terhadap source code.
- Dokumentasi yang dibuat oleh skill boleh dibuat atau diperbarui.

---

# STEP 1 — CODEBASE DISCOVERY

Lakukan eksplorasi read-only.

### 1.1 Repository Overview

Identifikasi:

- struktur direktori utama
- repository type
- language / runtime
- build system
- dependency manager
- package/module structure

Mulai dengan directory tree depth 3.

Setelah itu lakukan targeted exploration terhadap modul penting.

Jangan membaca seluruh repository secara indiscriminately.

### 1.2 Identify Project Artifacts

Cari jika tersedia:

- go.mod / go.work
- pom.xml
- build.gradle / build.gradle.kts
- package.json
- lockfiles
- Dockerfile
- docker-compose
- Makefile / Taskfile
- CI/CD configuration
- Kubernetes / Helm
- Terraform
- application configuration

### 1.3 Identify Runtime Architecture

Cari dan identifikasi:

- application entry point
- bootstrap / initialization
- dependency injection
- HTTP server
- background worker
- scheduler
- message consumer / producer
- database access
- external API clients
- cache
- observability / telemetry

### 1.4 Identify Architecture

Identifikasi architecture pattern berdasarkan evidence.

Contoh:

- Layered Architecture
- Clean Architecture
- Hexagonal Architecture
- Ports & Adapters
- MVC
- Event-driven

Untuk setiap pattern, jelaskan evidence yang mendukung.

Jangan menyatakan pattern sebagai CONFIRMED jika hanya merupakan inferensi.

---

# STEP 2 — GENERATE CODEBASE_MAP.md

Buat dokumentasi navigasi repository.

Untuk setiap modul penting:

- Path
- Responsibility
- Important files
- Dependencies
- Consumers
- External integrations
- Important notes

Contoh:

## internal/order

Responsibility:
Order lifecycle management.

Important files:
- internal/order/service.go
- internal/order/repository.go

Dependencies:
- PostgreSQL
- PaymentClient

Consumers:
- HTTP API
- Kafka Consumer

---

# STEP 3 — GENERATE ARCHITECTURE.md

Dokumentasikan:

### Component Architecture
Gunakan Mermaid jika memungkinkan.

### Request / Data Flow

Jelaskan alur:

Client
→ Handler
→ Application Service
→ Domain
→ Repository
→ Database

atau flow aktual repository.

### Dependency Direction

Jelaskan dependency antar layer.

### Concurrency Model & Resource Management
Jika repository menggunakan Go:
- Identifikasi penggunaan goroutine dan pattern sinkronisasi (channels, sync.Mutex, WaitGroup).
- Identifikasi penggunaan 3rd-party library vs standard library.

Jika repository menggunakan Java/Quarkus:
- Identifikasi thread safety, pengelolaan lifecycle bean (ApplicationScoped, RequestScoped), dan mekanisme memory visibility.
- Identifikasi pengelolaan koneksi dan thread pool.

Jika relevan:

- thread model
- goroutine model
- executor
- async processing
- worker pool
- locking
- transaction boundary
- synchronization mechanism

Jangan mengarang model concurrency apabila tidak ditemukan.

### Error Handling

Dokumentasikan:

- error propagation
- error mapping
- retry
- timeout
- circuit breaker
- dead-letter handling
- transaction rollback

### Observability

Dokumentasikan:

- logging
- metrics
- tracing
- OpenTelemetry
- correlation/request ID

### Data Boundary

Dokumentasikan boundary antara:

- API
- domain
- persistence
- message broker
- external services

---

# STEP 4 — IDENTIFY KNOWLEDGE GAPS

Sebelum melakukan interview:

1. Gunakan repository untuk menjawab sebanyak mungkin pertanyaan.
2. Jangan menanyakan fakta yang sudah dapat dibuktikan.
3. Identifikasi informasi yang tidak tersedia atau ambigu.

Kategori knowledge gap:

- business rule
- architectural constraint
- technology restriction
- concurrency policy
- transaction policy
- deployment constraint
- security requirement
- compatibility requirement

Ajukan maksimal 5 pertanyaan paling penting.

Pertanyaan harus spesifik dan actionable.

Contoh:

1. Library/framework apa yang secara eksplisit dilarang digunakan?
2. Bagaimana aturan transaction boundary?
3. Apa strategi concurrency yang harus dipertahankan?
4. Keputusan arsitektural apa yang tidak boleh diubah?
5. Apa constraint deployment/runtime yang harus dipenuhi?

Jangan mengarang jawaban.

**PAUSE EXECUTION HERE.**
Keluarkan output daftar pertanyaan kepada user. Jangan lanjutkan ke STEP 5 dan STEP 6 sebelum user memberikan jawaban. Anda boleh memproses STEP 7 (TODO.md) paralel dengan menunggu jawaban.

---

# STEP 5 — UPDATE/GENERATE DECISIONS.md

Jika file DECISIONS.md sudah ada, BACA file tersebut terlebih dahulu.
JANGAN menimpa (overwrite) ADR yang sudah ada. Tambahkan ADR baru di bagian atas atau bawah sesuai urutan (Append-only).

Setiap keputusan developer dicatat sebagai ADR.

Format:

## ADR-001: <Decision>

Status:
Accepted

Context:
...

Decision:
...

Consequences:
...

Source:
Developer interview

Date:
YYYY-MM-DD

Jangan memperluas scope keputusan melebihi jawaban developer.

---

# STEP 6 — GENERATE PROJECT_CONTEXT.md

Dokumentasikan context tingkat tinggi:

## Project Purpose

## System Boundary

## Main Actors

## Important Domain Concepts

## External Systems

## Runtime Environment

## Development Constraints

## Coding Conventions

## Known Limitations

Informasi yang tidak diketahui harus ditulis:

> UNKNOWN — not established yet.

Jangan mengarang.

---

# STEP 7 — GENERATE TODO.md

JANGAN membaca file satu per satu. Gunakan command line tool (seperti `grep`, `rg`, atau search tools agent) untuk mencari keyword TODO, FIXME, HACK, XXX secara rekursif.
Abaikan direktori build/vendor (contoh: `vendor/`, `node_modules/`, `target/`, `.git/`).

Kelompokkan:

## Existing TODOs

TODO yang memang terdapat di source code.

## Immediate Tasks

Masalah yang berdampak langsung terhadap maintainability,
correctness, reliability, atau development workflow.

## Technical Debt

Masalah struktural yang tidak harus diperbaiki segera.

Jangan mengubah TODO menjadi priority tanpa evidence.

---

# STEP 8 — VALIDATION

Sebelum selesai:

1. Pastikan semua file yang dibuat konsisten.
2. Pastikan tidak ada architectural claim tanpa evidence.
3. Pastikan tidak ada business rule yang dibuat-buat.
4. Pastikan path/file yang dirujuk benar-benar ada.
5. Tandai uncertainty sebagai UNKNOWN atau INFERRED.
6. Pastikan dokumentasi tidak bertentangan dengan source code.

Output akhir:

- CODEBASE_MAP.md
- ARCHITECTURE.md
- PROJECT_CONTEXT.md
- DECISIONS.md
- TODO.md