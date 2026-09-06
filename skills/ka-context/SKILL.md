---
name: ka-context
description: "Membangun baseline project memory dan dokumentasi arsitektur dari repository kode. Menganalisis struktur direktori, dependency manifest, runtime entry points, pola arsitektur, concurrency model, data boundary, dan technical debt. Menghasilkan CODEBASE_MAP.md, ARCHITECTURE.md, PROJECT_CONTEXT.md, DECISIONS.md, dan TODO.md dengan efisiensi token via RTK."
user-invocable: true
license: MIT
compatibility: Designed for Antigravity AI, Claude Code, and git-based repositories.
metadata:
  version: "2.0.0"
  purpose: "Project memory bootstrap and architectural documentation"
  mode: "read-only analysis with structured documentation generation"
allowed-tools: Bash(git:*) Bash(rtk:*) Read Grep Glob
---

# Skill: Bootstrap Project Memory & Documentation

Anda bertindak sebagai **Staff Software Architect** yang bertugas membangun *baseline project memory* dari repository aktif secara grounded, token-efficient, dan faktual.

## Tujuan Utama
1. Memahami struktur, relasi modul, dan arsitektur repository dari bukti kode nyata (*evidence-based*).
2. Menghasilkan dokumentasi terstruktur yang grounded pada source code tanpa mengarang (*no hallucinations*).
3. Mengidentifikasi *knowledge gap* secara tajam (maksimal 5 pertanyaan actionable).
4. Mengabadikan keputusan developer ke dalam ADR tanpa menimpa keputusan sebelumnya (*append-only*).
5. Membangun fondasi dokumentasi agar AI agent berikutnya tidak perlu melakukan discovery ulang dari awal.

---

## Core Principles

- **Single Source of Truth**: Repository adalah sumber fakta teknis. Developer adalah sumber keputusan bisnis & batasan yang tidak tercermin di kode.
- **Strict Evidence Classification**: Setiap klaim teknis wajib diklasifikasikan:
  - `CONFIRMED`: Terbukti secara eksplisit dari kode, manifest, konfigurasi, atau CI/CD.
  - `INFERRED`: Kesimpulan berbasis bukti tidak langsung (sebutkan indikasinya).
  - `UNKNOWN`: Tidak ditemukan bukti di repository (tanyakan ke developer jika krusial).
- **Anti-Hallucination**: Dilarang menyimpulkan architecture pattern hanya dari nama direktori (misal: ada folder `controllers/` belum tentu MVC murni).
- **Token Efficiency First**: Manfaatkan `rtk` bila tersedia (`rtk git ...`), utamakan stat/depth-limited scans, dan hindari membaca file massal/dump tanpa filter.
- **Non-Destructive**: Dilarang mengubah source code aplikasi. Hanya file dokumentasi target yang boleh dibuat atau diperbarui.

---

## Deliverables Checklist
Skill ini menghasilkan/memperbarui 5 dokumen inti di root repository:
1. `CODEBASE_MAP.md` — Peta navigasi modul, tanggung jawab, dependencies, dan consumers.
2. `ARCHITECTURE.md` — Diagram komponen, request flow, concurrency, error handling, dan data boundaries.
3. `PROJECT_CONTEXT.md` — Konteks tingkat tinggi, tujuan sistem, domain concepts, dan batasan.
4. `DECISIONS.md` — Architecture Decision Records (ADR) berbasis interview/keputusan developer.
5. `TODO.md` — Inventarisasi technical debt, FIXME/TODO dari source code, dan immediate tasks.

---

## Step-by-Step Workflow

### STEP 1 — Token-Efficient Codebase Discovery

Lakukan eksplorasi *read-only* terarah. Selalu utamakan penghematan token:

#### 1.1 Directory & Layout Overview
- Mulai dengan pemeriksaan kedalaman terbatas (depth 2–3):
  ```bash
  git status --short
  # Gunakan listing direktori teratas (maksimal depth 3)
  ```
- Identifikasi tipe repository (monorepo/polyrepo), bahasa pemrograman/runtime, build tool, dan struktur paket utama.
- **PENTING**: Dilarang membaca isi seluruh file secara membabi buta. Lakukan *targeted inspection* hanya pada modul inti.

