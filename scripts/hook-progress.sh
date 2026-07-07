#!/bin/bash
# Hook: PostToolUse — executado após cada uso de Write, Edit ou Bash.
# Envia um evento de progresso ao feed da plataforma (fire-and-forget).
# Gerado automaticamente — pode ser editado localmente se necessário.

PHASE_STATE=".claude/memory/phase-state.json"
[ -f "$PHASE_STATE" ] || exit 0

read -r SESSION_ID PLATFORM_URL CURRENT_PHASE < <(python3 -c "
import json, sys
try:
    d = json.load(open('.claude/memory/phase-state.json'))
    print(d.get('sessionId',''), d.get('platformUrl',''), d.get('currentPhase', 0))
except Exception:
    print('', '', 0)
" 2>/dev/null)

[ -z "$SESSION_ID" ] && exit 0
[ "$CURRENT_PHASE" = "0" ] && exit 0

TOOL="${CLAUDE_TOOL_NAME:-tool}"
FILE="${CLAUDE_TOOL_INPUT_FILE_PATH:-}"
if [ -n "$FILE" ]; then MSG="[$TOOL] $FILE"; else MSG="[$TOOL]"; fi

curl -s -X POST "${PLATFORM_URL}/api/wizard/${SESSION_ID}/phases/${CURRENT_PHASE}/event" \
  -H "Content-Type: application/json" \
  -d "{\"mensagem\": \"$MSG\"}" \
  > /dev/null 2>&1 &

exit 0