#!/bin/bash
# Hook: Stop — executado quando a sessão do Claude Code encerra.
# Se a fase atual ainda está "idle", marca como concluída na plataforma.
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

# Verifica se a fase ainda está idle (não foi concluída por outro mecanismo).
CURRENT_STATUS=$(python3 -c "
import json
try:
    d = json.load(open('.claude/memory/phase-state.json'))
    cp = int('$CURRENT_PHASE')
    phases = [p for p in d.get('phases', []) if p.get('index') == cp]
    print(phases[0].get('status', 'idle') if phases else 'idle')
except Exception:
    print('idle')
" 2>/dev/null)

[ "$CURRENT_STATUS" != "idle" ] && exit 0

curl -s -X POST "$PLATFORM_URL/api/wizard/$SESSION_ID/phases/$CURRENT_PHASE/complete" \
  -H "Content-Type: application/json" \
  && echo "FASE $CURRENT_PHASE marcada como concluida via hook Stop." \
  || echo "Aviso: plataforma offline. Use: ./scripts/notificar-fase.sh $CURRENT_PHASE"