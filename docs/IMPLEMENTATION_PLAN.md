# Plano de Implementação — Espaço Laser

Este documento é a **Fonte Única da Verdade** para a execução do desenvolvimento da aplicação scoped `x_espaco` na ServiceNow. Cada fase é autocontida e traz o prompt de execução, dependências e critérios de aceite.

## Ordem e Dependências entre Fases

```
Fase 1 (Fundação) ──► Fase 2 (Domínio) ──► Fase 3 (REST APIs) ──► Fase 4 (LGPD/Segurança)
                                                    │                     │
                                                    └────► Fase 5 (Fluxos/Notificações)
                                                                          │
                                                    Fase 6 (Interface/Testes/Deploy) ◄──┘
```

| Fase | Depende de | Estimativa |
|---|---|---|
| 1 — Fundação e Modelo de Dados | — | 6 dias |
| 2 — Domínio e Regras | Fase 1 | 8 dias |
| 3 — Casos de Uso e REST APIs | Fase 2 | 9 dias |
| 4 — LGPD, Segurança e Auditoria | Fases 1–3 | 7 dias |
| 5 — Fluxos, Notificações e Integrações | Fase 2 (eventos), Fase 4 (credenciais) | 6 dias |
| 6 — Interface, Dashboard, Testes e Deploy | Fases 1–5 | 10 dias |

**Total estimado**: 46 dias úteis (~12 semanas de calendário).

---

## Fase 1 — Fundação da Aplicação Scoped e Modelo de Dados

**Objetivo**: Criar a aplicação scoped `x_espaco` com modelo de dados completo, roles e estrutura base de Clean Architecture/DDD.

**Tarefas**:
1. Criar Custom App scoped `x_espaco` com repositório Git `teste_agent` vinculado.
2. Modelar tabelas base e de domínio (ver `docs/DATABASE.md`).
3. Definir campos, tipos, referências e relacionamentos.
4. Criar índices em `cliente` e `data_hora` do agendamento (+ composto para RN-02).
5. Definir roles: admin, gestor, recepcao, profissional, dpo, leitura, cliente.
6. Estruturar Script Includes base por camada (Domínio, Aplicação, Infraestrutura).

**Prompt de execução**: Implemente a fundação da aplicação ServiceNow scoped 'Espaço Laser' (`x_espaco`) vinculada ao repositório Git `teste_agent`. Crie as tabelas do dicionário de dados com todos os campos, tipos e reference fields; índices em agendamento; roles scoped; e o esqueleto de Script Includes por camada (Domínio com `client_callable=false`, Aplicação e Infraestrutura), comentando a responsabilidade de cada camada.

**Critérios de aceite**:
- Todas as tabelas criadas com campos conforme entidades.
- Relacionamentos (reference) funcionando.
- Roles criadas e atribuíveis.
- App versionada no Git.

---

## Fase 2 — Camada de Domínio e Regras de Negócio

**Objetivo**: Implementar entidades, agregados e regras via Script Includes e Business Rules.

**Tarefas**: Script Includes de domínio; BRs RN-01..04; eventos de domínio; testes ATF.

**Prompt de execução**: Implemente `ClienteEntity` (RN-07 consentimento), `AgendamentoEntity` (RN-02 conflito), `PacoteEntity` (`deduzirSessao` RN-01/RN-05 e marcação de esgotado), `ProfissionalEntity`, `ServicoEntity`, `SessaoEntity`. Crie Business Rules thin que delegam aos Script Includes: rejeitar conflito de horário; impedir agendamento sem consentimento; marcar penalidade em cancelamento < 24h; emitir `pacote.esgotado`. Registre eventos no Event Registry e dispare via `gs.eventQueue`. Cubra as regras com ATF.

**Critérios de aceite**: conflito bloqueado; dedução sem saldo bloqueada; agendamento sem consentimento bloqueado; eventos disparados; ATF passando.

---

## Fase 3 — Casos de Uso e Scripted REST APIs

**Objetivo**: Expor casos de uso via REST com validação, paginação e contratos.

**Tarefas**: Script Includes de casos de uso; 8 endpoints (ver `docs/API.md`); paginação, validação e tratamento de erros.

