---
name: ka-del-conversation
description: "Antigravity conversation history manager and cleaner (CLI, IDE, and Core). Supports conversation listing, age filtering (e.g. > 30 days), dry-run simulations, individual/range index selection, and complete purging of conversation database artifacts."
user-invocable: true
license: MIT
compatibility: Designed for Antigravity AI, Antigravity CLI, and macOS/Linux shells.
metadata:
  version: "1.0.0"
allowed-tools: Bash(clean-conversations:*) Bash(python3:*) Read Grep Glob
---

# Antigravity Conversation Cleaner & Manager

Use this skill to inspect, filter, and purge conversation history across Antigravity surfaces (`antigravity`, `antigravity-cli`, `antigravity-ide`) safely and systematically.

This skill utilizes the `clean-conversations` CLI binary wrapper (or backend script `clean-conversations.sh` / `scripts/clean_conversations.py`).

## Scope of Managed Artifacts
When a conversation is deleted, the script purges all related artifacts:
1. SQLite conversation database & WAL/SHM files (`conversations/<id>.db*`).
2. Conversation brain directories and artifacts (`brain/<id>/`).
3. Global summary SQLite database (`antigravity-cli/conversation_summaries.db`).
4. Annotation files & thumbnails if present (`annotations/<id>*`).

---

## Usage Guide & Workflows

### 1. List Active Conversations
Use the `-l` or `--list` flag to view conversations without deleting:
```bash
clean-conversations --list
```
Or directly from the repository if not yet in `$PATH`:
```bash
skills/ka-del-conversation/clean-conversations.sh --list
```

### 2. Delete Conversations by Age (e.g., Older Than 30 Days)
Purge conversations inactive for more than 30 days:
```bash
# Dry-run simulation first
clean-conversations -o 30 -n

# Execute directly with confirmation prompt
clean-conversations -o 30

# Force execution without interactive prompt
clean-conversations -o 30 -f
```

### 3. Filter by Specific Antigravity Surface
- **Antigravity CLI Only**:
  ```bash
  clean-conversations --cli -l
  ```
- **Antigravity IDE Only**:
  ```bash
  clean-conversations --ide -l
  ```
- **Antigravity Core / Hub Only**:
  ```bash
  clean-conversations --core -l
  ```

### 4. Interactive Terminal Mode (TUI)
When launched without deletion arguments, an interactive console menu opens:
```bash
clean-conversations
```

#### Quick Navigation Controls (Single Keypress, No Enter Needed):
- `n`: Go to next page
- `p`: Go to previous page
- `o`: Auto-select all conversations older than 30 days
- `d`: Enter conversation index input mode for deletion
- `1-9` (direct digits): Select conversation index directly
- `q` or `Esc`: Quit application

#### Index Selection Format:
- Single index: `3`
- Multiple indices: `1, 4, 7`
- Index range: `2-5`
- Combination: `1, 3-5, 8`
- All conversations: `all`

#### Confirmation Prompt:
- Press `Enter` or `y`: Execute deletion
- Press `Esc`, `q`, or `n`: Cancel and return to list

---

## Complete CLI Reference

| Flag | Alias | Description |
| :--- | :--- | :--- |
| `-l` | `--list` | Display conversation list only |
| `-o <DAYS>` | `--older-than <DAYS>` | Select conversations older than `DAYS` days |
| `--delete-all` | - | Select ALL conversations for purging |
| `-n` | `--dry-run` | Simulate operations without deleting physical files |
| `-f` | `-y`, `--force` | Execute deletion without interactive confirmation |
| `--cli` | - | Restrict target to Antigravity CLI |
| `--ide` | - | Restrict target to Antigravity IDE |
| `--core` | - | Restrict target to Antigravity Core/Hub |
| `--all` | - | Target all surfaces (default) |
