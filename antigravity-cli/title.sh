#!/bin/bash

# Tangkap pane/window ID dari argument (default: global)
PANE_ID="${1:-global}"
# Bersihkan karakter khusus seperti % pada ID pane tmux
CLEAN_ID=$(echo "$PANE_ID" | tr -cd '[:alnum:]')
CACHE_FILE="/tmp/tmux_agent_state_${CLEAN_ID}.json"

if [ ! -t 0 ]; then
  cat > "$CACHE_FILE"
fi

if [ ! -f "$CACHE_FILE" ] || [ ! -s "$CACHE_FILE" ]; then
  echo '{"agent_state": "idle", "workspace": {"current_dir": ""}}' > "$CACHE_FILE"
fi

DATA=$(cat "$CACHE_FILE" 2>/dev/null || echo '{}')

STATE=$(echo "$DATA" | jq -r '.agent_state // "idle"' 2>/dev/null || echo "idle")
CWD=$(echo "$DATA" | jq -r '.workspace.current_dir // ""' 2>/dev/null || echo "")

if [ -n "$CWD" ]; then
  if [[ "$CWD" =~ /google/src/cloud/[^/]+/([^/]+) ]]; then
    WORKSPACE="${BASH_REMATCH[1]}"
  else
    WORKSPACE=$(basename "$CWD")
  fi
else
  WORKSPACE="none"
fi

case "$STATE" in
  initializing) EMOJI="🚀 " ;;
  idle)         EMOJI="😴 " ;;
  thinking)     EMOJI="🤔 " ;;
  working)      EMOJI="🏃 " ;;
  tool_use)     EMOJI="⚙️ " ;;
  *)            EMOJI="🤖 " ;;
esac

echo "${EMOJI}${STATE} | ${WORKSPACE}"