**Prompt de execução**: Implemente `CadastrarClienteUseCase`, `AgendarSessaoUseCase`, `RegistrarSessaoUseCase`, `ReagendarCancelarUseCase`, `GerenciarPacoteUseCase`. Crie a Scripted REST API namespace `x_espaco` com os recursos descritos em `docs/API.md`, resources finos delegando aos use cases. Implemente paginação (limit default 20, máx 100), validação (HTTP 400), 404, 409 (conflito/saldo), 422 (regra de negócio), 201 (criação). Aplique ACLs por role. Respostas de lista no formato `{data, meta}`.

**Critérios de aceite**: 8 endpoints conforme contrato; paginação/busca; validações com HTTP correto; respostas < 2s; regras da Fase 2 respeitadas.

---

## Fase 4 — Conformidade LGPD, Segurança e Auditoria

**Objetivo**: LGPD/GDPR, ACLs completas, auditoria e anonimização.

**Tarefas**: ACLs por role/campo; registro de finalidade/consentimento; `AnonimizacaoService`; auditoria; `AuditoriaAcessoService`; validação de entrada; Flow de aprovação LGPD.

**Prompt de execução**: Implemente ACLs record e field-level (email/telefone ocultos para leitura); habilite auditoria de campos nas tabelas de dados pessoais; crie `AnonimizacaoService.anonimizarCliente(clienteId)` preservando integridade referencial; registro de finalidade e versão do termo de consentimento; `AuditoriaAcessoService`; validação de entrada nas APIs; Flow de aprovação de exclusão pelo DPO. Credenciais em Connection & Credential Alias.

**Critérios de aceite**: acesso restrito por role; anonimização funcional; auditoria ativa; consentimento obrigatório com finalidade/versão; exclusão requer aprovação do DPO.

---

## Fase 5 — Fluxos, Notificações e Integrações

**Objetivo**: Orquestrar fluxos e notificações via Flow Designer/IntegrationHub.

**Tarefas**: Flows de confirmação/lembrete/cancelamento/pacote esgotado; vinculação a eventos; `ReferenceCacheService` com invalidação; fluxo de reagendamento.

**Prompt de execução**: Crie Flows acionados por `agendamento.criado` (confirmação), `agendamento.cancelado` (aviso + penalidade), `pacote.esgotado` (renovação) e um Flow agendado de lembrete via IntegrationHub Spoke (E-mail/SMS). Vincule todos os eventos de domínio. Implemente `ReferenceCacheService` para `u_servico` com Business Rule de invalidação em insert/update/delete. Credenciais via Connection & Credential Alias.

**Critérios de aceite**: cliente notificado ao criar/cancelar; lembretes enviados; eventos disparam flows; cache invalida ao alterar serviço.

---

## Fase 6 — Interface, Dashboard, Testes e Deploy

**Objetivo**: Telas, dashboard, suíte de testes e pipeline CI/CD.

**Tarefas**: 6+ telas (Service Portal/UI Builder); dashboard de KPIs; suíte ATF ≥80%; pipeline CI/CD; testes de performance; documentação e deploy.

**Prompt de execução**: Crie os widgets/telas: Lista de Clientes, Cadastro de Cliente (consentimento obrigatório), Agenda, Detalhe do Agendamento (concluir sessão), Pacotes do Cliente, Dashboard (KPIs de ocupação/faturamento). Consumam as REST APIs da Fase 3 respeitando ACLs. Implemente suíte ATF ponta a ponta (≥80% das regras críticas). Configure pipeline CI/CD (GitHub Actions + Update Sets) com promoção dev→staging→prod e execução automática de ATF. Execute testes de performance (API <2s).

**Critérios de aceite**: telas navegáveis; dashboard correto; ATF ≥80%; pipeline promove até produção; disponibilidade ≥99%.

---

## Critérios de Aceite Globais do Projeto

1. **Funcional**: todos os 20 RF e 10 RN implementados e testados.
2. **Arquitetura**: solução 100% em Custom App scoped `x_espaco`, com camadas Clean/DDD (RNF-01, RNF-02, RNF-11).
3. **Segurança/LGPD**: ACLs por role/campo, auditoria, consentimento e anonimização em conformidade (RNF-07..09).
4. **APIs**: 8 endpoints REST operacionais com respostas < 2s.
5. **Performance**: telas do portal < 3s (RNF-06).
6. **Qualidade**: suíte ATF verde com cobertura ≥80%.
7. **Deploy**: pipeline CI/CD funcional e go-live em produção com disponibilidade ≥99,5%.
8. **Documentação**: docs atualizados como fonte única da verdade e aprovados pelo DPO.
