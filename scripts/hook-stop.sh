#!/bin/bash
# Hook: Stop — executado quando a sessão do Claude Code encerra.
# NÃO marca fases como concluídas automaticamente.
#
# Para concluir uma fase, use explicitamente:
#   ./scripts/notificar-fase.sh <numero_da_fase>
# ou a tool MCP: concluir_fase
#
# IMPORTANTE: encerrar um turno NÃO equivale a concluir uma fase.
# A fase só está pronta quando todos os critérios de aceite foram validados.

PHASE_STATE=".claude/memory/phase-state.json"
[ -f "$PHASE_STATE" ] || exit 0

CURRENT_PHASE=$(python3 -c "
import json
try:
    d = json.load(open('.claude/memory/phase-state.json'))
    print(d.get('currentPhase', '?'))
except Exception:
    print('?')
" 2>/dev/null)

echo "[hook-stop] Turno encerrado. Fase em andamento: FASE${CURRENT_PHASE}. Use 'notificar-fase.sh ${CURRENT_PHASE}' apenas quando concluída de verdade."
exit 0