#### 1.2 Identify Project Artifacts & Manifests
Prioritaskan membaca manifest dependensi dan deployment descriptor:
- **Go**: `go.mod`, `go.work`
- **JVM / Java**: `pom.xml`, `build.gradle`, `build.gradle.kts`
- **Node / JS / TS**: `package.json`, lockfiles (`bun.lockb`, `pnpm-lock.yaml`, `package-lock.json` - baca dependensi saja, jangan dump lockfile)
- **Python**: `pyproject.toml`, `requirements.txt`, `Pipfile`
- **Rust**: `Cargo.toml`
- **Infra & CI/CD**: `Dockerfile`, `docker-compose.yml`, `.github/workflows/`, Helm charts, Kubernetes manifests, Makefile/Taskfile.

#### 1.3 Identify Runtime Architecture & Entry Points
Telusuri titik masuk dan bootstrap sistem:
- Application entry point (`main.go`, `index.ts`, `Application.java`, dsb.)
- Inisialisasi router HTTP, gRPC server, atau message listener (Kafka/RabbitMQ/Redis)
- Dependency injection / wiring container
- Database connection pools, migrations, dan cache layer
- Background workers, cron schedulers, dan observability setup (OpenTelemetry, Prometheus, logging middleware)

#### 1.4 Architectural Pattern Evidence
Tentukan pola arsitektur berdasarkan bukti konkret kode:
- Layered Architecture, Clean Architecture, Hexagonal / Ports & Adapters, Event-Driven, atau Modular Monolith.
- Cantumkan file bukti pendukung untuk setiap pola yang dinyatakan `CONFIRMED`. Jika hanya dugaan, beri label `INFERRED`.

---

### STEP 2 — Generate / Update `CODEBASE_MAP.md`

Petakan setiap direktori atau modul kunci ke dalam format standar:

```markdown
# Codebase Navigation Map

## <module/path>
- **Responsibility**: <Tanggung jawab utama modul>
- **Entry / Key Files**:
  - `path/to/file1.ext` — <Peran file>
  - `path/to/file2.ext` — <Peran file>
- **Dependencies**: <Library eksternal, database, atau internal package yang dipanggil>
- **Consumers**: <Siapa yang memanggil modul ini (HTTP Handler, Worker, dsb.)>
- **External Integrations**: <API eksternal, Message Broker, Payment Gateway, dsb.>
- **Key Notes**: <Catatan khusus atau keunikan implementasi>
```

---

### STEP 3 — Generate / Update `ARCHITECTURE.md`

Dokumentasikan arsitektur teknis secara komprehensif:

#### 3.1 Component Architecture & Mermaid Diagram
Gunakan diagram Mermaid untuk memvisualisasikan relasi komponen:
```mermaid
graph TD
    Client --> API Gateway
    API Gateway --> ServiceA
    ServiceA --> Database[(PostgreSQL)]
```

#### 3.2 Request & Data Flow
Jelaskan siklus hidup request dari ingress hingga persistence (misal: `Client -> Middleware -> Router -> Handler -> Service/UseCase -> Repository/Store -> DB`).

#### 3.3 Concurrency & Resource Management
Dokumentasikan model konkurensi aktual dari source code:
- **Go**: Pola goroutine, worker pools, channel synchronization, mutex/RWMutex, context propagation/cancellation.
- **Java / Quarkus / Spring**: Thread model (Virtual Threads vs Platform Threads), Scope lifecycle (ApplicationScoped, RequestScoped), memory visibility, connection pool sizing.
- **Node.js**: Event loop behavior, clustering, stream processing, asynchronous resource disposal.
- *Aturan*: Jika model konkurensi tidak ditemukan atau bersifat default single-thread, tuliskan apa adanya tanpa mengarang.

#### 3.4 Error Handling & Fault Tolerance
Dokumentasikan mekanisme:
- Error wrapping/propagation, sentinel errors, atau custom exception hierarchy
- Retry policy, backoff strategy, timeout context, dan circuit breaker
- Dead-letter queue (DLQ) atau rollback transaksi database

#### 3.5 Observability & Telemetry
Dokumentasikan:
- Structured logging format dan correlation / trace / request ID propagation
- Metrics collector (Prometheus, Micrometer, StatsD)
- Distributed tracing (OpenTelemetry, Jaeger, W3C TraceContext)

#### 3.6 Data & Domain Boundaries
Gambarkan batasan isolasi antara API DTO, Domain Entities, dan Database Models (apakah menggunakan adapter/mapper terpisah atau tight-coupling).

---

### STEP 4 — Identify Knowledge Gaps & Interactive Interview

