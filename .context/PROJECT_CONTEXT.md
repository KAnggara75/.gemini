# Project Context & High-Level Overview

## 1. Project Purpose
Repository `.gemini` adalah repositori manajemen konfigurasi (*dotfiles* dan *custom tooling*) untuk lingkungan pengembangan bertenaga Google Antigravity AI (CLI `agy`, IDE, dan desktop app). Tujuan intinya adalah:
1. Menyediakan *centralized source of truth* untuk perizinan, tema, dan preferensi agent.
2. Mengintegrasikan Model Context Protocol (MCP) server lokal dan remote (Kubernetes, Podman, Context7, Git, Memory Graph, Postman, Jira).
3. Mengotomasi alur kerja pengembangan melalui *custom skills* terstandarisasi (`ka-git-commit`, `ka-pr`, `ka-del-conversation`, `ka-context`).
4. Mengoptimalkan konsumsi token AI hingga 60–90% menggunakan proxy RTK (Rust Token Killer).

---

## 2. System Boundaries
- **In-Scope**:
  - Konfigurasi runtime Antigravity (`~/.gemini/settings.json`, `~/.gemini/antigravity-cli/settings.json`, `~/.gemini/config/config.json`).
  - Integrasi MCP client (`mcp_config.json`).
  - Terminal statusline dan audio notification hooks macOS.
  - Script installer dan symlink/hardlink orchestrator (`install.sh`).
  - Utilitas CLI akun ganda Antigravity (`swagy.sh` / `swagy`).
  - Custom skills yang dipasang ke `~/.agents/skills/`.
  - Definisi custom subagent role (`config/agents/devops`, `config/agents/code-reviewer`).
- **Out-of-Scope**:
  - Kode sumber binary engine Antigravity itu sendiri.
  - Binary binary eksternal seperti `rtk`, `podman`, `kubectl`, atau Node runtime (diasumsikan sudah terpasang di host macOS).

---

## 3. Main Actors & Surfaces
1. **Developer (User)**: Menjalankan perintah terminal, memicu slash commands (`/ka-*`), dan menyetujui izin perizinan kritis.
2. **Primary AI Agent**: Model AI (Gemini 3.8 Flash / Pro) yang bertindak sebagai pair programmer utama di workspace.
3. **Specialized Subagents**:
   - **`devops`**: Subagent operasional kontainer (Podman), klaster k8s, dan pipeline CI/CD.
   - **`code-reviewer`**: Subagent peninjau kode statis tingkat lanjut khusus Java (Quarkus, Kafka, REST Client) dan Go.
   - **`java-dev-lead`**: Subagent Java Tech Lead & Solutions Architect untuk perancangan arsitektur microservice (Quarkus/Spring Boot), arsitektur reaktif (Kafka, Mutiny), Hexagonal/DDD, dan high-performance enterprise Java.
4. **RTK (Rust Token Killer)**: Proxy CLI lokal yang memfilter dan mengompres output perintah terminal standar untuk menghemat token.
5. **MCP Servers**: Daemon/proses yang menyediakan kapabilitas tambahan (k8s cluster inspection, container status, git diffing, memory indexing, Postman API collections/environments, dan Jira issue tracking).

---

## 4. Domain Concepts & Glossary
- **Skill**: Kumpulan instruksi langkah-demi-langkah (runbook terstandarisasi dalam `SKILL.md`) yang diajarkan kepada agent untuk menyelesaikan tugas kompleks secara konsisten.
- **Hook**: Script yang dieksekusi pada lifecycle event tertentu (misalnya `BeforeTool`), digunakan untuk validasi, manipulasi argumen, atau notifikasi audio.
- **MCP (Model Context Protocol)**: Protokol standar terbuka untuk menghubungkan model AI dengan data/tool eksternal.
- **Self-Healing Symlink**: Mekanisme otomatis di mana script statusline memulihkan tautan symlink konfigurasi jika terputus oleh operasi atomic-write Antigravity CLI.

---

## 5. Runtime Environment & Constraints
- **OS**: macOS (Apple Silicon / Darwin arm64).
- **Shell**: Bash / Zsh dengan ketersediaan tools: `jq`, `sqlite3`, `afplay`, `osascript`, `python3`, `git`.
- **Security & Privacy**:
  - Token OAuth lokal (`antigravity-oauth-token`, `oauth_creds.json`, `google_accounts.json`) diabaikan oleh `.gitignore`.
  - File konfigurasi lokal dengan host atau kredensial internal (`config.json`, `mcp_config.json`) dilindungi dengan `git update-index --skip-worktree`.
