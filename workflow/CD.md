# CD.md — Pipeline de Entrega/Deploy Contínuo

## 1. Objetivo

Promover a aplicação `x_espaco` entre ambientes `dev → staging → prod` via Update Sets, com estratégia **rolling**, executado pelo agente Bridge `localmachine2`.

---

## 2. Ambientes

| Ambiente | Uso | Gatilho de deploy |
|----------|-----|-------------------|
| dev | Desenvolvimento | Automático a cada merge em `develop` |
| staging | Homologação/UAT | Automático em branch `release/*` |
| prod | Produção | Manual (approval) após tag `vX.Y.Z` em `main` |

---

## 3. Estratégia Rolling

A promoção ocorre de forma incremental com validação em cada etapa:
```
[Artefato CI verde] --> Staging --> Smoke Tests --> Approval --> Prod --> Smoke Tests
                                          |                              |
                                    (falha=rollback)              (falha=rollback)
```

---

## 4. Workflow GitHub Actions (`.github/workflows/cd.yml`)

```yaml
name: CD - Espaco Laser (x_espaco)

on:
  push:
    tags: ['v*']
  workflow_dispatch:

jobs:
  deploy-staging:
    runs-on: self-hosted   # agente Bridge localmachine2
    environment: staging
    steps:
      - uses: actions/checkout@v4
      - name: Baixar artefato Update Set
        uses: actions/download-artifact@v4
        with:
          name: x_espaco-update-set
      - name: Importar Update Set no Staging
        env:
          SN_INSTANCE_URL: ${{ secrets.SN_STAGING_URL }}
          SN_TOKEN: ${{ secrets.SN_STAGING_TOKEN }}
        run: ./scripts/import-update-set.sh
      - name: Smoke tests Staging
        run: ./scripts/smoke-tests.sh staging

  deploy-prod:
    needs: deploy-staging
    runs-on: self-hosted   # agente Bridge localmachine2
    environment: production   # requer approval manual
    steps:
      - uses: actions/checkout@v4
      - name: Importar Update Set em Producao
        env:
          SN_INSTANCE_URL: ${{ secrets.SN_PROD_URL }}
          SN_TOKEN: ${{ secrets.SN_PROD_TOKEN }}
        run: ./scripts/import-update-set.sh
      - name: Smoke tests Producao
        run: ./scripts/smoke-tests.sh prod
      - name: Notificar stakeholders
        run: ./scripts/notify-release.sh
```

---

## 5. Smoke Tests Pós-Deploy

| Verificação | Endpoint/Tela |
|-------------|---------------|
| API viva | GET /api/x_espaco/servicos → 200 |
| Criar agendamento | POST /api/x_espaco/agendamentos → 201/409 |
| Portal carrega | /sp?id=espacolaser_agendamento |
| Dashboard | /nav_to.do?uri=x_espacolaser_dashboard |

---

## 6. Rollback

1. Reverter o Update Set no ServiceNow (*System Update Sets > Committed > Back Out*).
2. Restaurar tag anterior no Git.
3. Re-executar smoke tests.
4. Registrar incidente e causa raiz.

---

## 7. Segurança do CD

- Credenciais de instância via GitHub Secrets / Credential Alias.
- Deploy em prod exige **approval manual** (environment protection rule).
- Todas as promoções logadas em `workflow/logs/`.
- Integrações on-premises (CRM/Financeiro) via MID Server do agente `localmachine2`.

---

## 8. Disponibilidade

- SLA alvo ≥99,5% (alinhado à instância ServiceNow).
- Janela de deploy fora do horário de operação das unidades.
