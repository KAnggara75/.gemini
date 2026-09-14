---
name: ka-pr
description: "Creates Pull Requests (PR) to on-premise Bitbucket Server based on the active Git repository. Activate this skill when the user requests 'create pr', 'pr dev', or 'pr uat'."
user-invocable: true
license: MIT
compatibility: Designed for Antigravity AI, Claude Code, and git-based repositories.
metadata:
  version: "2.1.0"
  purpose: "Bitbucket Server automated Pull Request creation"
  triggers:
    - "create pr"
    - "pr dev"
    - "pr to dev"
    - "pr uat"
    - "pr to uat"
allowed-tools: Bash(git:*) Bash(rtk:*) Bash(curl:*) Bash(jq:*) Read Grep Glob
---

# Skill: Create Bitbucket Server Pull Request

Standardized runbook for creating Pull Requests (PR) to an **on-premise Bitbucket Server** safely, efficiently, and with full validation.

---

## Core Objectives & Guardrails

### 1. Zero Hardcoding (Git Remote as Single Source of Truth)
- Base URL, Project Key, and Repository Slug **MUST** be dynamically parsed from Git remote `origin`.
- **Do not** hardcode domains/hosts, Project Keys, or Repository Slugs in scripts or prompts.

### 2. Strict Credential Isolation
- Authentication uses the environment variable `BITBUCKET_TOKEN`.
- **Never** print the token value to chat, logs, stdout/stderr, or payload files on disk.
- Never ask the user to provide their token directly in chat messages.

### 3. Non-Destructive Git Operations
- Do not perform automated force pushes (`--force` / `-f`).
- Push to remote only if upstream is missing or unpushed local commits exist.

### 4. Mandatory User Interaction
- Target branch (`development` or `uat`) and reviewers **MUST be confirmed with the user** before sending the HTTP `POST` request.

---

## Step-by-Step Workflow

### STEP 1: Remote Repository Extraction

Retrieve the remote URL for `origin`:
```bash
REMOTE_URL=$(git remote get-url origin)
```

Parse the remote URL:

| Remote Protocol   | Example URL Input                            | Parsing Target                                               |
| :---------------- | :------------------------------------------- | :----------------------------------------------------------- |
| **HTTPS**         | `https://<host>/scm/<project>/<repo>.git`    | Host: `https://<host>`, Project: `<project>`, Repo: `<repo>` |
| **SSH Standard**  | `ssh://git@<host>:7999/<project>/<repo>.git` | Host: `https://<host>`, Project: `<project>`, Repo: `<repo>` |
| **SSH SCP-style** | `git@<host>:<project>/<repo>.git`            | Host: `https://<host>`, Project: `<project>`, Repo: `<repo>` |

Shell parsing logic:
```bash
if [[ "$REMOTE_URL" =~ ^https?://([^/]+)/scm/([^/]+)/([^/]+)\.git$ ]]; then
  BITBUCKET_HOST="${BASH_REMATCH[1]}"
  PROJECT_KEY="${BASH_REMATCH[2]}"
  REPO_SLUG="${BASH_REMATCH[3]}"
  BITBUCKET_BASE_URL="https://${BITBUCKET_HOST}"
elif [[ "$REMOTE_URL" =~ ^ssh://git@([^:/]+)(:[0-9]+)?/([^/]+)/([^/]+)\.git$ ]]; then
  BITBUCKET_HOST="${BASH_REMATCH[1]}"
  PROJECT_KEY="${BASH_REMATCH[3]}"
  REPO_SLUG="${BASH_REMATCH[4]}"
  BITBUCKET_BASE_URL="https://${BITBUCKET_HOST}"
elif [[ "$REMOTE_URL" =~ ^git@([^:]+):([^/]+)/([^/]+)\.git$ ]]; then
  BITBUCKET_HOST="${BASH_REMATCH[1]}"
  PROJECT_KEY="${BASH_REMATCH[2]}"
  REPO_SLUG="${BASH_REMATCH[3]}"
  BITBUCKET_BASE_URL="https://${BITBUCKET_HOST}"
fi

PROJECT_KEY=$(echo "$PROJECT_KEY" | tr '[:lower:]' '[:upper:]')
```

