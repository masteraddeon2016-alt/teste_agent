# BUILD.md — Como Buildar o Projeto

## 1. Contexto

A aplicação `x_espaco` é uma Custom App scoped ServiceNow. O "build" consiste em sincronizar o código versionado no Git com a instância ServiceNow via **Source Control** e empacotar em **Update Sets** para promoção.

---

## 2. Build Local (Desenvolvimento)

### Pré-requisitos
- Acesso à instância dev ServiceNow.
- Repositório `teste_agent` clonado.
- Agente Bridge `localmachine` configurado (`appsettings.json`).

### Passos
1. **Sincronizar código do Git para a instância dev**
   - Studio → *Import Application from Source Control* (primeira vez).
   - Ou *Source Control > Apply Remote Changes* (atualizações).
2. **Selecionar o escopo** `x_espaco`.
3. **Validar convenções** (executado pelo agente `localmachine`):
   ```bash
   # valida prefixo x_espaco, escopo e Business Rules thin
   ./scripts/validate-conventions.sh
   ```
4. **Compilar widgets** (se houver assets front-end no Service Portal):
   ```bash
   npm ci && npm run build
   ```
5. **Executar ATF** (ver TESTS.md).

---

## 3. Build em CI (GitHub Actions)

O pipeline CI valida cada PR e prepara o artefato de Update Set. Etapas:

```
1. Checkout do repositório
2. Lint/validação de convenções (prefixo x_espaco, escopo, thin BR)
3. Import no ambiente CI ServiceNow via Source Control API
4. Execução de suíte ATF via REST
5. Geração do Update Set exportado (artefato)
6. Publicação do artefato para etapa de deploy
```

Detalhes do YAML em [`CI.md`](CI.md).

---

## 4. Artefatos Gerados

| Artefato | Descrição |
|----------|-----------|
| `x_espaco_<versao>.xml` | Update Set exportado da aplicação scoped |
| `atf_results.json` | Resultado da suíte ATF |
| `coverage_report.html` | Relatório de cobertura de regras críticas |

---

## 5. Checklist de Build

- [ ] Código sincronizado do branch correto (`develop`/`feature/*`).
- [ ] Escopo `x_espaco` selecionado.
- [ ] Validação de convenções sem erros.
- [ ] ATF verde.
- [ ] Update Set exportado sem itens em skipped/preview error.
- [ ] Artefatos publicados.

---

## 6. Troubleshooting

| Problema | Solução |
|----------|---------|
| Preview error no Update Set | Resolver colisões antes do commit; verificar dependências entre tabelas |
| ATF falhando por dados | Garantir que testes usam dados de fixture isolados |
| Escopo global acidental | Reabrir artefato apenas dentro de `x_espaco` |
