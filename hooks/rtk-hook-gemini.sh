#!/bin/bash
set -eo pipefail

# Baca payload dari stdin
PAYLOAD=$(cat)

# Periksa apakah toolCall adalah ask_question (agent meminta keputusan/input)
TOOL_NAME=$(echo "$PAYLOAD" | jq -r '.toolCall.name // empty' 2>/dev/null || true)

if [ "$TOOL_NAME" = "ask_question" ]; then
  # Mainkan suara notifikasi sistem di background tanpa memblokir
  (afplay /System/Library/Sounds/Glass.aiff &) 2>/dev/null || true
  (osascript -e 'display notification "Agent memerlukan keputusan/konfirmasi Anda!" with title "Antigravity" sound name "Glass"' &) 2>/dev/null || true
fi

# Teruskan payload ke rtk hook gemini
echo "$PAYLOAD" | exec rtk hook gemini
