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

# Helper function to link files and directories safely
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

echo "[1/6] Linking CLI scripts & settings..."
link_file "${REPO_DIR}/antigravity-cli/statusline.sh" "${TARGET_DIR}/antigravity-cli/statusline.sh"
link_file "${REPO_DIR}/antigravity-cli/title.sh" "${TARGET_DIR}/antigravity-cli/title.sh"
if [ -f "${REPO_DIR}/antigravity-cli/settings.json" ]; then
  link_file "${REPO_DIR}/antigravity-cli/settings.json" "${TARGET_DIR}/antigravity-cli/settings.json"
fi
chmod +x "${REPO_DIR}/antigravity-cli/statusline.sh" "${REPO_DIR}/antigravity-cli/title.sh"

echo
echo "[2/6] Linking hooks..."
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
echo "[3/6] Linking config folder & root configs..."
link_file "${REPO_DIR}/config" "${TARGET_DIR}/config"
link_file "${REPO_DIR}/settings.json" "${TARGET_DIR}/settings.json"
link_file "${REPO_DIR}/GEMINI.md" "${TARGET_DIR}/GEMINI.md"
if [ -f "${REPO_DIR}/memory.jsonl" ]; then
  link_file "${REPO_DIR}/memory.jsonl" "${TARGET_DIR}/memory.jsonl"
  # Maintain backward compatibility link for legacy tools expecting memory.json
  ln -sf "${TARGET_DIR}/memory.jsonl" "${TARGET_DIR}/memory.json"
elif [ -f "${REPO_DIR}/memory.json" ]; then
  link_file "${REPO_DIR}/memory.json" "${TARGET_DIR}/memory.json"
fi

echo
echo "[4/6] Setting up skills..."
AGENTS_SKILLS_DIR="${HOME}/.agents/skills"
mkdir -p "${AGENTS_SKILLS_DIR}"
mkdir -p "${REPO_DIR}/skills"

# Ensure ~/.gemini/skills points to ~/.agents/skills
if [ ! -e "${TARGET_DIR}/skills" ] && [ ! -L "${TARGET_DIR}/skills" ]; then
  ln -sf "${AGENTS_SKILLS_DIR}" "${TARGET_DIR}/skills"
  echo "  [LINKED] ${TARGET_DIR}/skills -> ${AGENTS_SKILLS_DIR}"
fi

# Link all skill directories in skills/ to ~/.agents/skills/
if [ -d "${REPO_DIR}/skills" ]; then
  for skill_dir in "${REPO_DIR}/skills"/*; do
    if [ -d "${skill_dir}" ]; then
      skill_name="$(basename "${skill_dir}")"
      link_file "${skill_dir}" "${AGENTS_SKILLS_DIR}/${skill_name}"
    fi
  done
fi

echo
echo "[5/6] Linking binaries & CLI tools..."
chmod +x "${REPO_DIR}/skills/ka-del-conversation/clean-conversations.sh" "${REPO_DIR}/skills/ka-del-conversation/scripts/clean_conversations.py"

# Link to ~/.local/bin and ~/.gemini/antigravity-cli/bin (both in PATH)
for bin_dir in "${HOME}/.local/bin" "${TARGET_DIR}/antigravity-cli/bin"; do
  if [ -d "${bin_dir}" ]; then
    link_file "${REPO_DIR}/skills/ka-del-conversation/clean-conversations.sh" "${bin_dir}/clean-conversations"
  fi
done

echo
echo "[6/6] Setting up git skip-worktree..."

# Protect against accidental local leaks
if git -C "${REPO_DIR}" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  git -C "${REPO_DIR}" update-index --skip-worktree antigravity-cli/settings.json 2>/dev/null || true
  git -C "${REPO_DIR}" update-index --skip-worktree config/config.json 2>/dev/null || true
  git -C "${REPO_DIR}" update-index --skip-worktree config/mcp_config.json 2>/dev/null || true
  echo "  [SECURED] Git skip-worktree enabled for local config files."
fi

echo
echo "=== Installation complete! ==="
