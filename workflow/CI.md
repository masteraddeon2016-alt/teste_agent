# CI.md — Pipeline de Integração Contínua

## 1. Objetivo

Validar automaticamente cada PR/commit: convenções, import no ambiente CI, execução de ATF e geração de artefato de Update Set. Executado pelo agente Bridge `localmachine`.

---

## 2. Gatilhos

| Evento | Ação |
|--------|------|
| PR para `develop` | Validação completa + ATF |
| Push em `feature/*` | Lint + validação de convenções |
| Push em `develop` | Validação + ATF + export de artefato |

---

## 3. Workflow GitHub Actions (`.github/workflows/ci.yml`)

```yaml
name: CI - Espaco Laser (x_espaco)

on:
  pull_request:
    branches: [develop, main]
  push:
    branches: [develop, 'feature/**']

jobs:
  validate:
    runs-on: self-hosted   # agente Bridge localmachine
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Validar convencoes x_espaco
        run: ./scripts/validate-conventions.sh

      - name: Aplicar codigo na instancia CI (Source Control)
        env:
          SN_INSTANCE_URL: ${{ secrets.SN_CI_INSTANCE_URL }}
          SN_TOKEN: ${{ secrets.SN_CI_TOKEN }}
        run: ./scripts/apply-remote-changes.sh

      - name: Executar suite ATF
        env:
          SN_INSTANCE_URL: ${{ secrets.SN_CI_INSTANCE_URL }}
          SN_TOKEN: ${{ secrets.SN_CI_TOKEN }}
        run: ./scripts/run-atf.sh 'x_espaco - Regras Criticas'

      - name: Verificar cobertura minima (80%)
        run: ./scripts/check-coverage.sh 80

      - name: Exportar Update Set (artefato)
        if: github.ref == 'refs/heads/develop'
        run: ./scripts/export-update-set.sh

      - name: Publicar artefato
        if: github.ref == 'refs/heads/develop'
        uses: actions/upload-artifact@v4
        with:
          name: x_espaco-update-set
          path: artifacts/x_espaco_*.xml
```

---

## 4. Validações Obrigatórias (bloqueiam merge)

1. Prefixo `x_espaco` em tabelas/scripts.
2. Nenhum item em escopo global.
3. Business Rules thin (sem regra de negócio inline).
4. Sem `GlideRecord` dentro de loops.
5. ATF verde.
6. Cobertura ≥80%.

---

## 5. Segredos do CI

Armazenados em GitHub Secrets (nunca em código):
- `SN_CI_INSTANCE_URL`
- `SN_CI_TOKEN`
- `GIT_TOKEN`

> Tokens dos agentes Bridge ficam no `appsettings.json` local do agente, fora do versionamento.

---

## 6. Status e Notificações

- Status do CI reportado no PR (check obrigatório).
- Falhas notificam o canal da equipe via IntegrationHub.
