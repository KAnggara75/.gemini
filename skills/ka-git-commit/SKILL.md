---
name: ka-git-commit
description: "Generates high-quality, structured Conventional Commit messages by analyzing git diffs, extracting ticket/issue IDs from branch names, optimizing token usage with RTK and stat-first inspection, and offering atomic commit splits for multi-concern changes. Use when crafting commit messages, reviewing staged changes before commit, or preparing atomic commits."
user-invocable: true
license: MIT
compatibility: Designed for Antigravity AI, Claude Code, and git-based repositories.
metadata:
  version: "2.0.0"
allowed-tools: Bash(git:*) Bash(rtk:*) Read Grep Glob
---

# Generate Conventional Commit Message

Specialized runbook for crafting precise, production-grade Conventional Commit messages adhering to Conventional Commits 1.0.0, Git best practices, and token-efficient diff inspection.

## Core Objectives
1. **Accurate Diff Analysis**: Inspect staged changes (or unstaged when nothing is staged) efficiently without exhausting token budgets.
2. **Intelligent Ticket & Scope Extraction**: Parse ticket keys (Jira, Linear, GitHub Issues) from branch names and determine concise subsystem scopes.
3. **Semantic Classification**: Choose the exact Conventional Commit type (`feat`, `fix`, `refactor`, `perf`, `docs`, `style`, `test`, `build`, `ci`, `chore`, `revert`).
4. **Atomic Commit Awareness**: Detect mixed concerns and propose split atomic commits with exact `git add` sequences when applicable.
5. **Ready-to-Execute CLI Snippets**: Provide both formatted drafts and copy-pasteable/executable git CLI commands.

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
   - For large diffs (>300 lines or >10 files), inspect hunks per subsystem or file-by-file rather than dumping entire diffs.

### Step 3: Semantic Analysis & Multi-Concern Detection

Analyze changes along three dimensions:
- **Primary Intent**: Why was this change made? (Fixing a regression, adding a capability, refactoring architecture, updating CI?)
- **Scope**: What submodule or component is affected? (e.g. `auth`, `cli`, `mcp`, `ui`, `db`, `config`, `deps`).
- **Breaking Changes**: Does this alter public APIs, interfaces, configurations, or database schemas in a backward-incompatible way? (Mark with `!` after scope and `BREAKING CHANGE:` footer).

#### Multi-Concern Check (Atomic Commit Splitting)
If changes span multiple unrelated concerns (e.g., refactoring a database query + updating dependencies + fixing a UI style bug):
- **Recommend Atomic Splits**: Present separate commit drafts for each logical unit along with the specific files to stage.

---

## Conventional Commit Specification Rules

### 1. Structure
```text
<type>(<scope>): [<TICKET_ID>] <imperative subject summary>

[optional body: motivation and context]

- <component/file>: <concise description of key update>
- <component/file>: <concise description of key update>

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
- Use bullet points for specific file/component breakdowns.
- Format breaking changes:
  ```text
  BREAKING CHANGE: The `getUser()` API now returns a Result type instead of throwing.
  ```
- Reference issues: `Closes #123`, `Fixes PROJ-456`, `Refs #789`.

---

## Output Template & Modes

Always output clean markdown formatted drafts followed by copy-pasteable CLI commands.

### Mode A: Single Commit (Standard)
```text
<type>(<optional-scope>): [<TICKET-ID>] <imperative subject>

<1-2 sentences summarizing context/motivation>

- <file/subsystem>: <detail>
- <file/subsystem>: <detail>

[Closes #123 / BREAKING CHANGE: ...]
```

**Git Command Snippet**:
```bash
git commit -m "<type>(<scope>): [<TICKET-ID>] <imperative subject>" \
  -m "<1-2 sentences summarizing context/motivation>

- <file/subsystem>: <detail>
- <file/subsystem>: <detail>"
```

### Mode B: Atomic Commit Split (Multi-Concern)
When changes contain distinct logical units:

#### Commit 1: <Focus 1>
```bash
git add <files-for-part-1>
git commit -m "<type>(<scope>): [<TICKET-ID>] <subject 1>"
```

#### Commit 2: <Focus 2>
```bash
git add <files-for-part-2>
git commit -m "<type>(<scope>): [<TICKET-ID>] <subject 2>"
```
