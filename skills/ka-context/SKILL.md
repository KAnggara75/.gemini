---
name: ka-context
description: "Bootstrap project memory and architectural documentation from an active codebase. Analyzes directory layout, dependency manifests, runtime entry points, architectural patterns, concurrency models, data boundaries, and technical debt. Generates CODEBASE_MAP.md, ARCHITECTURE.md, PROJECT_CONTEXT.md, DECISIONS.md, and TODO.md with token-efficient RTK inspection."
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

You act as a **Staff Software Architect** tasked with building grounded, token-efficient, and factual *baseline project memory* from an active repository.

## Core Objectives
1. Understand architecture, module relationships, and data flow from empirical code evidence (*evidence-based*).
2. Produce structured documentation grounded in source code without hallucination (*no hallucinations*).
3. Identify sharp, actionable knowledge gaps (maximum 5 critical questions).
4. Record architectural decisions into ADRs without overwriting historical decisions (*append-only*).
5. Establish a baseline memory so subsequent AI agents do not need to rediscover the system from scratch.

---

## Core Principles

- **Single Source of Truth**: The repository is the source of technical truth. The developer is the source of business context and constraints not evident in code.
- **Strict Evidence Classification**: Every technical assertion must be classified:
  - `CONFIRMED`: Explicitly evidenced by source code, manifests, configs, or CI/CD pipelines.
  - `INFERRED`: Deduced from indirect indicators (specify evidence).
  - `UNKNOWN`: No evidence found in repository (inquire with developer if crucial).
- **Anti-Hallucination**: Never assume architecture patterns solely based on directory names (e.g., having `controllers/` does not guarantee pure MVC).
- **Token Efficiency First**: Use `rtk` when available (`rtk git ...`), prefer shallow depth-limited scans, and avoid dumping raw files unconditionally.
- **Non-Destructive**: Do not alter application code. Only designated documentation files may be created or updated.

---

## Deliverables Checklist
This skill produces and maintains 5 core documents at the repository root:
1. `CODEBASE_MAP.md` — Module navigation map, responsibilities, dependencies, and consumers.
2. `ARCHITECTURE.md` — Component diagrams, request lifecycles, concurrency models, error boundaries, and telemetry.
3. `PROJECT_CONTEXT.md` — High-level purpose, domain glossary, system boundaries, and runtime constraints.
4. `DECISIONS.md` — Architecture Decision Records (ADRs) capturing developer decisions (append-only).
5. `TODO.md` — Inventory of technical debt, code annotations (TODO/FIXME), and immediate improvements.

---

## Step-by-Step Workflow

### STEP 1 — Token-Efficient Codebase Discovery

Perform focused, read-only discovery prioritizing token budget:

#### 1.1 Directory & Layout Overview
- Begin with shallow depth scans (depth 2–3):
  ```bash
  git status --short
  ```
- Identify repository type (monorepo/polyrepo), primary language/runtime, build tool, and package root.

#### 1.2 Inspect Project Artifacts & Manifests
Prioritize reading dependency manifests and deployment descriptors:
- **Go**: `go.mod`, `go.work`
- **JVM / Java**: `pom.xml`, `build.gradle`, `build.gradle.kts`
- **Node / JS / TS**: `package.json` (read dependencies only; avoid dumping full lockfiles)
- **Python**: `pyproject.toml`, `requirements.txt`, `Pipfile`
- **Rust**: `Cargo.toml`
- **Infra & CI/CD**: `Dockerfile`, `docker-compose.yml`, `.github/workflows/`, Helm charts, Kubernetes manifests.

#### 1.3 Identify Runtime Architecture & Entry Points
Trace system entry points and bootstrap wiring:
- Application entry points (`main.go`, `index.ts`, `Application.java`, etc.)
- Router initialization (HTTP, gRPC, or message consumers like Kafka/RabbitMQ)
- Dependency injection and component wiring containers
- Database connection pools, migrations, and cache layers
- Background workers, cron schedulers, and observability middleware

#### 1.4 Architectural Pattern Evidence
Identify patterns from concrete codebase evidence:
- Layered Architecture, Clean Architecture, Hexagonal / Ports & Adapters, Event-Driven, or Modular Monolith.
- Tag each identified pattern with `CONFIRMED` (with file path references) or `INFERRED`.

---

### STEP 2 — Generate / Update `CODEBASE_MAP.md`

Map each primary directory or subsystem into standard format:

```markdown
# Codebase Navigation Map

## <module/path>
- **Responsibility**: <Primary responsibility>
- **Entry / Key Files**:
  - `path/to/file1.ext` — <File purpose>
  - `path/to/file2.ext` — <File purpose>
- **Dependencies**: <External libraries, databases, or internal packages>
- **Consumers**: <Callers such as HTTP Handlers, Workers, or CLI>
- **External Integrations**: <APIs, Message Brokers, Payment Gateways>
- **Key Notes**: <Implementation quirks or notable characteristics>
```

