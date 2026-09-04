---
name: ka-git-commit
description: "Generates high-quality, structured Conventional Commit messages by analyzing git diffs, extracting ticket/issue IDs from branch names, prioritizing granular file-by-file (1 per 1) atomic commits by default, and optimizing token usage with RTK and stat-first inspection. Use when crafting commit messages, reviewing staged changes, or preparing atomic commits."
user-invocable: true
license: MIT
compatibility: Designed for Antigravity AI, Claude Code, and git-based repositories.
metadata:
  version: "2.1.0"
allowed-tools: Bash(git:*) Bash(rtk:*) Read Grep Glob
---

# Generate Conventional Commit Message

Specialized runbook for crafting precise, production-grade Conventional Commit messages adhering to Conventional Commits 1.0.0, Git best practices, token-efficient diff inspection, and **file-by-file (1 per 1) atomic commit prioritization**.

## Core Objectives
1. **File-by-File & Atomic Commit First**: Selalu utamakan memecah perubahan menjadi commit per file (1 per 1) atau unit perubahan terkecil yang mandiri, agar riwayat commit bersih, mudah di-review, dan mudah di-revert.
2. **Auto-Commit for Single File**: Jika hanya ada 1 file yang mengalami perubahan (modified/untracked), **LANGSUNG EKSEKUSI COMMIT** menggunakan format Mode A tanpa perlu meminta konfirmasi atau bertanya ke user.
3. **Accurate Diff Analysis**: Inspect staged changes (or unstaged when nothing is staged) efficiently without exhausting token budgets.
4. **Intelligent Ticket & Scope Extraction**: Parse ticket keys (Jira, Linear, GitHub Issues) from branch names and determine concise subsystem scopes.
5. **Semantic Classification**: Choose the exact Conventional Commit type (`feat`, `fix`, `refactor`, `perf`, `docs`, `style`, `test`, `build`, `ci`, `chore`, `revert`).
6. **Ready-to-Execute CLI Snippets**: Provide sequential, copy-pasteable git CLI commands per file/atomic unit.

---

## Step-by-Step Workflow

### Step 1: Branch & Ticket Key Extraction
Run:
```bash
git branch --show-current
```
- **Pattern Matching Rules**:
  - **Jira / Linear / Custom**: Match `[A-Za-z]{2,10}-[0-9]+` (e.g. `feat/PROJ-123-login` -> `PROJ-123`, `bugfix/ABC-999-fix` -> `ABC-999`).
  - **GitHub Issue**: Match `(?:#|gh-|issue-)?([0-9]+)` in branch names (e.g. `fix/gh-45-auth` -> `GH-45` or `#45`).
  - **Main / Trunk / No Ticket**: If on `main`, `master`, `develop`, `staging`, or a branch without a ticket pattern, omit the ticket section cleanly (e.g. `feat(auth): ...` instead of `feat(auth): [] ...` or empty brackets).

### Step 2: Token-Efficient Diff Inspection
Always prioritize token efficiency. Utilize RTK if available (`rtk git ...`).

1. **Check Working Tree State**:
   ```bash
   git status --short
   ```
2. **Determine Target Changes**:
   - **Staged Changes Exist** (`git diff --cached --stat` has output): Focus inspection strictly on staged changes (`git diff --cached`).
   - **No Staged Changes**: Inspect unstaged tracked changes (`git diff`) and identify untracked files (`git status --short`).
3. **Stat-First & Token Protection**:
   - Run `git diff --stat` (or `git diff --cached --stat`) first to assess volume and changed file paths.
   - For lockfiles (`package-lock.json`, `pnpm-lock.yaml`, `Cargo.lock`, `go.sum`, `yarn.lock`) or auto-generated files (minified bundles, sourcemaps), do NOT dump full line diffs. Summarize them as dependency/lockfile updates.
   - For large diffs (>300 lines or >10 files), inspect hunks file-by-file rather than dumping entire diffs.

### Step 3: Granular Analysis & Per-File Splitting (Utamakan 1 per 1)

