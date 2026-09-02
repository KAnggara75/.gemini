#!/usr/bin/env bash
set -euo pipefail

# Determine repository and target directories
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="${HOME}/.gemini"

echo "=== Installing .gemini configuration ==="
echo "Repo source : ${REPO_DIR}"
echo "Target dir  : ${TARGET_DIR}"
echo

# Ensure base target directories exist
mkdir -p "${TARGET_DIR}/antigravity-cli"
mkdir -p "${TARGET_DIR}/hooks"
mkdir -p "${TARGET_DIR}/config"

# Helper function to link files safely
link_file() {
  local src="$1"
  local dest="$2"

  if [ -e "${dest}" ] || [ -L "${dest}" ]; then
    if [ -L "${dest}" ] && [ "$(readlink "${dest}")" = "${src}" ]; then
      echo "  [OK] Already linked: ${dest} -> ${src}"
      return 0
    fi
    echo "  [BACKUP] Backing up existing ${dest} to ${dest}.bak"
    mv "${dest}" "${dest}.bak"
  fi

  ln -sf "${src}" "${dest}"
  echo "  [LINKED] ${dest} -> ${src}"
}

echo "[1/4] Linking CLI scripts..."
link_file "${REPO_DIR}/antigravity-cli/statusline.sh" "${TARGET_DIR}/antigravity-cli/statusline.sh"
link_file "${REPO_DIR}/antigravity-cli/title.sh" "${TARGET_DIR}/antigravity-cli/title.sh"
chmod +x "${REPO_DIR}/antigravity-cli/statusline.sh" "${REPO_DIR}/antigravity-cli/title.sh"

echo
echo "[2/4] Linking hooks..."
if [ -d "${REPO_DIR}/hooks" ]; then
  for hook_file in "${REPO_DIR}/hooks"/*; do
    if [ -f "${hook_file}" ]; then
      hook_name="$(basename "${hook_file}")"
      link_file "${hook_file}" "${TARGET_DIR}/hooks/${hook_name}"
      chmod +x "${hook_file}"
    fi
  done
fi

echo
echo "[3/4] Linking root configs..."
link_file "${REPO_DIR}/settings.json" "${TARGET_DIR}/settings.json"
link_file "${REPO_DIR}/GEMINI.md" "${TARGET_DIR}/GEMINI.md"

echo
echo "[4/4] Setting up local symlinks & git skip-worktree..."
# Ensure local repo configs point to target ~/.gemini/ configs if they exist
for cfg in "antigravity-cli/settings.json" "config/config.json" "config/mcp_config.json"; do
  if [ -f "${TARGET_DIR}/${cfg}" ] && [ ! -L "${REPO_DIR}/${cfg}" ]; then
    ln -sf "${TARGET_DIR}/${cfg}" "${REPO_DIR}/${cfg}"
    echo "  [LINKED] ${REPO_DIR}/${cfg} -> ${TARGET_DIR}/${cfg}"
  fi
done

# Protect against accidental local leaks
if git -C "${REPO_DIR}" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  git -C "${REPO_DIR}" update-index --skip-worktree antigravity-cli/settings.json 2>/dev/null || true
  git -C "${REPO_DIR}" update-index --skip-worktree config/config.json 2>/dev/null || true
  git -C "${REPO_DIR}" update-index --skip-worktree config/mcp_config.json 2>/dev/null || true
  echo "  [SECURED] Git skip-worktree enabled for local config files."
fi

echo
echo "=== Installation complete! ==="
