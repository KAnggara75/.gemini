---
name: ka-review
description: "Comprehensive code reviewer and PR inspection runbook for Java (Quarkus, Spring Boot, Kafka, REST Client) and Go. Enforces strict NPE prevention, memory leak elimination, thread safety, reactive stream sanity, DRY, and generates structured review verdicts with actionable diffs. Activate when reviewing code, diffs, commits, or PRs."
user-invocable: true
license: MIT
compatibility: Designed for Antigravity AI, Claude Code, and git-based repositories.
metadata:
  version: "1.0.0"
  purpose: "Senior Code Reviewer & PR Quality Gatekeeper"
  triggers:
    - "review"
    - "review pr"
    - "code review"
    - "review code"
    - "review diff"
allowed-tools: Bash(git:*) Bash(rtk:*) Bash(curl:*) Bash(jq:*) Read Grep Glob
---

# Skill: Senior Code Reviewer & PR Quality Audit

Standardized runbook for conducting comprehensive, production-grade code reviews for **Java** (Modern Java 17/21+, Spring Boot, Quarkus) and **Go (Golang)** codebases.

---

## Core Review Objectives

1. **Evidence-Based & Grounded**: Every finding must point to exact file paths and line ranges (`file:///path/to/file#L10-L20`) with clear technical reasoning and copy-pasteable diff fixes.
2. **Strict Quality Gate**: Identify bugs, regressions, memory leaks, concurrency violations, and NullPointerExceptions before code merges to `development` or `uat`.
3. **Constructive & Actionable**: Provide concrete replacement code snippets for all non-trivial issues.
4. **Token Efficiency**: Focus diff inspections using `git diff`, `git log`, stat-first checks, and targeted slices rather than dumping entire source files unconditionally.
5. **Bitbucket Server PR/MR Link Support**: Capable of directly reviewing pull requests from Bitbucket Server URL links via REST API without requiring local branch checkout.

---

## Review Workflow

### STEP 1: Determine Review Target

Identify what changes to review based on user input or Git context:

#### Option A: Bitbucket PR / MR Link (e.g. `https://<host>/projects/<PROJECT>/repos/<REPO>/pull-requests/<ID>/...`)
If the user provides a Pull Request URL:
1. **Parse PR URL**:
   Extract Host, Project Key, Repository Slug, and PR ID:
   ```bash
   PR_URL="<USER_PROVIDED_URL>"
   if [[ "$PR_URL" =~ ^(https?://[^/]+)/projects/([^/]+)/repos/([^/]+)/pull-requests/([0-9]+) ]]; then
     BITBUCKET_BASE_URL="${BASH_REMATCH[1]}"
     PROJECT_KEY="${BASH_REMATCH[2]}"
     REPO_SLUG="${BASH_REMATCH[3]}"
     PR_ID="${BASH_REMATCH[4]}"
   fi
   ```
2. **Fetch PR Details & Metadata**:
   Using `BITBUCKET_TOKEN` (never print the token):
   ```bash
   curl -s -H "Authorization: Bearer $BITBUCKET_TOKEN" \
     "${BITBUCKET_BASE_URL}/rest/api/1.0/projects/${PROJECT_KEY}/repos/${REPO_SLUG}/pull-requests/${PR_ID}" \
     > /tmp/pr_${PR_ID}_meta.json
   ```
   Extract Title, Source Branch, Target Branch, and Author:
   ```bash
   PR_TITLE=$(jq -r '.title' /tmp/pr_${PR_ID}_meta.json)
   FROM_BRANCH=$(jq -r '.fromRef.displayId' /tmp/pr_${PR_ID}_meta.json)
   TO_BRANCH=$(jq -r '.toRef.displayId' /tmp/pr_${PR_ID}_meta.json)
   ```
3. **Fetch Changed Files List (Stat-First)**:
   ```bash
   curl -s -H "Authorization: Bearer $BITBUCKET_TOKEN" \
     "${BITBUCKET_BASE_URL}/rest/api/1.0/projects/${PROJECT_KEY}/repos/${REPO_SLUG}/pull-requests/${PR_ID}/changes?limit=100" \
     | jq '[.values[] | {path: .path.toString, type}]' > /tmp/pr_${PR_ID}_changes.json
   ```
4. **Fetch Complete Unified Diff**:
   ```bash
   curl -s -H "Authorization: Bearer $BITBUCKET_TOKEN" \
     "${BITBUCKET_BASE_URL}/rest/api/1.0/projects/${PROJECT_KEY}/repos/${REPO_SLUG}/pull-requests/${PR_ID}.diff" \
     > /tmp/pr_${PR_ID}.diff
   ```
   Review the unified diff directly, prioritizing business logic, service implementations, and DTO/entity transformations.

