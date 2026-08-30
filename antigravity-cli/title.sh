#!/bin/bash

# Tangkap pane ID dari argumen pertama, jika tidak ada cari dari $TMUX_PANE, default ke 'global'
TARGET_ID="${1:-${TMUX_PANE:-global}}"
CLEAN_ID=$(echo "$TARGET_ID" | tr -cd '[:alnum:]')
CACHE_FILE="/tmp/tmux_agent_state_${CLEAN_ID}.json"

# 1. Jika ada data masuk dari stdin/pipe, simpan dan gunakan langsung
if [ ! -t 0 ]; then
  cat > "$CACHE_FILE"
  tmux refresh-client -S 2>/dev/null || true
fi

# 2. Jika file cache belum ada atau kosong, inisialisasi default
if [ ! -f "$CACHE_FILE" ] || [ ! -s "$CACHE_FILE" ]; then
  echo '{"agent_state": "idle", "workspace": {"current_dir": ""}}' > "$CACHE_FILE"
fi

# 3. Baca data
DATA=$(cat "$CACHE_FILE" 2>/dev/null || echo '{}')

# 4. Parsing JSON
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

# 5. Mapping emoji (dengan spasi pengaman agar tidak glitch di iTerm2/tmux)
case "$STATE" in
  initializing) EMOJI="🚀 " ;;
  idle)         EMOJI="😴 " ;;
  thinking)     EMOJI="🤔 " ;;
  working)      EMOJI="🏃 " ;;
  tool_use)     EMOJI="⚙️ " ;;
  *)            EMOJI="🤖 " ;;
esac

# 6. Selalu cetak output
echo "${EMOJI}${STATE} | ${WORKSPACE}"