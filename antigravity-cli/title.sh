#!/bin/bash

CACHE_FILE="/tmp/tmux_agent_state.json"

# Jika ada data yang dipipa ke stdin, simpan ke cache file
if [ ! -t 0 ]; then
  cat > "$CACHE_FILE"
fi

# Pastikan default JSON valid jika file belum ada
if [ ! -f "$CACHE_FILE" ] || [ ! -s "$CACHE_FILE" ]; then
  echo '{"agent_state": "idle", "workspace": {"current_dir": ""}}' > "$CACHE_FILE"
fi

DATA=$(cat "$CACHE_FILE" 2>/dev/null || echo '{}')

# Parsing JSON menggunakan jq secara aman
STATE=$(echo "$DATA" | jq -r '.agent_state // "idle"' 2>/dev/null || echo "idle")
CWD=$(echo "$DATA" | jq -r '.workspace.current_dir // ""' 2>/dev/null || echo "")

# Ekstraksi nama workspace
if [ -n "$CWD" ]; then
  if [[ "$CWD" =~ /google/src/cloud/[^/]+/([^/]+) ]]; then
    WORKSPACE="${BASH_REMATCH[1]}"
  else
    WORKSPACE=$(basename "$CWD")
  fi
else
  WORKSPACE="none"
fi

# Mapping emoji
case "$STATE" in
  initializing) EMOJI="🚀" ;;
  idle)         EMOJI="😴" ;;
  thinking)     EMOJI="🤔" ;;
  working)      EMOJI="🏃" ;;
  tool_use)     EMOJI="🛠️" ;;
  *)            EMOJI="🤖" ;;
esac

echo "$EMOJI $STATE | $WORKSPACE"