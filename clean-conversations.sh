#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# Script: clean-conversations.sh
# Wrapper shell script untuk scripts/clean_conversations.py
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PYTHON_BIN="$(command -v python3 || command -v python || true)"

if [ -z "${PYTHON_BIN}" ]; then
  echo "Error: Python 3 tidak ditemukan di sistem." >&2
  exit 1
fi

exec "${PYTHON_BIN}" "${SCRIPT_DIR}/scripts/clean_conversations.py" "$@"
