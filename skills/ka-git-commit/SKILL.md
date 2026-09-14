---
name: ka-git-commit
description: "Generates high-quality, structured Conventional Commit messages by analyzing git diffs, extracting ticket/issue IDs from branch names, prioritizing granular file-by-file (1 per 1) atomic commits by default, and optimizing token usage with RTK and stat-first inspection. Supports instant mode triggering (e.g. commit A, commit 1/1, commit B, commit all). Use when crafting commit messages, reviewing staged changes, or preparing atomic commits."
user-invocable: true
license: MIT
compatibility: Designed for Antigravity AI, Claude Code, and git-based repositories.
metadata:
  version: "2.2.0"
allowed-tools: Bash(git:*) Bash(rtk:*) Read Grep Glob
---

# Generate Conventional Commit Message

Specialized runbook for crafting precise, production-grade Conventional Commit messages adhering to Conventional Commits 1.0.0, Git best practices, token-efficient diff inspection, and **file-by-file (1 per 1) atomic commit prioritization**.

## Direct Trigger & Explicit Mode Selection
This skill can be invoked directly with an explicit execution mode to trigger commits immediately without interactive prompt cycles:
- **Trigger Mode A (Atomic / 1 per 1)**:
  - Keywords: `commit A`, `commit 1 per 1`, `commit 1/1`, `atomic commit`, `ka-git-commit A`, `/ka-git-commit A`
  - Behavior: **EXECUTE COMMITS FILE BY FILE ONE BY ONE IMMEDIATELY** for every changed file without asking for confirmation.
- **Trigger Mode B (Combined / All)**:
  - Keywords: `commit B`, `commit all`, `combined commit`, `ka-git-commit B`, `/ka-git-commit B`
  - Behavior: **EXECUTE A SINGLE COMBINED COMMIT IMMEDIATELY** grouping all modified files into one commit without asking for confirmation.
- **Default Trigger (No Mode Specified)**:
  - Keywords: `/ka-git-commit`, `make commit`, `commit`
  - Behavior: If only 1 file changed -> automatically execute Mode A immediately. If >1 file changed -> present Mode A (1 per 1) drafts by default and offer Mode A vs Mode B options.

## Core Objectives
1. **File-by-File & Atomic Commit First**: Always prioritize splitting changes into individual commits per file (1 per 1) or atomic units of work, keeping git history clear, easy to review, and simple to revert.
2. **Auto-Commit for Explicit Mode or Single File**:
   - When triggered with an explicit mode (`commit A` / `commit 1/1` / `commit B` / `commit all`), **IMMEDIATELY EXECUTE GIT COMMITS** matching the chosen mode without pausing for further confirmation.
   - When only 1 file is modified/untracked, **IMMEDIATELY EXECUTE THE COMMIT** using Mode A format without asking for confirmation.
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

### Step 3: Granular Analysis & Per-File Splitting (1 per 1 Priority)

Analyze changes for each file individually:
- **Single File Direct Execution**: If only **1 file** changed, **IMMEDIATELY EXECUTE COMMIT** using Mode A format without waiting for confirmation. Report the result once completed.
- **Multiple Files (Primary Rule)**: If more than 1 file changed, prepare separate commits for each modified file (`1 file = 1 commit`) and present the drafts.
- **Exception (Tightly Coupled)**: Only combine multiple files if changes are strictly inseparable (e.g. function implementation paired with its unit test, or source code paired with its type definitions).
- **Scope**: Determine concise scopes based on touched files or subsystems (e.g. `install`, `gitignore`, `mcp`, `auth`).
- **Semantic Type**: Select the accurate type per file (`feat`, `fix`, `refactor`, `chore`, `docs`, `style`, `test`, `build`, `ci`).

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

- **When Triggered with Explicit Mode A (`commit A` / `commit 1 per 1` / `commit 1/1`)**:
  - **IMMEDIATELY EXECUTE** Mode A sequence (file-by-file one by one) without waiting for user response.
  - Display summary of created commits.
- **When Triggered with Explicit Mode B (`commit B` / `commit all`)**:
  - **IMMEDIATELY EXECUTE** Mode B sequence (all files combined into 1 commit) without waiting for user response.
  - Display summary of the created commit.
- **When Only 1 File Changed**:
  - Immediately execute git commit Mode A (atomic commit) without asking first, then display the summary.
- **When More Than 1 File Changed (No Mode Specified)**:
  - Present **Mode A: File-by-File Atomic Commits (1 per 1)** by default, provide **Mode B: Single Combined Commit** as alternative option, and ask for user preference.

### Mode A: File-by-File Atomic Commits (Default & Preferred)
Present drafted commits and execution commands sequentially per file:

#### Commit 1: `<file_path_1>`
```bash
git add <file_path_1>
git commit -m "<type>(<scope>): [<TICKET-ID>] <imperative subject>" \
  -m "<1-2 sentences explaining motivation and context>"
```

#### Commit 2: `<file_path_2>`
```bash
git add <file_path_2>
git commit -m "<type>(<scope>): [<TICKET-ID>] <imperative subject>" \
  -m "<1-2 sentences explaining motivation and context>"
```

---

### Mode B: Single Combined Commit (Alternative / Tightly Coupled)
Only when explicitly requested or changes are strictly coupled:

```bash
git add <all_files>
git commit -m "<type>(<scope>): [<TICKET-ID>] <imperative subject>" \
  -m "<summary of motivation>

- <file1>: <details>
- <file2>: <details>"
```
