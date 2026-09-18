#!/bin/bash
set -euo pipefail

# ─── ANSI Helpers (Standard 16-color palette) ─────────────────────────────────
R="\033[0m"
B="\033[1m"
D="\033[2m"
I="\033[3m"

FG_BLACK="\033[30m"
FG_RED="\033[31m"
FG_GREEN="\033[32m"
FG_YELLOW="\033[33m"
FG_BLUE="\033[34m"
FG_MAGENTA="\033[35m"
FG_CYAN="\033[36m"
FG_WHITE="\033[37m"

FG_GRAY="\033[90m"
FG_BRIGHT_RED="\033[91m"
FG_BRIGHT_GREEN="\033[92m"
FG_BRIGHT_YELLOW="\033[93m"
FG_BRIGHT_BLUE="\033[94m"
FG_BRIGHT_MAGENTA="\033[95m"
FG_BRIGHT_CYAN="\033[96m"
FG_BRIGHT_WHITE="\033[97m"

NUM_COLOR="${FG_BRIGHT_WHITE}${B}"

# ─── Handle Direct Cleanup Argument ───────────────────────────────────────────
CLEAN_ID=$(echo "${TMUX_PANE:-global}" | tr -cd '[:alnum:]')
if [ $# -gt 0 ] && [[ "${1:-}" =~ ^(exit|quit|stop|clean|cleanup|shutdown)$ ]]; then
  rm -f "/tmp/tmux_agent_state_${CLEAN_ID}.json" "/tmp/tmux_agent_state_global.json" 2>/dev/null || true
  exit 0
fi

# ─── Parse JSON from stdin ───────────────────────────────────────────────────
INPUT_JSON=$(cat 2>/dev/null || true)
if [ -z "$INPUT_JSON" ]; then
  exit 0
fi

# Helper function untuk format angka k/M
format_tokens() {
  local num=$1
  if [ -z "$num" ] || [ "$num" = "null" ] || [ "$num" -eq 0 ] 2>/dev/null; then
    echo "0"
  elif [ "$num" -ge 1000000 ]; then
    printf "%.1fM" "$(echo "scale=1; $num/1000000" | bc -l 2>/dev/null || awk "BEGIN {printf \"%.1f\", $num/1000000}")"
  elif [ "$num" -ge 1000 ]; then
    printf "%.1fk" "$(echo "scale=1; $num/1000" | bc -l 2>/dev/null || awk "BEGIN {printf \"%.1f\", $num/1000}")"
  else
    echo "$num"
  fi
}

{
  read -r STATE || true
  read -r USED_PCT || true
  read -r USED_TOKENS || true
  read -r TOTAL_TOKENS || true
  read -r VCS_BRANCH || true
  read -r VCS_DIRTY || true
  read -r SANDBOX || true
  read -r ARTIFACTS || true
  read -r SUBAGENTS || true
  read -r BG_TASKS || true
  read -r MODEL || true
  read -r CONV_TITLE || true
  read -r CONV_ID || true
  read -r WS_DIR || true
  read -r COLS || true
  read -r TRANSCRIPT_PATH || true
  read -r USER_EMAIL || true
  read -r QUOTA_5H || true
} <<< "$(
  echo "$INPUT_JSON" | jq -r '
    (.agent_state // "idle"),
    (.context_window.used_percentage // 0),
    (.context_window.used_tokens // 0),
    (.context_window.total_tokens // 0),
    (.vcs.branch // ""),
    (.vcs.dirty // false),
    (.sandbox.enabled // false),
    (.artifact_count // 0),
    (if .subagents | type == "array" then (.subagents | length) else 0 end),
    (.task_count // 0),
    (.model.display_name // ""),
    (.conversation_title // .conversation_name // .title // ""),
    (.conversation_id // .session_id // ""),
    (.workspace.project_dir // .workspace.current_dir // .cwd // ""),
    (.terminal_width // 80),
    (.transcript_path // ""),
    (.email // ""),
    (
      def m: ((.model.display_name // "") | ascii_downcase);
      def is3p: (m | (contains("claude") or contains("gpt") or contains("3p") or contains("sonnet") or contains("haiku") or contains("opus")));
      def frac: (if is3p then (.quota["3p-5h"].remaining_fraction // .quota["gemini-5h"].remaining_fraction // null) else (.quota["gemini-5h"].remaining_fraction // .quota["3p-5h"].remaining_fraction // null) end);
      if frac != null then ((frac * 100) | round) else "" end
    )
  ' 2>/dev/null || printf "idle\n0\n0\n0\n\nfalse\nfalse\n0\n0\n0\n\n\n\n\n80\n\n\n\n"
)"
COLS="${COLS:-80}"
[[ "$COLS" =~ ^[0-9]+$ ]] || COLS=80

# ─── Check Exit State or Save Cache ──────────────────────────────────────────
STATE_LOWER=$(echo "$STATE" | tr '[:upper:]' '[:lower:]')
if [[ "$STATE_LOWER" =~ ^(exit|exited|quit|stopped|terminated|closed|shutdown|offline|done|end|killed)$ ]]; then
  rm -f "/tmp/tmux_agent_state_${CLEAN_ID}.json" "/tmp/tmux_agent_state_global.json" 2>/dev/null || true
  exit 0
fi

echo "$INPUT_JSON" > "/tmp/tmux_agent_state_${CLEAN_ID}.json" 2>/dev/null || true
echo "$INPUT_JSON" > "/tmp/tmux_agent_state_global.json" 2>/dev/null || true

# ─── Sound Notification on Decision / Confirmation Prompt ─────────────────────
CONFIRM_PENDING=$(echo "$INPUT_JSON" | jq -r '.tool_confirmation_pending // false' 2>/dev/null || echo "false")
if [ "$CONFIRM_PENDING" = "true" ]; then
  NOTIF_LOCK="/tmp/antigravity_last_confirm_sound"
  NOW=$(date +%s)
  LAST_TIME=$(cat "$NOTIF_LOCK" 2>/dev/null || echo 0)
  # Debounce minimal 4 detik agar suara tidak berulang secara beruntun
  if [ $((NOW - LAST_TIME)) -ge 4 ]; then
    echo "$NOW" > "$NOTIF_LOCK" 2>/dev/null || true
    (afplay /System/Library/Sounds/Glass.aiff &) 2>/dev/null || true
    (osascript -e 'display notification "Agent memerlukan keputusan/konfirmasi Anda!" with title "Antigravity" sound name "Glass"' &) 2>/dev/null || true
  fi
fi

# ─── Auto-Heal & Sync settings.json (Self-Healing Symlink) ────────────────────
(
  CLI_SETTINGS="${HOME}/.gemini/antigravity-cli/settings.json"
  REPO_SETTINGS="/Users/i/work/KAnggara75/.gemini/antigravity-cli/settings.json"
  if [ -f "$CLI_SETTINGS" ] && [ ! -L "$CLI_SETTINGS" ] && [ -f "$REPO_SETTINGS" ]; then
    # File telah diputus oleh atomic rename CLI - sinkronkan izin terbaru ke repo lalu relink
    cp -f "$CLI_SETTINGS" "$REPO_SETTINGS" 2>/dev/null || true
    ln -sf "$REPO_SETTINGS" "$CLI_SETTINGS" 2>/dev/null || true
  fi
) &


# ─── Computed Values ─────────────────────────────────────────────────────────
PCT_FMT=$(LC_NUMERIC=C printf "%.1f" "$USED_PCT")
PCT_INT=${USED_PCT%.*}; PCT_INT=${PCT_INT:-0}

# ─── State Indicator ─────────────────────────────────────────────────────────
case "$STATE" in
  idle)     S="${FG_BRIGHT_GREEN}${B}● READY${R}" ;;
  thinking) S="${FG_BRIGHT_YELLOW}${B}◆ THINKING${R}" ;;
  working)  S="${FG_BRIGHT_CYAN}${B}⚙ WORKING${R}" ;;
  tool_use) S="${FG_BRIGHT_MAGENTA}${B}🔧 TOOL${R}" ;;
  error)    S="${FG_BRIGHT_RED}${B}✖ ERROR${R}" ;;
  *)        S="${FG_WHITE}${B}⏳ $(echo "$STATE" | tr '[:lower:]' '[:upper:]')${R}" ;;
esac

# ─── Conversation / Session ──────────────────────────────────────────────────
C=""
NAME_TO_SHOW=""

# 1. Cek judul langsung dari JSON payload
if [ -n "$CONV_TITLE" ] && ! [[ "$CONV_TITLE" =~ ^[0-9a-fA-F-]{36}$ ]]; then
  NAME_TO_SHOW="$CONV_TITLE"
fi

# 2. Ambil title percakapan dari SQLite database Antigravity
if [ -z "$NAME_TO_SHOW" ] && [ -n "$CONV_ID" ]; then
  DB_PATHS=(
    "${HOME}/.gemini/antigravity-cli/conversation_summaries.db"
    "${HOME}/.gemini/antigravity/conversation_summaries.db"
  )
  for db in "${DB_PATHS[@]}"; do
    if [ -f "$db" ]; then
      DB_TITLE=$(sqlite3 "$db" "SELECT title FROM conversation_summaries WHERE conversation_id = '$CONV_ID' LIMIT 1;" 2>/dev/null || true)
      if [ -n "$DB_TITLE" ]; then
        NAME_TO_SHOW="$DB_TITLE"
        break
      fi
    fi
  done
fi

if [ -z "$NAME_TO_SHOW" ] && [ -n "$CONV_ID" ]; then
  if [[ "$CONV_ID" =~ ^[0-9a-fA-F-]{36}$ ]]; then
    NAME_TO_SHOW="${CONV_ID:0:8}"
  else
    NAME_TO_SHOW="$CONV_ID"
  fi
fi

if [ -n "$NAME_TO_SHOW" ]; then
  if [ "${#NAME_TO_SHOW}" -gt 24 ]; then
    CONV_DISPLAY="${NAME_TO_SHOW:0:21}..."
  else
    CONV_DISPLAY="$NAME_TO_SHOW"
  fi
  C="${FG_GRAY} ╱ ${FG_BRIGHT_CYAN}💬 ${CONV_DISPLAY}${R}"
fi

# ─── VCS / Git Status (Color-coded status: Green=Clean, Yellow/Red=Dirty) ───
V=""
if [ -z "$VCS_BRANCH" ] && [ -n "$WS_DIR" ] && [ -d "$WS_DIR" ]; then
  if git -C "$WS_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    VCS_BRANCH=$(git -C "$WS_DIR" branch --show-current 2>/dev/null || true)
    if [ -z "$VCS_BRANCH" ]; then
      VCS_BRANCH=$(git -C "$WS_DIR" rev-parse --short HEAD 2>/dev/null || true)
    fi
    if [ -n "$(git -C "$WS_DIR" status --porcelain 2>/dev/null)" ]; then
      VCS_DIRTY="true"
    else
      VCS_DIRTY="false"
    fi
  fi
fi

if [ -n "$VCS_BRANCH" ]; then
  if [ "$VCS_DIRTY" = "true" ]; then
    V="${FG_GRAY} ╱ ${FG_BRIGHT_YELLOW} ${VCS_BRANCH}${R}"
  else
    V="${FG_GRAY} ╱ ${FG_BRIGHT_GREEN} ${VCS_BRANCH}${R}"
  fi
fi

# ─── Model ───────────────────────────────────────────────────────────────────
M=""
if [ -n "$MODEL" ]; then
  M="${FG_GRAY} ╱ ${FG_BRIGHT_MAGENTA}${MODEL}${R}"
fi

# ─── Account & 5h Quota Usage ────────────────────────────────────────────────
ACC_BADGE=""
if [ -z "$USER_EMAIL" ]; then
  USER_EMAIL=$(jq -r '.active // empty' "${HOME}/.gemini/google_accounts.json" 2>/dev/null || true)
fi

if [ -n "$USER_EMAIL" ]; then
  if [[ "$USER_EMAIL" == *"pakaiwa"* ]]; then
    ACC_ALIAS="pwa"
  elif [[ "$USER_EMAIL" == *"kaanggara"* || "$USER_EMAIL" == *"kanggara"* ]]; then
    ACC_ALIAS="kaa"
  else
    ACC_ALIAS="${USER_EMAIL%%@*}"
  fi

  # Format persentase sisa 5-hour quota jika tersedia
  QUOTA_STR=""
  if [ -n "$QUOTA_5H" ] && [[ "$QUOTA_5H" =~ ^[0-9]+$ ]]; then
    if [ "$QUOTA_5H" -ge 50 ]; then
      Q_COLOR="${FG_BRIGHT_GREEN}"
    elif [ "$QUOTA_5H" -ge 20 ]; then
      Q_COLOR="${FG_BRIGHT_YELLOW}"
    else
      Q_COLOR="${FG_BRIGHT_RED}"
    fi
    QUOTA_STR=" ${Q_COLOR}⏳${QUOTA_5H}%${R}"
  fi

  ACC_BADGE="${FG_GRAY} ╱ ${FG_BRIGHT_CYAN}👤 ${ACC_ALIAS}${R}${QUOTA_STR}"
fi

# ─── Sandbox Badge ───────────────────────────────────────────────────────────
if [ "$SANDBOX" = "true" ]; then
  SB="${FG_BRIGHT_GREEN}🛡️ on${R}"
else
  SB="${FG_GRAY}🛡️ off${R}"
fi

# ─── Active Skill & MCP Detection ─────────────────────────────────────────────
ACTIVE_SKILL=""
ACTIVE_MCP=""

if [ -n "$CONV_ID" ]; then
  CACHE_FILE="/tmp/antigravity_skill_mcp_${CLEAN_ID}.json"
  NOW_SEC=$(date +%s)
  LAST_CHECK=$(cat "${CACHE_FILE}.ts" 2>/dev/null || echo 0)

  # Caching selama 2 detik agar pembacaan statusline tetap super ringan
  if [ -f "$CACHE_FILE" ] && [ $((NOW_SEC - LAST_CHECK)) -lt 2 ]; then
    read -r ACTIVE_SKILL ACTIVE_MCP < "$CACHE_FILE" 2>/dev/null || true
  else
    TR_CANDIDATES=(
      "$TRANSCRIPT_PATH"
      "${HOME}/.gemini/antigravity-cli/brain/${CONV_ID}/.system_generated/logs/transcript.jsonl"
      "${HOME}/.gemini/antigravity/brain/${CONV_ID}/.system_generated/logs/transcript.jsonl"
    )
    ACTUAL_TR=""
    for cand in "${TR_CANDIDATES[@]}"; do
      if [ -n "$cand" ] && [ -f "$cand" ]; then
        ACTUAL_TR="$cand"
        break
      fi
    done

    if [ -n "$ACTUAL_TR" ]; then
      INFO=$(python3 -c '
import json, sys

tpath = sys.argv[1]
try:
    with open(tpath, "rb") as f:
        lines = f.readlines()[-160:]
    last_input_idx = -1
    last_user_content = ""
    for idx, line in enumerate(lines):
        try:
            d = json.loads(line.decode("utf-8", errors="ignore"))
            if d.get("type") == "USER_INPUT":
                last_input_idx = idx
                last_user_content = d.get("content", "")
        except: pass

    active_skill = "-"
    if "<SKILL>The user has explicitly invoked the (" in last_user_content:
        active_skill = last_user_content.split("<SKILL>The user has explicitly invoked the (")[1].split(")")[0]

    active_mcp = "-"
    if last_input_idx != -1:
        for line in lines[last_input_idx:]:
            try:
                d = json.loads(line.decode("utf-8", errors="ignore"))
                for tc in d.get("tool_calls", []):
                    if tc.get("name") == "call_mcp_tool":
                        s = tc.get("args", {}).get("ServerName", "").strip("\"'\''")
                        if s: active_mcp = s
                    elif tc.get("name", "").startswith("mcp_"):
                        active_mcp = tc["name"].replace("mcp_", "").split("_")[0]
            except: pass
    print(f"{active_skill} {active_mcp}")
except Exception:
    print("- -")
' "$ACTUAL_TR" 2>/dev/null || echo "- -")

      ACTIVE_SKILL=$(echo "$INFO" | awk '{print $1}')
      ACTIVE_MCP=$(echo "$INFO" | awk '{print $2}')
      echo "${ACTIVE_SKILL:--} ${ACTIVE_MCP:--}" > "$CACHE_FILE" 2>/dev/null || true
      echo "$NOW_SEC" > "${CACHE_FILE}.ts" 2>/dev/null || true
    fi
  fi
fi

if [ -n "$ACTIVE_SKILL" ] && [ "$ACTIVE_SKILL" != "-" ] && [ "$ACTIVE_SKILL" != "none" ]; then
  SKILL_BADGE="${FG_GRAY} ╱ ${FG_BRIGHT_CYAN}⚡ ${ACTIVE_SKILL}${R}"
else
  SKILL_BADGE="${FG_GRAY} ╱ ⚡ -${R}"
fi

if [ -n "$ACTIVE_MCP" ] && [ "$ACTIVE_MCP" != "-" ] && [ "$ACTIVE_MCP" != "none" ]; then
  MCP_BADGE="${FG_GRAY} ╱ ${FG_BRIGHT_YELLOW}🔌 ${ACTIVE_MCP}${R}"
else
  MCP_BADGE="${FG_GRAY} ╱ 🔌 -${R}"
fi



# ─── Context Bar (10 segments) ───────────────────────────────────────────────
BAR_LEN=10
FILLED=$((PCT_INT * BAR_LEN / 100))
REMAINDER=$(( (PCT_INT * BAR_LEN) % 100 ))

if [ "$PCT_INT" -ge 85 ]; then
  BAR_COLOR="$FG_BRIGHT_RED"
elif [ "$PCT_INT" -ge 60 ]; then
  BAR_COLOR="$FG_BRIGHT_YELLOW"
else
  BAR_COLOR="$FG_BRIGHT_GREEN"
fi

BAR=""
for ((i = 0; i < BAR_LEN; i++)); do
  if [ "$i" -lt "$FILLED" ]; then
    BAR="${BAR}█"
  elif [ "$i" -eq "$FILLED" ]; then
    if [ "$REMAINDER" -ge 75 ]; then
      BAR="${BAR}▓"
    elif [ "$REMAINDER" -ge 50 ]; then
      BAR="${BAR}▒"
    elif [ "$REMAINDER" -ge 25 ]; then
      BAR="${BAR}░"
    else
      BAR="${BAR}·"
    fi
  else
    BAR="${BAR}·"
  fi
done

# Token count string (jika tersedia di payload)
TOKEN_INFO=""
if [ "$TOTAL_TOKENS" -gt 0 ] 2>/dev/null; then
  USED_STR=$(format_tokens "$USED_TOKENS")
  TOTAL_STR=$(format_tokens "$TOTAL_TOKENS")
  TOKEN_INFO=" ${FG_GRAY}(${USED_STR}/${TOTAL_STR})${R}"
fi

CTX="${FG_GRAY}ctx ${BAR_COLOR}${BAR} ${NUM_COLOR}${PCT_FMT}%${R}${TOKEN_INFO}"

# ─── Dynamic Highlight Stats ─────────────────────────────────────────────────
# Memberi highlight hanya ketika count > 0 agar fokus ke aktivitas penting
if [ "$ARTIFACTS" -gt 0 ] 2>/dev/null; then
  ART_FMT="${FG_CYAN}📦 ${NUM_COLOR}${ARTIFACTS}${R}"
else
  ART_FMT="${FG_GRAY}📦 0${R}"
fi

if [ "$SUBAGENTS" -gt 0 ] 2>/dev/null; then
  SUB_FMT="${FG_BRIGHT_YELLOW}🤖 ${NUM_COLOR}${SUBAGENTS}${R}"
else
  SUB_FMT="${FG_GRAY}🤖 0${R}"
fi

if [ "$BG_TASKS" -gt 0 ] 2>/dev/null; then
  BG_FMT="${FG_BRIGHT_GREEN}⚡ ${NUM_COLOR}${BG_TASKS}${R}"
else
  BG_FMT="${FG_GRAY}⚡ 0${R}"
fi

# ─── Separators ──────────────────────────────────────────────────────────────
DOT="${FG_GRAY} · ${R}"

# ─── Output Layout ───────────────────────────────────────────────────────────
LINE1="${S}${C}${M}${SKILL_BADGE}${MCP_BADGE}${V}${ACC_BADGE}"
LINE2="${CTX}${DOT}${ART_FMT}${DOT}${SUB_FMT}${DOT}${BG_FMT}${DOT}${SB}"



if [ "$COLS" -ge 120 ]; then
  echo -e "${LINE1}  ${FG_GRAY}│${R}  ${LINE2}"
elif [ "$COLS" -ge 80 ]; then
  echo -e "${FG_GRAY}╭─${R} ${LINE1}"
  echo -e "${FG_GRAY}╰─${R} ${LINE2}"
else
  echo -e "${S}${C}${M}${ACC_BADGE}"
  echo -e "${CTX}${DOT}${BG_FMT}"
fi