---
name: ka-pr
description: "Membuat Pull Request (PR) ke Bitbucket Server On-Premise berdasarkan repository Git aktif. Gunakan atau aktifkan skill ini ketika pengguna meminta 'buat pr', 'pr dev', atau 'pr uat'."
user-invocable: true
license: MIT
compatibility: Designed for Antigravity AI, Claude Code, and git-based repositories.
metadata:
  version: "2.1.0"
  purpose: "Bitbucket Server automated Pull Request creation"
  triggers:
    - "buat pr"
    - "pr dev"
    - "pr ke dev"
    - "pr uat"
    - "pr ke uat"
allowed-tools: Bash(git:*) Bash(rtk:*) Bash(curl:*) Bash(jq:*) Read Grep Glob
---

# Skill: Create Bitbucket Server Pull Request

Runbook terstandarisasi untuk membuat Pull Request (PR) ke **Bitbucket Server On-Premise** secara aman, efisien, dan tervalidasi.

---

## Core Objectives & Guardrails

### 1. Zero Hardcoding (Git Remote as Single Source of Truth)
- Base URL, Project Key, dan Repository Slug **WAJIB** diparse langsung dari Git remote `origin`.
- **Dilarang** melakukan hardcode pada domain/host, Project Key, maupun Repository Slug di dalam script atau prompt.

### 2. Strict Credential Isolation
- Autentikasi menggunakan environment variable `BITBUCKET_TOKEN`.
- **Dilarang** menampilkan nilai token ke chat, log, stdout/stderr, maupun payload file di disk.
- Jangan meminta pengguna mengirimkan token secara langsung di chat.

### 3. Non-Destructive Git Operations
- Tidak boleh melakukan force push otomatis (`--force` / `-f`).
- Push ke remote hanya dilakukan jika upstream belum ada atau terdapat commit lokal yang belum ter-push.

### 4. Mandatory User Interaction
- Target branch (`development` atau `uat`) dan reviewer **WAJIB dikonfirmasi kepada pengguna** sebelum HTTP `POST` dieksekusi.

---

## Step-by-Step Workflow

### STEP 1: Deteksi & Ekstraksi Repository Remote

Jalankan perintah untuk mengambil URL remote `origin`:
```bash
REMOTE_URL=$(git remote get-url origin)
```

Lakukan parsing URL remote:

| Protokol Remote   | Contoh URL Input                             | Format Parsing                                               |
| :---------------- | :------------------------------------------- | :----------------------------------------------------------- |
| **HTTPS**         | `https://<host>/scm/<project>/<repo>.git`    | Host: `https://<host>`, Project: `<project>`, Repo: `<repo>` |
| **SSH Standard**  | `ssh://git@<host>:7999/<project>/<repo>.git` | Host: `https://<host>`, Project: `<project>`, Repo: `<repo>` |
| **SSH SCP-style** | `git@<host>:<project>/<repo>.git`            | Host: `https://<host>`, Project: `<project>`, Repo: `<repo>` |

#### Script Helper Parsing:
```bash
# Hapus suffix .git jika ada
CLEAN_URL="${REMOTE_URL%.git}"

if [[ "$CLEAN_URL" =~ ^https?://([^/]+)/scm/([^/]+)/(.+)$ ]]; then
    BITBUCKET_BASE_URL="https://${BASH_REMATCH[1]}"
    PROJECT_KEY="${BASH_REMATCH[2]}"
    REPO_SLUG="${BASH_REMATCH[3]}"
elif [[ "$CLEAN_URL" =~ ^ssh://git@([^:/]+)(:[0-9]+)?/([^/]+)/(.+)$ ]]; then
    BITBUCKET_BASE_URL="https://${BASH_REMATCH[1]}"
    PROJECT_KEY="${BASH_REMATCH[3]}"
    REPO_SLUG="${BASH_REMATCH[4]}"
elif [[ "$CLEAN_URL" =~ ^git@([^:]+):([^/]+)/(.+)$ ]]; then
    BITBUCKET_BASE_URL="https://${BASH_REMATCH[1]}"
    PROJECT_KEY="${BASH_REMATCH[2]}"
    REPO_SLUG="${BASH_REMATCH[3]}"
fi
```

