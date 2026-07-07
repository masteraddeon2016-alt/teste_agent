Se um número de fase for passado como argumento ($ARGUMENTS), leia diretamente
`fases/FASE$ARGUMENTS.md` e exiba:
1. **Objetivo** da fase
2. **Pré-requisitos** (o que deve estar pronto antes de começar)
3. **Tarefas** — lista completa com checkboxes
4. **Critérios de aceite** — como validar que a fase está completa
5. **Prompt de execução** — o bloco de instruções específico para implementação

Se nenhum argumento for passado, primeiro leia `.claude/memory/phase-state.json`
para descobrir qual é a `currentPhase`, depois leia o arquivo `fases/FASE{currentPhase}.md`
correspondente e exiba o mesmo conteúdo acima.