#### Option B: Local Branch / PR Diff Against Target Branch
Default target: `origin/development` or `origin/uat`:
```bash
git fetch origin development --depth=50 2>/dev/null || true
git diff --stat origin/development...HEAD
git diff origin/development...HEAD
```

#### Option C: Uncommitted Local Changes
```bash
git status --short
git diff --stat
git diff
```

#### Option D: Specific Commit or Range
```bash
git show --stat <commit-hash>
git show <commit-hash>
```

---

### STEP 2: In-Depth Code Inspection

Clean up temporary diff and metadata files after completing review:
```bash
rm -f /tmp/pr_${PR_ID}_meta.json /tmp/pr_${PR_ID}_changes.json /tmp/pr_${PR_ID}.diff
```

---

## Senior Lead Java & Quarkus Review Guidelines

When reviewing Java source code—specifically **Quarkus**, **Spring Boot**, **Kafka (SmallRye Reactive Messaging)**, and **MicroProfile REST Client**—audit rigorously against these criteria:

### 1. Mandatory NPE (NullPointerException) Guardrails
- **Object Navigation Chaining**:
  - Never chain getters without intermediate null guards (e.g., `obj.getA().getB()` will crash if `getA()` returns `null`).
  - Use safe intermediate extraction, `Objects.requireNonNull()`, or `Optional.ofNullable(...)`.
- **List & Collection Checks**:
  - Guard collection emptiness and element nullness before indexing:
    ```java
    if (list != null && !list.isEmpty() && list.get(0) != null) { ... }
    ```
  - Guard collection elements during iteration (`for (Item item : list)` requires verifying `item != null` if items can be nullable).
- **DTO Primitive Unboxing / Auto-unboxing NPE**:
  - Direct conversion of boxed numbers (`Double`, `BigDecimal`, `Long`, `Boolean`) via `.doubleValue()`, `.booleanValue()`, or `+=` will throw `NullPointerException` if the boxed wrapper is `null`.
  - Always check for null or use ternary defaults (`val != null ? val.doubleValue() : 0.0`).
- **External DTO & Deserialization Safety**:
  - DTOs coming from external REST APIs (e.g., Core Engine, Calculation Services) can serialize `null` for fields even if defined as lists or sub-objects. Always check parent DTO, nested container, and leaf node.
  - Set `@JsonIgnoreProperties(ignoreUnknown = true)` on DTOs to avoid unmarshalling crashes during upstream schema drift.
- **Collection Return Values**:
  - Never return `null` for Collections, Arrays, or Maps. Always return `Collections.emptyList()`, `List.of()`, or empty collection variants.

### 2. Memory Leak & OOM (Out of Memory) Elimination
- **Kafka / SmallRye Reactive Messaging**:
  - **Backpressure & Unbounded Buffers**: Verify buffer limits (`@Incoming`, `@Outgoing`, `@Channel`). Without a backpressure overflow strategy, fast producers / slow consumers buffer messages in heap until OOM occurs.
  - **Message Acknowledgment**: Ensure `message.ack()` or `message.nack()` is always handled. Unacknowledged reactive messages retain memory references indefinitely.
  - **Large Payload Streaming**: Avoid accumulating full byte arrays or large Kafka record payloads in memory; use streaming or chunking patterns for multi-megabyte payloads.
- **MicroProfile / Quarkus REST Client**:
  - **Connection & Socket Leaks**: Verify client instance lifecycles. Ensure REST Client interfaces (`@RegisterRestClient`) are scoped properly (`@ApplicationScoped` or `@Dependent`) and connection pools are bounded.
  - **Response Stream Consumption**: Ensure responses with unmanaged streams (e.g., `InputStream`, `Response`) are closed via `try-with-resources`. Leaving unread responses open leaks underlying HTTP client connection pool sockets.
  - **Timeout Safeguards**: Always configure explicit connect and read timeouts. Missing timeouts cause worker threads to hang indefinitely, leading to pool starvation and gradual heap exhaustion.
- **Static & Bean State Retention**:
  - In `@ApplicationScoped` singletons, forbid unbounded collections (`List`, `Map`, `Set`) used as custom in-memory caches. Mandate cache frameworks (Caffeine, Quarkus Cache) with explicit TTL and eviction caps.
  - Clean up `ThreadLocal` variables (or prefer Quarkus CDI request scopes / Vert.x Context) to prevent worker thread reference retention.

### 3. DRY (Don't Repeat Yourself) & Clean Architecture
- **Reusable REST Client Handlers**:
  - Abstract common HTTP headers, bearer tokens, error responses, and retries using MicroProfile `ClientHeadersFactory`, `ResponseExceptionMapper`, or `@ClientHeaderParam` instead of duplicating boilerplate across clients.
- **Unified Kafka Error Handling & Dead Letter Queue (DLQ)**:
  - Centralize Kafka deserialization failure handling, dead-letter-topic routing (`dead-letter-queue.topic`), and retry backoffs rather than writing manual `try-catch` blocks inside every message consumer.
