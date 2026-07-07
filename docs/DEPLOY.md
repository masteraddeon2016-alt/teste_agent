# Deploy e CI/CD — Espaço Laser

## 1. Estratégia de Deploy

- **Modelo**: **Rolling** entre ambientes ServiceNow.
- **Empacotamento**: Custom App scoped `x_espaco` versionada via **Source Control (Git)** e/ou **Update Sets**.
- **Repositório**: Git `teste_agent`.

> **Observação**: Este projeto roda **exclusivamente na plataforma ServiceNow (PaaS)**. Não há uso de Docker/containers — o "deploy" corresponde à promoção da aplicação scoped e Update Sets entre instâncias.

## 2. Ambientes

| Ambiente | Instância | Uso |
|---|---|---|
| dev | `<empresa>dev.service-now.com` | Desenvolvimento e commits diários |
| staging | `<empresa>test.service-now.com` | Homologação, UAT, testes ATF |
| prod | `<empresa>.service-now.com` | Produção (SLA ≥ 99,5%) |

## 3. Pipeline CI/CD (GitHub Actions + Source Control ServiceNow)

```
┌──────────┐   commit    ┌───────────────┐  ATF pass  ┌────────────┐  approval  ┌──────────┐
│  DEV     │ ─────────► │ GitHub Actions │ ─────────► │  STAGING   │ ─────────► │  PROD    │
│ (scoped) │  push app  │  - validar     │  promote   │ (UAT/ATF)  │  gated     │ (rolling)│
└──────────┘            │  - rodar ATF   │  Update Set└────────────┘            └──────────┘
                        │  - lint/scan   │
                        └───────────────┘
```

### Etapas do pipeline
1. **Trigger**: push na branch de feature → PR para `main`.
2. **Validação**: sincronização do escopo `x_espaco` com o repositório; verificação de integridade da app.
3. **Testes automáticos**: execução da suíte **ATF** (unit, integration, API, security).
4. **Quality Gate**: cobertura ≥ 80%; nenhum teste crítico falhando.
5. **Promoção a staging**: aplicação do Update Set em staging; UAT e testes de performance.
6. **Aprovação (gated)**: aprovação manual do gestor/DPO.
7. **Promoção a prod**: aplicação rolling do Update Set em produção.

### Exemplo de workflow (`.github/workflows/deploy.yml`)
```yaml
name: espaco-laser-cicd
on:
  push:
    branches: [ main ]
jobs:
  validate-and-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Sync scoped app to dev
        run: ./scripts/sn-sync.sh --scope x_espaco --instance ${{ secrets.SN_DEV_INSTANCE }}
      - name: Run ATF suite
        run: ./scripts/sn-run-atf.sh --suite "Espaco Laser Regression" --instance ${{ secrets.SN_DEV_INSTANCE }}
  promote-staging:
    needs: validate-and-test
    runs-on: ubuntu-latest
    steps:
      - name: Promote Update Set to staging
        run: ./scripts/sn-promote.sh --from dev --to staging --scope x_espaco
  promote-prod:
    needs: promote-staging
    environment: production   # requer aprovação manual
    runs-on: ubuntu-latest
    steps:
      - name: Promote Update Set to prod
        run: ./scripts/sn-promote.sh --from staging --to prod --scope x_espaco
```

## 4. Variáveis e Segredos

| Segredo (GitHub Secrets) | Descrição |
|---|---|
| `SN_DEV_INSTANCE` | URL da instância de dev |
| `SN_STAGING_INSTANCE` | URL da instância de staging |
| `SN_PROD_INSTANCE` | URL da instância de produção |
| `SN_CICD_USER` / `SN_CICD_PASS` | Credenciais do usuário de integração CI/CD |
| `GIT_TOKEN` | Token de acesso ao repositório (rotacionado) |

- Credenciais das integrações externas (CRM, Financeiro, Notificações) em **Connection & Credential Alias** dentro da instância — nunca no pipeline em texto claro.

## 5. Rollback

- **Update Sets**: manter o Update Set anterior; em caso de falha, aplicar **Back Out** do Update Set em produção.
- **Source Control**: reverter para o commit/tag estável anterior e re-promover.
- **Critério de rollback**: falha de smoke test pós-deploy, indisponibilidade > 5 min, ou defeito crítico em dados sensíveis.
- **Smoke tests pós-deploy**: `POST /agendamento` (happy path), `GET /servicos`, login no portal.

## 6. Monitoramento e Alertas

| Item | Ferramenta ServiceNow |
|---|---|
| Disponibilidade / SLA | Instance Health / SLA dashboards |
| Performance de transações | Transaction logs, Performance Analytics |
| Erros de API | System logs + alertas por severidade |
| Falhas de integração | IntegrationHub execution logs + retry |
| Eventos de segurança/LGPD | `sys_audit` + alertas para o DPO |

- **Alertas**: notificação por e-mail/Slack ao time de TI quando: taxa de erro de API > 2%, latência média > 2s, falha de flow de notificação, ou tentativa de acesso negada recorrente.

## 7. Checklist de Go-Live
- [ ] Suíte ATF verde (≥80%).
- [ ] UAT aprovado por gestor e DPO.
- [ ] ACLs e auditoria validadas em staging.
- [ ] Integrações com credenciais configuradas em prod.
- [ ] Smoke tests pós-deploy executados.
- [ ] Plano de rollback validado.