Analyze changes for each file individually:
- **Single File Direct Execution**: Jika total file yang berubah hanya **1 file**, **LANGSUNG EKSEKUSI COMMIT** menggunakan perintah git Mode A tanpa menanyakan konfirmasi lagi kepada pengguna. Langsung laporkan hasilnya setelah commit sukses.
- **Multiple Files (Primary Rule)**: Jika terdapat lebih dari 1 file, buat commit terpisah untuk setiap file yang diubah (`1 file = 1 commit`) dan sajikan drafnya.
- **Exception (Tightly Coupled)**: Hanya gabungkan beberapa file jika perubahan antar-file tersebut benar-benar saling bergantung erat (misal: implementasi fungsi dan unit test-nya, atau file kode dan type declaration-nya).
- **Scope**: Tentukan scope spesifik berdasarkan path file atau modul yang disentuh (misal: `install`, `gitignore`, `mcp`, `auth`).
- **Semantic Type**: Tentukan tipe yang akurat per file (`feat`, `fix`, `refactor`, `chore`, `docs`, `style`, `test`, `build`, `ci`).

---

## Conventional Commit Specification Rules

### 1. Structure
```text
<type>(<scope>): [<TICKET_ID>] <imperative subject summary>

[optional body: motivation and context]

[optional footer: BREAKING CHANGE, Closes #123, Co-authored-by]
```

### 2. Type Taxonomy
| Type | Description | Example |
| :--- | :--- | :--- |
| `feat` | New feature or capability for user/consumer | `feat(auth): add OAuth2 refresh token rotation` |
| `fix` | Bug fix or regression repair | `fix(cli): resolve hang on detached background task` |
| `refactor`| Code restructuring without behavior change | `refactor(db): extract connection pool manager` |
| `perf` | Performance improvement | `perf(cache): switch to LRU cache for memory indexing` |
| `docs` | Documentation changes only | `docs(readme): update installation and setup guide` |
| `test` | Adding or fixing test suites/mocks | `test(auth): add edge case tests for expired tokens` |
| `build` | Build system, packaging, external dependencies | `build(deps): bump @modelcontextprotocol/sdk to 1.6` |
| `ci` | CI/CD configuration files and pipelines | `ci(github): add matrix build for macos and linux` |
| `chore` | Routine maintenance, configs, tooling | `chore(lint): configure ruff rules and formatters` |
| `style` | Formatting, white-space, naming (no logic change)| `style(theme): standardize color palette variable names`|
| `revert` | Reverting a previous commit | `revert(api): revert commit abc1234` |

### 3. Subject Line Rules
- **Imperative Mood**: Use imperative verbs ("add", "fix", "update", "remove", "refactor" — NOT "added", "fixes", "updating").
- **Case**: Lowercase start after prefix/ticket.
- **Length**: Strict max 72 characters (optimal 50-60).
- **Punctuation**: NO trailing period (`.`).

### 4. Body & Footers
- Explain **WHY** the change is needed and **WHAT** problem it solves.
- Format breaking changes:
  ```text
  BREAKING CHANGE: The `getUser()` API now returns a Result type instead of throwing.
  ```
- Reference issues: `Closes #123`, `Fixes PROJ-456`, `Refs #789`.

---

## Output Template & Modes

- **Jika Hanya 1 File Diubah**: Langsung jalankan perintah commit Mode A (atomic commit) tanpa meminta konfirmasi terlebih dahulu, lalu tampilkan ringkasan hasil commit.
- **Jika Lebih Dari 1 File Diubah**: Selalu utamakan penyajian **Mode A: File-by-File Atomic Commits (1 per 1)** secara default, lalu sertakan **Mode B: Single Combined Commit** hanya sebagai opsi alternatif.

### Mode A: File-by-File Atomic Commits (Utamakan / Default)
Sajikan draf commit dan perintah eksekusi terpisah secara berurutan untuk setiap file:

#### Commit 1: `<file_path_1>`
```bash
git add <file_path_1>
git commit -m "<type>(<scope>): [<TICKET-ID>] <imperative subject>" \
  -m "<1-2 kalimat konteks dan motivasi perubahan file ini>"
```

#### Commit 2: `<file_path_2>`
```bash
git add <file_path_2>
git commit -m "<type>(<scope>): [<TICKET-ID>] <imperative subject>" \
  -m "<1-2 kalimat konteks dan motivasi perubahan file ini>"
```

---

### Mode B: Single Combined Commit (Alternatif / Tightly Coupled)
Hanya jika pengguna secara eksplisit meminta commit gabungan atau perubahan benar-benar tidak dapat dipisahkan:

```bash
git add <all_files>
git commit -m "<type>(<scope>): [<TICKET-ID>] <imperative subject>" \
  -m "<ringkasan motivasi>

- <file1>: <detail>
- <file2>: <detail>"
```