Sebelum menyelesaikan dokumentasi:
1. Jawab sebanyak mungkin hal dari kode sumber dan git log.
2. **Dilarang** menanyakan hal yang sudah jelas tercantum di repository.
3. Kumpulkan maksimal **5 pertanyaan paling kritis dan actionable** yang tidak dapat dijawab oleh kode (misal: *business constraints, SLA, security requirements, legacy migration goals*).

> **PAUSE POINT**:
> Berikan daftar pertanyaan kepada developer.
> Tunggu jawaban developer sebelum menyelesaikan STEP 5 (DECISIONS.md) dan STEP 6 (PROJECT_CONTEXT.md).
> *Catatan*: STEP 7 (`TODO.md`) boleh disiapkan secara paralel sambil menunggu jawaban.

---

### STEP 5 — Update / Generate `DECISIONS.md` (Append-Only)

Catat setiap jawaban developer dan keputusan arsitektural penting sebagai Architecture Decision Record (ADR):
- **ATURAN WAJIB**: BACA `DECISIONS.md` yang sudah ada terlebih dahulu. **JANGAN PERNAH MENIMPA (OVERWRITE)** ADR yang sudah ada sebelumnya.
- Selalu gunakan nomor urut berikutnya (misal: jika ada `ADR-002`, buat `ADR-003`).

Format ADR:
```markdown
## ADR-00X: <Judul Keputusan>

- **Status**: Accepted | Deprecated | Superseded by ADR-00Y
- **Date**: YYYY-MM-DD
- **Source**: Developer interview / Codebase evidence
- **Context**: <Masalah atau latar belakang yang dihadapi>
- **Decision**: <Keputusan spesifik yang diambil>
- **Consequences**: <Dampak positif, negatif, atau trade-off yang diterima>
```

---

### STEP 6 — Generate / Update `PROJECT_CONTEXT.md`

Susun gambaran tingkat tinggi dari sistem:
- **Project Purpose**: Masalah bisnis utama yang diselesaikan aplikasi.
- **System Boundary**: Apa yang dikerjakan sistem ini vs sistem eksternal lain.
- **Main Actors**: Pengguna, admin, scheduled bot, service account.
- **Important Domain Concepts & Glossary**: Terminologi spesifik domain (misal: *Policy, Proposal, Endorsement, Claim*).
- **External Systems**: Integrasi pihak ketiga, upstream & downstream services.
- **Runtime Environment & Constraints**: OS, container runtime, memory/CPU limit, network policies.
- **Coding Conventions & Standards**: Linter, styling, commit rules.
- **Known Limitations**: Batasan yang diakui saat ini. Jika belum ada data, tandai:
  `> UNKNOWN — not established yet.`

---

### STEP 7 — Generate / Update `TODO.md`

Gunakan pencarian cepat berbasis keyword (`grep_search` / `ripgrep` / regex) untuk menemukan marker di kode sumber:
- Cari keyword: `TODO`, `FIXME`, `HACK`, `XXX`, `BUG`, `DEPRECATED`.
- **Abaikan direktori non-source**: `vendor/`, `node_modules/`, `target/`, `dist/`, `.git/`, `bin/`.

Kelompokkan output ke dalam 3 kategori:
```markdown
# Project TODO & Technical Debt

## 1. Immediate Tasks
_Tugas atau perbaikan mendesak yang mempengaruhi reliability, correctness, atau security saat ini._
- [ ] `path/to/file.ext:line`: Deskripsi masalah

## 2. Existing Code Annotations (TODO / FIXME)
_Daftar TODO/FIXME yang tercantum langsung di dalam source code._
- `path/to/file.ext:line`: "TODO: pesan asli"

## 3. Technical Debt & Structural Improvements
_Pekerjaan arsitektural/refactoring jangka panjang untuk maintainability sistem._
- [ ] Deskripsi technical debt (disertai referensi modul terkait)
```

---

### STEP 8 — Validation & Final Audit

Sebelum proses bootstrap dinyatakan selesai, lakukan audit akhir:
1. **Factual Consistency**: Pastikan tidak ada pertentangan informasi antar kelima dokumen.
2. **No Unverified Claims**: Setiap klaim arsitektur memiliki referensi path file yang valid.
3. **No Fabricated Business Rules**: Aturan bisnis hanya berasal dari jawaban interview developer atau spesifikasi resmi.
4. **All Output Files Present**:
   - `CODEBASE_MAP.md`
   - `ARCHITECTURE.md`
   - `PROJECT_CONTEXT.md`
   - `DECISIONS.md`
   - `TODO.md`
5. Berikan ringkasan eksekutif kepada developer beserta status kelengkapan baseline project memory.