---

### STEP 2: Active Branch & Git Status Verification

1. Get current branch:
   ```bash
   CURRENT_BRANCH=$(git branch --show-current)
   ```
2. Verify branch is not `master`, `main`, `development`, or `uat`.
3. Check working directory status:
   ```bash
   git status --short
   ```
   If uncommitted changes exist, inform the user or use `ka-git-commit`.
4. Ensure local commits are pushed to remote upstream:
   ```bash
   git push -u origin "$CURRENT_BRANCH"
   ```

---

### STEP 3: Credential Verification (`BITBUCKET_TOKEN`)

Check whether `BITBUCKET_TOKEN` is exported:
```bash
if [ -z "${BITBUCKET_TOKEN:-}" ]; then
  echo "ERROR: BITBUCKET_TOKEN environment variable is not set."
  exit 1
fi
```
Determine header format:
```bash
if [[ "$BITBUCKET_TOKEN" =~ ^[A-Za-z0-9+/=._-]+$ ]]; then
  AUTH_HEADER="Bearer ${BITBUCKET_TOKEN}"
fi
```

---

### STEP 4: Target Branch & PR Metadata Determination

1. **Target Branch Mapping**:
   - `pr dev` -> `development`
   - `pr uat` -> `uat`
   - If unspecified, ask user or default to `development`.
2. **PR Title & Description**:
   - Title: Generate from latest commit summary or branch name (e.g., `feat(auth): add OAuth2 provider`).
   - Description: Summarize changes using bullet points based on `git log origin/<target>..HEAD --oneline`.

---

### STEP 5: Interactive Confirmation

Before creating the PR, present configuration details to user:
- **Repository**: `<PROJECT_KEY>/<REPO_SLUG>`
- **Source Branch**: `<CURRENT_BRANCH>`
- **Target Branch**: `<TARGET_BRANCH>`
- **Title**: `<TITLE>`
- **Reviewers**: `<REVIEWERS>`

---

### STEP 6: Execute Bitbucket REST API Request

#### 6.1 Construct Payload
```bash
jq -n \
  --arg title "$PR_TITLE" \
  --arg desc "$PR_DESCRIPTION" \
  --arg source "$CURRENT_BRANCH" \
  --arg target "$TARGET_BRANCH" \
  --arg repo "$REPO_SLUG" \
  --arg project "$PROJECT_KEY" \
  --argjson reviewers "${REVIEWERS_JSON:-[]}" \
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
        project: { key: $project }
      }
    },
    toRef: {
      id: ("refs/heads/" + $target),
      repository: {
        slug: $repo,
        name: null,
        project: { key: $project }
      }
    },
    locked: false,
    reviewers: $reviewers
  }' > /tmp/pr_payload.json
```

#### 6.2 Send API Request
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

### STEP 7: Response Handling & Output

#### 7.1 Success (HTTP 200 / 201)
```bash
PR_ID=$(jq -r '.id' /tmp/pr_response.json)
PR_URL=$(jq -r '.links.self[0].href' /tmp/pr_response.json)
```

Display confirmation summary:
```text
 Pull Request created successfully!

- Repository : <PROJECT_KEY>/<REPO_SLUG>
- PR ID      : #<PR_ID>
- Source     : <SOURCE_BRANCH>
- Target     : <TARGET_BRANCH>
- Reviewers  : <REVIEWERS>
- Link PR    : <PR_URL>
```

#### 7.2 Error Handling
| HTTP Code | Common Cause | Action |
| :--- | :--- | :--- |
| **409 Conflict** | Pull Request for these branches already exists. | Report existing PR. Do not submit duplicate. |
| **401 / 403** | Invalid token, expired, or insufficient permissions. | Prompt user to verify `BITBUCKET_TOKEN` without printing it. |
| **404 Not Found** | Project key, repository, or branch does not exist on remote. | Verify remote settings and branch existence. |
| **400 Bad Request** | Invalid payload structure or unknown reviewer. | Display sanitized error message from API response. |

---

### STEP 8: Cleanup Temporary Files
Always clean up payload and response files:
```bash
rm -f /tmp/pr_payload.json /tmp/pr_response.json
```
