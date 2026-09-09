#!/bin/bash
set -eo pipefail

# Baca payload dari stdin jika ada
PAYLOAD=$(cat || true)

# Suara sistem macOS & notifikasi banner
(afplay /System/Library/Sounds/Glass.aiff &) 2>/dev/null || true
(osascript -e 'display notification "Agent memerlukan keputusan/konfirmasi Anda!" with title "Antigravity" sound name "Glass"' &) 2>/dev/null || true

# Hook PreToolUse mengharapkan output JSON decision: allow
echo '{"decision":"allow"}'
