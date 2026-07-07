# RELEASE.md — Processo de Release

## 1. Versionamento

Segue **Semantic Versioning** `MAJOR.MINOR.PATCH`:
- **MAJOR**: mudança incompatível no modelo de dados ou contrato de API.
- **MINOR**: nova funcionalidade compatível (nova tela, novo endpoint).
- **PATCH**: correção de bug/ajuste sem quebra.

Exemplos por fase:
| Versão | Marco |
|--------|-------|
| `0.1.0` | Fase 1 — Fundação e modelo de dados |
| `0.2.0` | Fase 2 — Domínio e regras |
| `0.3.0` | Fase 3 — APIs REST |
| `0.4.0` | Fase 4 — LGPD/Segurança |
| `0.5.0` | Fase 5 — Notificações |
| `1.0.0` | Fase 6 — Interface, testes e deploy em produção |

---

## 2. Fluxo de Release

```
feature/* --> develop --> release/x.y.z --> main (tag vX.Y.Z) --> prod
```

1. Criar branch `release/x.y.z` a partir de `develop`.
2. Congelar escopo (apenas correções).
3. Executar suíte ATF completa + performance.
4. QA e UAT aprovados (ver QA.md).
5. Merge em `main` + criar **tag** `vX.Y.Z`.
6. Exportar Update Set versionado `x_espaco_vX.Y.Z.xml`.
7. Deploy rolling (ver CD.md).

---

## 3. Checklist de Release

- [ ] Todas as fases previstas na versão concluídas.
- [ ] ATF verde (cobertura ≥80%).
- [ ] Zero defeitos Crítica/Alta abertos.
- [ ] QA LGPD aprovado pelo DPO.
- [ ] Update Set sem preview errors.
- [ ] `docs/API_CONTRACTS.md` atualizado.
- [ ] Changelog atualizado.
- [ ] Tag Git criada.
- [ ] Backup/rollback plan definido.
- [ ] Comunicação aos stakeholders enviada.

---

## 4. Changelog (template)

```
## [1.0.0] - AAAA-MM-DD
### Adicionado
- Telas de Service Portal (agendamento, pacotes, histórico...)
- Dashboard de ocupação e faturamento
### Alterado
- Otimização de queries com GlideAggregate
### Segurança
- ACLs field-level para email/telefone
### LGPD
- Anonimização com preservação de histórico referencial
```

---

## 5. Rollback

- Manter Update Set da versão anterior disponível.
- Em caso de falha crítica pós-deploy: reverter Update Set no ServiceNow e restaurar tag anterior no Git.
- Executar smoke tests após rollback.

---

## 6. Janela de Release

- Preferencialmente fora do horário de operação das unidades.
- Notificar recepção e gestores com 48h de antecedência.