#### Validasi Hasil Parsing:
- Pastikan `BITBUCKET_BASE_URL`, `PROJECT_KEY`, dan `REPO_SLUG` tidak kosong.
- Jika salah satu kosong, **hentikan proses** dan berikan pesan kesalahan kepada pengguna bahwa remote Git `origin` tidak valid.

---

### STEP 2: Verifikasi State Branch & Remote Sync

#### 2.1 Cek Source Branch
```bash
SOURCE_BRANCH=$(git branch --show-current)
```
- Jika kosong (*detached HEAD*), **hentikan proses** dan minta pengguna checkout ke branch kerja.
- Pastikan source branch bukan target branch:
  ```text
  SOURCE_BRANCH != "development" && SOURCE_BRANCH != "uat"
  ```
  Jika source branch adalah `development` atau `uat`, **hentikan proses** (PR tidak valid).

#### 2.2 Sinkronisasi Remote & Push
Periksa apakah local branch sudah ter-push ke remote:
```bash
git fetch origin
```

Cek upstream branch:
```bash
UPSTREAM=$(git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null || true)
```
- **Jika upstream belum ada**:
  ```bash
  git push -u origin "$SOURCE_BRANCH"
  ```
- **Jika upstream sudah ada tetapi ada commit lokal belum ter-push**:
  ```bash
  git push origin "$SOURCE_BRANCH"
  ```

---

### STEP 3: Validasi Autentikasi Token

Periksa ketersediaan environment variable `BITBUCKET_TOKEN`:
```bash
if [ -z "${BITBUCKET_TOKEN:-}" ]; then
  echo "Error: BITBUCKET_TOKEN belum diset di environment."
  echo "Silakan jalankan di terminal: export BITBUCKET_TOKEN=\"Bearer <token_anda>\""
  exit 1
fi
```

Normalisasi format authorization header:
```bash
if [[ "$BITBUCKET_TOKEN" == Bearer\ * ]]; then
    AUTH_HEADER="$BITBUCKET_TOKEN"
else
    AUTH_HEADER="Bearer $BITBUCKET_TOKEN"
fi
```

---

### STEP 4: Konfirmasi Target Branch & Reviewers

Sebelum membuat payload dan mengirim request, **tanyakan kepada pengguna**:

1. **Target Branch**:
   - `development` (Default / Fitur baru & bugfix reguler)
   - `uat` (Staging / Rilis)
2. **Reviewers**:
   - Minta daftar username Bitbucket reviewer (pisahkan dengan koma jika lebih dari satu, misal: `john.doe, jane.smith`).

#### Validasi:
- Target branch **hanya boleh** `development` atau `uat`.
- Pastikan `SOURCE_BRANCH != TARGET_BRANCH`.

---

### STEP 5: Generate Title & Description

#### 5.1 Judul PR (Title)
Ambil subjek commit terakhir dari branch:
```bash
TITLE=$(git log -1 --pretty=format:'%s')
```

#### 5.2 Deskripsi PR (Description)
Generate ringkasan commit dari perbedaan branch target ke branch source:
```bash
COMMITS_DIFF=$(git log "origin/${TARGET_BRANCH}..${SOURCE_BRANCH}" --pretty=format:'- %h %s')
```
- Jika `COMMITS_DIFF` kosong, **hentikan proses**: tidak ada perbedaan commit untuk dibuatkan PR.

Deskripsi disusun dengan format:
```markdown
### Summary of Changes
<COMMITS_DIFF>
```

---

### STEP 6: Pembuatan Payload & Eksekusi API

#### 6.1 Format Payload JSON Aman (`jq`)
Gunakan temporary file `/tmp/pr_payload.json` untuk menghindari *shell escaping issue*:

```bash
# Format array reviewer ke JSON
REVIEWERS_JSON=$(echo "$REVIEWERS" | tr ',' '\n' | sed 's/^[ \t]*//;s/[ \t]*$//' | grep -v '^$' | jq -R '{"user": {"name": .}}' | jq -s '.')

jq -n \
  --arg title "$TITLE" \
  --arg desc "$DESCRIPTION" \
  --arg source "$SOURCE_BRANCH" \
  --arg target "$TARGET_BRANCH" \
  --arg repo "$REPO_SLUG" \
  --arg project "$PROJECT_KEY" \
  --argjson reviewers "$REVIEWERS_JSON" \
  '{
    title: $title,
    description: $desc,
    state: "OPEN",
    open: true,
    closed: false,
    fromRef: {
      id: ("refs/heads/" + $source),
      repository: {
        slug: $repo,
        name: null,
        project: {
          key: $project
        }
      }
    },
    toRef: {
      id: ("refs/heads/" + $target),
      repository: {
        slug: $repo,
        name: null,
        project: {
          key: $project
        }
      }
    },
    locked: false,
    reviewers: $reviewers
  }' > /tmp/pr_payload.json
```

#### 6.2 Eksekusi REST API Bitbucket
Endpoint URL dibangun secara dinamis:
```text
${BITBUCKET_BASE_URL}/rest/api/1.0/projects/${PROJECT_KEY}/repos/${REPO_SLUG}/pull-requests
```

Kirim request via `curl`:
```bash
HTTP_CODE=$(curl \
  --silent \
  --show-error \
  --output /tmp/pr_response.json \
  --write-out "%{http_code}" \
  --request POST \
  --url "${BITBUCKET_BASE_URL}/rest/api/1.0/projects/${PROJECT_KEY}/repos/${REPO_SLUG}/pull-requests" \
  --header "Authorization: ${AUTH_HEADER}" \
  --header "Content-Type: application/json" \
  --data @/tmp/pr_payload.json)
```

---

### STEP 7: Penanganan Respons & Output

#### 7.1 Berhasil (HTTP 200 / 201)
Ambil URL PR langsung dari properti respons Bitbucket:
```bash
PR_ID=$(jq -r '.id' /tmp/pr_response.json)
PR_URL=$(jq -r '.links.self[0].href' /tmp/pr_response.json)
```

Tampilkan informasi ringkas kepada pengguna:
```text
 Pull Request berhasil dibuat!

- Repository : <PROJECT_KEY>/<REPO_SLUG>
- PR ID      : #<PR_ID>
- Source     : <SOURCE_BRANCH>
- Target     : <TARGET_BRANCH>
- Reviewers  : <REVIEWERS>
- Link PR    : <PR_URL>
```

#### 7.2 Error Handling
| Kode HTTP           | Penyebab Umum                                                      | Tindakan                                                                                              |
| :------------------ | :----------------------------------------------------------------- | :---------------------------------------------------------------------------------------------------- |
| **409 Conflict**    | PR dari branch source ke target sudah pernah dibuat sebelumnya.    | Informasikan bahwa PR sudah ada. Tampilkan error message dari API. Dilarang mencoba membuat duplikat. |
| **401 / 403**       | Token tidak valid, kedaluwarsa, atau permission repository kurang. | Informasikan pengecekan token/permission tanpa mengekspos token.                                      |
| **404 Not Found**   | Project key, repository slug, atau target branch tidak ditemukan.  | Periksa nama remote dan pastikan target branch ada di remote.                                         |
| **400 Bad Request** | Validasi payload gagal (misal: reviewer tidak valid).              | Tampilkan pesan kesalahan dari respons API setelah disanitasi.                                        |

---

### STEP 8: Pembersihan File Sementara (Cleanup)
Selalu bersihkan payload dan respons:
```bash
rm -f /tmp/pr_payload.json /tmp/pr_response.json
```
