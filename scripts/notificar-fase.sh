#!/bin/bash
# Notifica a plataforma de gerenciamento que uma fase foi concluída.
# Gerado automaticamente — não editar manualmente.
# Uso: ./scripts/notificar-fase.sh <numero_da_fase>
#
# Exemplo ao finalizar FASE01:
#   ./scripts/notificar-fase.sh 1

SESSION_ID="b0a9e503-1c7a-4cb7-aa2b-ec65d4b04a24"
FASE=${1:?Informe o numero da fase. Ex: ./scripts/notificar-fase.sh 1}
PLATFORM_URL="http://localhost:5001"

curl -s -X POST "$PLATFORM_URL/api/wizard/$SESSION_ID/phases/$FASE/complete" \
  -H "Content-Type: application/json" \
  && echo "✓ FASE$(printf '%02d' "$FASE") marcada como concluida na plataforma." \
  || echo "Nao foi possivel notificar (verifique se a plataforma esta em http://localhost:5001)."