---

### STEP 3 — Generate / Update `ARCHITECTURE.md`

Document technical architecture comprehensively:

#### 3.1 Component Architecture & Mermaid Diagram
Visualize component interactions using Mermaid:
```mermaid
graph TD
    Client --> API Gateway
    API Gateway --> ServiceA
    ServiceA --> Database[(PostgreSQL)]
```

#### 3.2 Request & Data Flow
Explain request lifecycle from ingress to persistence.

#### 3.3 Concurrency & Resource Management
Document actual concurrency patterns in code:
- **Go**: Goroutines, worker pools, channel synchronization, mutexes, context cancellation.
- **Java / Quarkus / Spring**: Thread models (Virtual vs Platform), bean scope lifecycle, connection pool sizing.
- **Node.js**: Event loop dynamics, stream processing, async resource cleanup.

#### 3.4 Error Handling & Fault Tolerance
Document:
- Error wrapping, sentinel errors, or custom exception hierarchies.
- Retry policies, timeouts, backoff strategies, circuit breakers, and transaction rollbacks.

#### 3.5 Observability & Telemetry
Document:
- Structured logging format and correlation / trace ID propagation.
- Metrics collection (Prometheus, Micrometer, StatsD) and tracing (OpenTelemetry).

#### 3.6 Data & Domain Boundaries
Detail isolation between API DTOs, Domain Entities, and Database Models.

---

### STEP 4 — Identify Knowledge Gaps & Interactive Interview

Before finalizing:
1. Resolve as much technical context as possible from source code and git logs.
2. Formulate at most **5 critical, actionable questions** that cannot be answered by code (e.g., business constraints, target SLA, compliance).

> **PAUSE POINT**:
> Present questions to the developer.
> Wait for answers before completing STEP 5 (DECISIONS.md) and STEP 6 (PROJECT_CONTEXT.md).

---

### STEP 5 — Update / Generate `DECISIONS.md` (Append-Only)

Record every developer decision as an Architecture Decision Record (ADR):
- **MANDATORY RULE**: Always read existing `DECISIONS.md` first. **NEVER OVERWRITE** previous ADRs.
- Always use incremental numbering (e.g., if `ADR-005` exists, create `ADR-006`).

ADR Format:
```markdown
## ADR-00X: <Decision Title>

- **Status**: Accepted | Deprecated | Superseded by ADR-00Y
- **Date**: YYYY-MM-DD
- **Source**: Developer interview / Codebase evidence
- **Context**: <Problem background and motivation>
- **Decision**: <Specific architectural choice made>
- **Consequences**: <Positive, negative, or trade-off impacts>
```

---

### STEP 6 — Generate / Update `PROJECT_CONTEXT.md`

Provide a high-level system overview:
- **Project Purpose**: Core business problems solved.
- **System Boundary**: In-scope responsibilities vs external services.
- **Main Actors**: Users, admins, background services, APIs.
- **Domain Concepts & Glossary**: Ubiquitous domain terminology.
- **External Systems**: Upstream and downstream dependencies.
- **Runtime Environment & Constraints**: OS, container runtimes, memory/CPU bounds.
- **Coding Conventions & Standards**: Linters, formatting, commit rules.
- **Known Limitations**: Explicit acknowledged boundaries (`> UNKNOWN — not established yet.` if missing).

---

### STEP 7 — Generate / Update `TODO.md`

Search for source annotations using keywords (`TODO`, `FIXME`, `HACK`, `BUG`, `DEPRECATED`), excluding build and vendor folders.

Structure output into 3 sections:
```markdown
# Project TODO & Technical Debt

## 1. Immediate Tasks
_Urgent tasks affecting reliability, security, or immediate execution._
- [ ] `path/to/file.ext:line`: Issue description

## 2. Existing Code Annotations (TODO / FIXME)
_Annotations found directly in source code._
- `path/to/file.ext:line`: "TODO: message"

## 3. Technical Debt & Structural Improvements
_Long-term architectural and refactoring initiatives._
- [ ] Technical debt description
```

---

### STEP 8 — Validation & Final Audit

Perform final verification:
1. **Factual Consistency**: Verify zero conflicting statements across all 5 documents.
2. **No Unverified Claims**: Ensure every architectural claim points to valid file paths.
3. **All Output Files Present**:
   - `CODEBASE_MAP.md`
   - `ARCHITECTURE.md`
   - `PROJECT_CONTEXT.md`
   - `DECISIONS.md`
   - `TODO.md`
4. Present an executive summary of the baseline memory to the developer.
