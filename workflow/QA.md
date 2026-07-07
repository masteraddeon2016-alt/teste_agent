# QA.md — Processo de Garantia de Qualidade

## 1. Objetivo

Garantir que cada entrega da aplicação `x_espaco` cumpra os requisitos funcionais (RF), não funcionais (RNF), regras de negócio (RN) e conformidade LGPD antes de promover para staging/produção.

---

## 2. Níveis de QA

| Nível | Escopo | Responsável |
|-------|--------|-------------|
| QA de código | Convenções, escopo, thin BR, sem GlideRecord em loop | Revisor de PR |
| QA funcional | RF-01 a RF-20 via ATF e testes manuais | QA Analyst |
| QA de regras | RN-01 a RN-10 via ATF | QA Analyst |
| QA LGPD/Segurança | ACLs, consentimento, anonimização, auditoria | DPO + QA |
| QA de performance | APIs < 2s, portal < 3s | QA Performance |
| UAT | Homologação com stakeholders | Cliente / Gestor |

---

## 3. Checklist de Qualidade por Fase

### Fase 1 — Fundação
- [ ] 5 tabelas criadas com campos/tipos corretos.
- [ ] Relacionamentos por reference funcionando.
- [ ] Índices em `cliente` e `data_hora`.
- [ ] 5 roles criadas.
- [ ] Commit no Git.

### Fase 2 — Domínio
- [ ] RN-01: agendamento bloqueado sem consentimento LGPD.
- [ ] RN-02: conflito de horário do profissional bloqueado.
- [ ] RN-03: dedução de sessão sem saldo bloqueada.
- [ ] RN-04: penalidade em cancelamento < 24h.
- [ ] Eventos de domínio disparados.
- [ ] ATF cobrindo regras críticas passando.

### Fase 3 — APIs
- [ ] 7 endpoints funcionando conforme contrato.
- [ ] Paginação (page/limit) e busca.
- [ ] Códigos HTTP corretos (400/404/409/201).
- [ ] Respostas < 2s.

### Fase 4 — LGPD/Segurança
- [ ] Role `leitura` não vê email/telefone.
- [ ] Anonimização mantém histórico referencial.
- [ ] Auditoria de dados sensíveis ativa.
- [ ] Consentimento obrigatório com finalidade e versão.

### Fase 5 — Notificações
- [ ] Notificação ao criar agendamento.
- [ ] Aviso ao cancelar.
- [ ] Lembrete agendado disparado.
- [ ] Cache de serviços invalida em alteração.

### Fase 6 — Interface/Deploy
- [ ] 6 telas navegáveis.
- [ ] Dashboard com KPIs corretos.
- [ ] ATF ≥80% de cobertura.
- [ ] Pipeline promove até produção.

---

## 4. Critérios de Entrega (Definition of Done)

1. Todos os critérios de aceite da fase cumpridos.
2. ATF verde com cobertura ≥80% das regras críticas.
3. Sem defeitos de severidade Alta/Crítica em aberto.
4. QA LGPD aprovado pelo DPO (para fases 1, 4, 6).
5. Documentação atualizada (`docs/`).
6. PR revisado e mergeado em `develop`.

---

## 5. Classificação de Defeitos

| Severidade | Definição | SLA de correção |
|------------|-----------|-----------------|
| Crítica | Perda/vazamento de dado pessoal, sistema indisponível | Imediato |
| Alta | RN/RF crítica não atendida | 24h |
| Média | Funcionalidade parcial, workaround existe | 3 dias |
| Baixa | Cosmético, UX menor | Backlog |

---

## 6. Registro

Defeitos registrados como incidentes/histórias na instância ServiceNow, vinculados à fase e ao RF/RN correspondente.
