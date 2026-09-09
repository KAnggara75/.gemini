#!/bin/bash
set -eo pipefail

# Baca payload dari stdin
PAYLOAD=$(cat)

# Ekstrak toolCall name dan args
TOOL_NAME=$(echo "$PAYLOAD" | jq -r '.toolCall.name // empty' 2>/dev/null || true)

play_sound() {
  (afplay /System/Library/Sounds/Glass.aiff &) 2>/dev/null || true
  (osascript -e 'display notification "Agent memerlukan keputusan/konfirmasi Anda!" with title "Antigravity" sound name "Glass"' &) 2>/dev/null || true
}

# 1. Jika toolCall adalah ask_question, mainkan suara & teruskan
if [ "$TOOL_NAME" = "ask_question" ]; then
  play_sound
  echo "$PAYLOAD" | exec rtk hook gemini
fi

# 2. Jika toolCall adalah eksekusi shell command (run_command / run_shell_command)
if [ "$TOOL_NAME" = "run_command" ] || [ "$TOOL_NAME" = "run_shell_command" ]; then
  CMD=$(echo "$PAYLOAD" | jq -r '.toolCall.args.CommandLine // .toolCall.args.command // empty' 2>/dev/null || true)

  if [ -n "$CMD" ]; then
    # Periksa apakah command sudah ada di daftar auto-allow permissions (~/.gemini/antigravity-cli/settings.json)
    SETTINGS_FILE="${HOME}/.gemini/antigravity-cli/settings.json"
    IS_ALLOWED=false

    if [ -f "$SETTINGS_FILE" ]; then
      # Ambil daftar permissions.allow
      # Matcher pattern format: command(cmd_prefix)
      MATCH=$(jq -r --arg cmd "$CMD" '
        .permissions.allow[]? | 
        select(startswith("command(")) | 
        sub("^command\\("; "") | sub("\\)$"; "") |
        select($cmd == . or ($cmd | startswith(. + " ")))
      ' "$SETTINGS_FILE" 2>/dev/null || true)

      if [ -n "$MATCH" ]; then
        IS_ALLOWED=true
      fi
    fi

    # Jika command TIDAK termasuk dalam allowed permissions, Antigravity akan memicu prompt konfirmasi ke user
    if [ "$IS_ALLOWED" = "false" ]; then
      play_sound
    fi
  fi
fi

# Teruskan payload ke rtk hook gemini
echo "$PAYLOAD" | exec rtk hook gemini
