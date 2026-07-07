# Roadmap — Espaço Laser

Projeto planejado em **6 fases** ao longo de ~12 semanas (~4 meses de calendário), complexidade 4/5.

## Visão Geral do Cronograma

```
Semana:  1   2   3   4   5   6   7   8   9   10  11  12
Fase 1  [===]                                            Fundação + Modelo de Dados
Fase 2      [=======]                                    Domínio + Regras
Fase 3              [=======]                             Casos de Uso + REST APIs
Fase 4                      [=======]                     LGPD + Segurança + Auditoria
Fase 5                              [===]                 Fluxos + Notificações
Fase 6                                  [=============]   Interface + Testes + Deploy
```

| Fase | Marco (mês) | Entrega |
|---|---|---|
| 1 | Mês 1 | Fundação e modelo de dados prontos |
| 2 | Mês 1–2 | Domínio e regras de negócio implementados |
| 3 | Mês 2 | APIs REST operacionais |
| 4 | Mês 2–3 | Conformidade LGPD e segurança garantidas |
| 5 | Mês 3 | Notificações e integrações ativas |
| 6 | Mês 3–4 | Interface, testes e deploy em produção |

---

## Fase 1 — Fundação da Aplicação Scoped e Modelo de Dados
**Estimativa**: 6 dias · **Semanas 1–2**

**Objetivo**: Criar a aplicação scoped `x_espaco` com modelo de dados completo, roles e estrutura base de Clean Architecture/DDD.

**Entregáveis**: App scoped publicada; 5+ tabelas com relacionamentos; roles; esqueleto de Script Includes por camada.

**Dependências**: Instância ServiceNow licenciada; repositório Git `teste_agent`; plugins Custom App scoped.

**Critérios de conclusão**: tabelas criadas com campos conforme entidades; referências funcionando; roles atribuíveis; app versionada no Git.

**Riscos da fase**: escopo ambíguo (mitigação: workshop de requisitos); customização fora do escopo (mitigação: estritamente scoped).

---

## Fase 2 — Camada de Domínio e Regras de Negócio
**Estimativa**: 8 dias · **Semanas 2–4**

**Objetivo**: Implementar entidades de domínio, agregados e regras via Script Includes e Business Rules.

**Entregáveis**: Script Includes de domínio; BRs de invariantes (RN-01..06); eventos de domínio; testes ATF das regras críticas.

**Dependências**: Fase 1 concluída (tabelas e escopo).

**Critérios de conclusão**: conflito de agenda bloqueado; dedução sem saldo bloqueada; agendamento sem consentimento bloqueado; eventos disparados.

**Riscos da fase**: overbooking (mitigação: BR + lock transacional); performance de queries em BR.

---

## Fase 3 — Casos de Uso e Scripted REST APIs
**Estimativa**: 9 dias · **Semanas 4–6**

**Objetivo**: Expor casos de uso via Scripted REST APIs com validação, paginação e contratos.

**Entregáveis**: APIs sob `/api/x_espaco/*`; Script Includes de casos de uso; documentação de contratos; coleção de testes.

**Dependências**: Fase 2 (domínio e regras).

**Critérios de conclusão**: 8 endpoints funcionando; paginação/busca; validações com HTTP correto; respostas < 2s.

**Riscos da fase**: performance com volume (mitigação: índices, paginação, cache).

---

## Fase 4 — Conformidade LGPD, Segurança e Auditoria
**Estimativa**: 7 dias · **Semanas 6–8**

**Objetivo**: Implementar LGPD/GDPR, ACLs completas, auditoria e anonimização.

**Entregáveis**: ACLs por role/campo; módulo de anonimização; auditoria ativa; documentação de conformidade.

**Dependências**: Fases 1–3; envolvimento do DPO; definição de políticas LGPD.

**Critérios de conclusão**: acesso restrito por role; anonimização funcional; auditoria de dados sensíveis; consentimento obrigatório.

**Riscos da fase**: tratamento inadequado de dados sensíveis (mitigação: privacy by design, revisão do DPO).

---

## Fase 5 — Fluxos, Notificações e Integrações
**Estimativa**: 6 dias · **Semanas 8–9**

**Objetivo**: Orquestrar fluxos e notificações via Flow Designer e IntegrationHub.

**Entregáveis**: Flows de confirmação/lembrete/cancelamento; integração de notificação; cache de referência; fluxos por evento.

**Dependências**: Fase 2 (eventos), Fase 4 (credenciais seguras); gateway de notificações disponível.

**Critérios de conclusão**: cliente notificado ao criar/cancelar; lembretes enviados; eventos disparam flows; cache invalida ao alterar serviços.

**Riscos da fase**: indisponibilidade de integrações externas (mitigação: retry/fila via IntegrationHub).

---

## Fase 6 — Interface, Dashboard, Testes e Deploy
**Estimativa**: 10 dias · **Semanas 9–12**

**Objetivo**: Entregar telas, dashboard, suíte de testes e pipeline CI/CD.

**Entregáveis**: 6+ telas (Service Portal/UI Builder); dashboard de KPIs; suíte ATF ≥80%; pipeline CI/CD e deploy em produção.

**Dependências**: Fases 1–5.

**Critérios de conclusão**: telas navegáveis; dashboard correto; ATF passando ≥80%; deploy em produção com disponibilidade ≥99%.

**Riscos da fase**: performance > 2s (mitigação: testes de carga); curva de aprendizado (mitigação: capacitação).

---

## Marcos-Chave (Milestones)
1. **M1 (fim Sem. 2)**: Fundação e dados.
2. **M2 (fim Sem. 6)**: APIs operacionais com regras de negócio.
3. **M3 (fim Sem. 8)**: Conformidade LGPD homologada com o DPO.
4. **M4 (fim Sem. 12)**: Go-live em produção.
