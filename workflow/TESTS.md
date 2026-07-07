# TESTS.md — Estratégia e Execução de Testes

## 1. Estratégia

Testes automatizados multinível usando o **Automated Test Framework (ATF)** do ServiceNow, complementados por testes de API (Postman/REST API Explorer), performance e segurança. Cobertura mínima: **80%** das regras críticas.

---

## 2. Tipos de Teste

| Tipo | Ferramenta | O que cobre |
|------|-----------|-------------|
| Unit | ATF (Server Script step) | Métodos de Script Includes de domínio (ClienteEntity, PacoteEntity...) |
| Integration | ATF (REST step) | Scripted REST APIs e integração entre camadas |
| E2E | ATF (Form/UI steps) | Fluxos completos: cadastro → agendamento → sessão → dedução |
| Performance | Postman + Performance Analytics | Latência de APIs (< 2s) e portal (< 3s) |
| Security | ATF + revisão manual | ACLs por role/campo, consentimento LGPD |

---

## 3. Suítes ATF

### `x_espaco - Regras Críticas`
| Teste | Regra | Cenário |
|-------|-------|---------|
| Conflito de agenda | RN-02 | Criar 2 agendamentos mesmo profissional/horário → 2º bloqueado |
| Dedução sem saldo | RN-03 | Concluir sessão sem saldo → bloqueado |
| Agendamento sem consentimento | RN-01 | Cliente sem consentimento → agendamento bloqueado |
| Cancelamento < 24h | RN-04 | Cancelar com < 24h → flag de penalidade marcada |
| Pacote esgotado | — | Saldo chega a 0 → status esgotado + evento `pacote.esgotado` |

### `x_espaco - APIs REST`
| Teste | Endpoint | Verificação |
|-------|----------|-------------|
| Listar clientes paginado | GET /clientes | `{data, meta}`, limit default 20 |
| Criar cliente | POST /clientes | 201 + evento `cliente.cadastrado` |
| Criar agendamento conflito | POST /agendamentos | 409 |
| Criar sem campo obrigatório | POST /agendamentos | 400 |
| Recurso inexistente | GET /agendamentos/{id} | 404 |

### `x_espaco - E2E`
| Teste | Fluxo |
|-------|-------|
| Jornada completa | Cadastrar cliente c/ consentimento → agendar → check-in → concluir → verificar dedução de pacote |
| LGPD | Solicitar exclusão → aprovação DPO → anonimização → verificar histórico preservado |

---

## 4. Como Executar

### Via UI
1. *Automated Test Framework > Test Suites*.
2. Selecione `x_espaco - Regras Críticas`.
3. Clique **Run Test Suite**.
4. Verifique resultados em *Test Suite Results*.

### Via CI (REST)
```bash
# disparado automaticamente pelo GitHub Actions (localmachine)
curl -s -X POST \
  "$SN_INSTANCE_URL/api/now/table/sys_atf_test_suite_run" \
  -H "Authorization: Bearer $SN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"test_suite":"<sys_id_suite>"}'
```

---

## 5. Cobertura

- **Meta**: ≥80% das regras críticas (RN-01 a RN-10) e RF principais.
- Relatório gerado em `coverage_report.html`.
- PR bloqueado se cobertura < 80%.

---

## 6. Dados de Teste

- Usar **fixtures isoladas** por teste (setup/teardown ATF).
- **NUNCA** usar dados pessoais reais de clientes.
- Dados de teste anonimizados (ex.: `cliente_teste_01`).

---

## 7. Performance

| Alvo | Limite |
|------|--------|
| APIs de listagem | < 2s com 1000+ registros |
| Telas do portal | < 3s |
| Dashboard (GlideAggregate) | < 3s |
