Leia `.claude/memory/phase-state.json` e exiba o status de implementação do projeto:

1. **Fase atual** — o valor de `currentPhase`
2. **Todas as fases** — número, nome, objetivo e status (idle/done/failed) com timestamps
3. **Resumo** — total de fases, concluídas, pendentes, falhas
4. **Próxima ação** — qual fase deve ser implementada agora

Se o arquivo `phase-state.json` não existir ainda, liste os arquivos em `fases/`
para identificar quais fases existem.