- **Domain & DTO Mapping**:
  - Enforce automated mappers (e.g., MapStruct) or centralized transformation functions instead of repetitive, copy-pasted manual builder / setter mappings across controllers, services, and consumers.

### 4. Concurrency, Virtual Threads & Reactive Context
- **Event Loop Blocking**: Never execute blocking I/O (JDBC, synchronous REST Client, heavy computation) directly on Vert.x Event Loop threads. Annotate blocking methods with `@Blocking` or run them on worker pools / Virtual Threads (`@RunOnVirtualThread`).
- **Virtual Threads (Java 21+)**: Detect *thread pinning* caused by `synchronized` blocks around I/O operations or native calls inside virtual thread contexts. Replace with `ReentrantLock`.
- **Transaction Boundaries**: Keep `@Transactional` scopes minimal. Never execute external REST Client calls or Kafka emits inside an open database transaction block.

---

## Senior Golang Review Guidelines

When reviewing Go source code, audit strictly against these guidelines:

### 1. Concurrency & Goroutine Safety
- **Goroutine Leaks**: Ensure every spawned goroutine terminates reliably via `context.Context` cancellation, worker shutdown signals, or bounded channel operations.
- **Race Conditions**: Verify concurrent memory access is guarded by `sync.Mutex`, `sync.RWMutex`, or `sync/atomic`. Never share pointers across goroutines without synchronization.
- **Channel Discipline**: Prevent deadlocks, avoid unbuffered channel blocking without active consumers, and guarantee no writes occur on closed channels.
- **Context Propagation**: Verify `context.Context` is passed as the first parameter to I/O/DB/HTTP calls. Context must never be stored inside struct fields.

### 2. Error Handling & Resilience
- **Idiomatic Errors**: Never discard errors (`_`). Use `errors.Is()` and `errors.As()` instead of string matching.
- **Error Wrapping**: Wrap contextual errors with `%w` in `fmt.Errorf()` to preserve error chains for inspection.
- **Panic Policy**: Forbid `panic()` in production service and library routines except during irreversible startup initialization (`must*`).

### 3. Performance & Memory Allocations
- **Slice & Map Pre-allocation**: Use `make([]T, 0, cap)` or `make(map[K]V, cap)` whenever the element count is known or bounded to prevent reallocations.
- **Receiver Semantics**: Use value receivers for small immutable types; use pointer receivers for mutable state or large structs.
- **Resource Cleanup**: Ensure `defer resp.Body.Close()`, `defer rows.Close()`, or `defer file.Close()` is scheduled immediately after checking `err == nil`.

---

## Security & Input Sanitization Audit

- **Injection Prevention**:
  - Go: Forbid string formatting (`fmt.Sprintf`) for SQL queries; mandate parameter binding (`$1`, `?`).
  - Java: Forbid string concatenation in JPQL/HQL/native queries; mandate parameterized queries.
- **Path Traversal & SSRF**: Validate remote URLs against allowlists and sanitize filesystem paths (`filepath.Clean()` / `Paths.get().normalize()`).
- **Data Protection**: Prevent passwords, bearer tokens, authorization headers, or PII from being written into application logs.

---

## Structured Review Report Output

Deliver code reviews using the following clean, actionable format:

```markdown
# 📋 Code Review Report

## 1. Executive Summary
- **Target**: [<Branch / PR / Diff>]
- **Languages / Frameworks**: [Java (Spring Boot / Quarkus) | Go]
- **Verdict**: [✅ APPROVED | ⚠️ APPROVED WITH SUGGESTIONS | ❌ CHANGES REQUESTED]
- **Risk Level**: [Low | Medium | High]
- **Summary**: Concise overview of change quality, key strengths, and critical areas requiring attention.

---

## 2. Detailed Findings

### [🔴 BLOCKER] <Issue Title>
- **File**: [`path/to/file.ext#L10-L20`](file:///path/to/file.ext#L10-L20)
- **Problem**: Technical explanation of why this code is buggy, insecure, or dangerous.
- **Recommendation**: Exact guidance on how to fix the issue.
- **Code Snippet**:
  ```diff
  - // Problematic implementation
  + // Proposed fix
  ```

### [🟠 MAJOR] <Issue Title>
- **File**: [`path/to/file.ext#L30-L40`](file:///path/to/file.ext#L30-L40)
- **Problem**: ...
- **Recommendation**: ...

### [💡 SUGGESTION] <Issue Title>
- **File**: [`path/to/file.ext#L50-L60`](file:///path/to/file.ext#L50-L60)
- ...

---

## 3. Best Practice & Verification Recommendations
- Specific unit tests, edge cases, concurrency race tests (`go test -race`), or load tests to execute.
```
