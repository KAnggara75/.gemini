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

# ─── Parse JSON from stdin ───────────────────────────────────────────────────
INPUT_JSON=$(cat)

CLEAN_ID=$(echo "${TMUX_PANE:-global}" | tr -cd '[:alnum:]')
if [ -n "$INPUT_JSON" ]; then
  echo "$INPUT_JSON" > "/tmp/tmux_agent_state_${CLEAN_ID}.json" 2>/dev/null || true
  echo "$INPUT_JSON" > "/tmp/tmux_agent_state_global.json" 2>/dev/null || true
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
  read -r STATE
  read -r USED_PCT
  read -r USED_TOKENS
  read -r TOTAL_TOKENS
  read -r VCS_BRANCH
  read -r VCS_DIRTY
  read -r SANDBOX
  read -r ARTIFACTS
  read -r SUBAGENTS
  read -r BG_TASKS
  read -r MODEL
  read -r CONV_TITLE
  read -r CONV_ID
  read -r WS_DIR
  read -r COLS
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
    (.terminal_width // 80)
  ' 2>/dev/null || printf "idle\n0\n0\n0\n\nfalse\nfalse\n0\n0\n0\n\n\n\n\n80\n"
)"

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

# 3. Fallback ke nama folder workspace (misal: .gemini)
if [ -z "$NAME_TO_SHOW" ] && [ -n "$WS_DIR" ]; then
  NAME_TO_SHOW=$(basename "$WS_DIR")
fi

# 4. Fallback ke short UUID
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

# ─── VCS Branch ──────────────────────────────────────────────────────────────
V=""
if [ -n "$VCS_BRANCH" ]; then
  if [ "$VCS_DIRTY" = "true" ]; then
    V="${FG_GRAY} ╱ ${FG_BRIGHT_RED} ${VCS_BRANCH}${FG_BRIGHT_YELLOW}*${R}"
  else
    V="${FG_GRAY} ╱ ${FG_BRIGHT_BLUE} ${VCS_BRANCH}${R}"
  fi
fi

# ─── Model ───────────────────────────────────────────────────────────────────
M=""
if [ -n "$MODEL" ]; then
  M="${FG_GRAY} ╱ ${FG_BRIGHT_MAGENTA}${MODEL}${R}"
fi

# ─── Sandbox Badge ───────────────────────────────────────────────────────────
if [ "$SANDBOX" = "true" ]; then
  SB="${FG_BRIGHT_GREEN}🛡️ on${R}"
else
  SB="${FG_GRAY}🛡️ off${R}"
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
LINE1="${S}${C}${M}${V}"
LINE2="${CTX}${DOT}${ART_FMT}${DOT}${SUB_FMT}${DOT}${BG_FMT}${DOT}${SB}"

if [ "$COLS" -ge 120 ]; then
  echo -e "${LINE1}  ${FG_GRAY}│${R}  ${LINE2}"
elif [ "$COLS" -ge 80 ]; then
  echo -e "${FG_GRAY}╭─${R} ${LINE1}"
  echo -e "${FG_GRAY}╰─${R} ${LINE2}"
else
  echo -e "${S}${C}${M}"
  echo -e "${CTX}${DOT}${BG_FMT}"
fi