# Codebase Navigation Map

## Root Repository (`/`)
- **Responsibility**: Repositori dotfile, konfigurasi global, hook otomatisasi, integrasi MCP, dan custom skills untuk runtime Google Antigravity (CLI, IDE, Core).
- **Entry / Key Files**:
  - [`install.sh`](../install.sh) — Installer dan symlink orchestrator dari repository ke `~/.gemini/`, `~/.agents/`, dan `~/.local/bin`.
  - [`GEMINI.md`](../GEMINI.md) — Workspace guidelines, aturan RTK, dan panduan Context7 MCP.
  - [`settings.json`](../settings.json) — Konfigurasi root Antigravity (autentikasi dan lifecycle hooks `BeforeTool`).
  - [`memory.jsonl`](../memory.jsonl) — Persistensi memory graf lokal untuk MCP server `@modelcontextprotocol/server-memory`.
- **Dependencies**: Bash, Python 3, `jq`, `rtk`, `tmux`, Homebrew.
- **Consumers**: Developer environment, Antigravity CLI, Antigravity IDE.

---

## `antigravity-cli/`
- **Responsibility**: Pengaturan khusus terminal CLI, pemantau statusline tmux, dan updater judul jendela.
- **Entry / Key Files**:
  - [`antigravity-cli/settings.json`](../antigravity-cli/settings.json) — Whitelist perizinan tool/command (`permissions.allow`), trusted workspaces, model AI, dan path command runner.
  - [`antigravity-cli/statusline.sh`](../antigravity-cli/statusline.sh) — Script statusline responsif (single line/multi-line); memonitor token usage, persentase 5-hour quota & waktu reset lokal (`🕒HH:MM`), git branch, task/subagent count, self-healing symlink, dan notifikasi audio prompt.
  - [`antigravity-cli/title.sh`](../antigravity-cli/title.sh) — Script formatting judul jendela terminal / tmux pane berbasis agent state dan nama workspace.
- **Dependencies**: `jq`, `afplay` (macOS), `osascript`, `bc`, `sqlite3`, `tmux`.
- **Consumers**: Developer terminal environment.

---

## `config/`
- **Responsibility**: Konfigurasi global lintas tool Gemini / Antigravity, plugin, manifest impor, dan konfigurasi Model Context Protocol (MCP).
- **Entry / Key Files**:
  - [`config/config.json`](../config/config.json) — Konfigurasi user tingkat lanjut (lebar percakapan, tema, remote control hostname, dan unsandboxed permissions).
  - [`config/mcp_config.json`](../config/mcp_config.json) — Pendaftaran dan konfigurasi runtime MCP server (`context7`, `podman-mcp`, `git`, `memory`, `filesystem`, `k8s-mcp-server`, `postman`, `jira`).
  - [`config/agents/devops/agent.md`](../config/agents/devops/agent.md) — Definisi custom subagent role DevOps.
  - [`config/agents/code-reviewer/agent.md`](../config/agents/code-reviewer/agent.md) — Definisi custom subagent role Senior Code Reviewer (Java & Go).
  - [`config/agents/java-dev-lead/agent.md`](../config/agents/java-dev-lead/agent.md) — Definisi custom subagent role Java Tech Lead & Senior Architect (Quarkus, Spring Boot, Kafka, Reactive, DDD).
  - `config/import_manifest.json` — Manifest pelacakan instalasi plugin eksternal (misal: `antigravity-cli-wakatime`).
  - `config/plugins/` — Direktori plugin modular Antigravity CLI.
- **Dependencies**: `bunx`, binary MCP server lokal, API remote endpoint Context7.
- **Consumers**: Antigravity core engine dan MCP client gateway.

---

## `hooks/`
- **Responsibility**: Lifecycle hook scripts yang di-trigger sebelum eksekusi tool.
- **Entry / Key Files**:
  - [`hooks/rtk-hook-gemini.sh`](../hooks/rtk-hook-gemini.sh) — Intersepsi perintah shell `run_command` / `run_shell_command`, memeriksa izin allowlist, membunyikan notifikasi audio sistem untuk perintah yang memerlukan konfirmasi, dan meneruskan ke `rtk hook gemini`.
  - [`hooks/notify-decision.sh`](../hooks/notify-decision.sh) — Menangani trigger event `ask_question` untuk memutar audio notifikasi sistem `Glass.aiff` dan menampilkan banner macOS.
- **Dependencies**: `rtk`, `jq`, `afplay`, `osascript`.
- **Consumers**: Antigravity runtime hook runner (`BeforeTool`).

---

## `skills/`
- **Responsibility**: Koleksi modul prosedur operasional terstandarisasi (*agent runbooks*).
- **Sub-Modul**:
  - [`skills/ka-git-commit/SKILL.md`](../skills/ka-git-commit/SKILL.md) — Runbook pembuatan pesan Conventional Commit dengan prioritas atomic commit per-file (1 per 1), auto-commit 1 file, dan direct trigger mode (Mode A vs Mode B).
  - [`skills/ka-pr/SKILL.md`](../skills/ka-pr/SKILL.md) — Runbook pembuatan Pull Request otomatis ke Bitbucket Server On-Premise berbasis Git remote aktif tanpa hardcoding.
  - [`skills/ka-review/SKILL.md`](../skills/ka-review/SKILL.md) — Runbook review kode dan PR quality audit mendalam untuk Java (Quarkus/Spring Boot/Kafka) dan Go.
  - [`skills/ka-del-conversation/`](../skills/ka-del-conversation) — Utilitas CLI (`clean-conversations`) dan script Python untuk inspeksi serta pembersihan database percakapan lama Antigravity/IDE/CLI.
  - [`skills/ka-context/SKILL.md`](../skills/ka-context/SKILL.md) — Bootstrap project memory dan arsitektur repository.
- **Dependencies**: Git, Python 3, `sqlite3`, `curl`.
- **Consumers**: User prompt, slash commands (`/ka-git-commit`, `/ka-pr`, `/ka-review`, `/ka-del-conversation`, `/ka-context`).
