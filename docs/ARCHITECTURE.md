# Arquitetura — Espaço Laser (ServiceNow Custom App `x_espaco`)

## 1. Visão Geral

A solução **Espaço Laser** é uma aplicação enterprise construída **exclusivamente na plataforma ServiceNow** como um **Custom App scoped** (`x_espaco`). Ela gerencia o ciclo de atendimento de um centro de depilação corporal a laser: clientes, unidades/franquias, profissionais aplicadores, serviços/áreas corporais, pacotes de tratamento, agendamentos e sessões, com **conformidade LGPD/GDPR** para dados pessoais sensíveis.

A arquitetura aplica **Clean Architecture** e **Domain-Driven Design (DDD)** adaptados ao contexto ServiceNow. Os artefatos nativos da plataforma são mapeados para as camadas clássicas:

| Camada Clean/DDD | Artefato ServiceNow |
|---|---|
| Apresentação / Interface | Service Portal Widgets, UI Builder, Scripted REST API Resources |
| Aplicação (Casos de Uso) | Script Includes de aplicação, Flow Designer, IntegrationHub |
| Domínio (Regras de Negócio) | Script Includes de domínio, Business Rules (invariantes) |
| Infraestrutura / Persistência | Tabelas ServiceNow (scoped), GlideRecord, Audit Tables, IntegrationHub Spokes |

### Princípios norteadores
- **Scoped app first**: todo código, tabelas e artefatos vivem no escopo `x_espaco`, garantindo isolamento de namespace, versionamento e portabilidade entre instâncias.
- **Thin Business Rules / Thin REST Resources**: a lógica reside nos Script Includes de domínio e aplicação; BRs e Resources apenas delegam.
- **Privacy by Design**: LGPD embutida desde a modelagem (consentimento, anonimização, auditoria, ACLs de campo).
- **Event-Driven**: eventos de domínio (`gs.eventQueue`) desacoplam regras de negócio de notificações e integrações.

## 2. Diagrama de Camadas (ASCII)

```
┌──────────────────────────────────────────────────────────────────────┐
│                    CAMADA DE APRESENTAÇÃO / INTERFACE                    │
│  Service Portal Widgets            Scripted REST API (/api/x_espaco/*)  │
│  ┌────────────────────────┐        ┌──────────────────────────────┐    │
│  │ Agendamento            │        │ ClientesResource             │    │
│  │ Meus Agendamentos      │        │ AgendamentosResource         │    │
│  │ Meus Pacotes           │◄──────►│ ServicosResource             │    │
│  │ Histórico / Check-in   │  HTTPS │ PacotesResource / SessaoRes. │    │
│  │ Dashboard / LGPD Admin │        │ LGPDResource                 │    │
│  └────────────────────────┘        └──────────────────────────────┘    │
│  Segurança: ACLs (record + field level), OAuth 2.0, SSO/SAML           │
└───────────────────────────────┬──────────────────────────────────────┘
                                 │ delega (thin)
┌───────────────────────────────▼──────────────────────────────────────┐
│                    CAMADA DE APLICAÇÃO (CASOS DE USO)                    │
│  Script Includes de aplicação:                                          │
│   • CadastrarClienteUseCase     • AgendarSessaoUseCase                  │
│   • RegistrarSessaoUseCase      • ReagendarCancelarUseCase             │
│   • GerenciarPacoteUseCase      • ProcessarSolicitacaoLGPDUseCase      │
│  Orquestração: Flow Designer / IntegrationHub                          │
└───────────────────────────────┬──────────────────────────────────────┘
                                 │ usa agregados / entidades
┌───────────────────────────────▼──────────────────────────────────────┐
│                    CAMADA DE DOMÍNIO (REGRAS DE NEGÓCIO)                 │
│  Entidades/Agregados (Script Includes, client_callable=false):          │
│   • ClienteEntity      • AgendamentoEntity   • PacoteEntity            │
│   • ProfissionalEntity • ServicoEntity       • SessaoEntity            │
│  Invariantes (Business Rules thin → Script Includes):                   │
│   RN-01 consentimento │ RN-02 conflito agenda │ RN-03 saldo pacote     │
│   RN-04 antecedência  │ RN-05 pacote expirado                          │
│  Eventos de domínio: gs.eventQueue(...)                                │
└───────────────────────────────┬──────────────────────────────────────┘
                                 │ persiste / consulta
┌───────────────────────────────▼──────────────────────────────────────┐
│                 CAMADA DE INFRAESTRUTURA / PERSISTÊNCIA                  │
│  Tabelas scoped: u_cliente, u_unidade, u_profissional, u_servico,       │
│   u_pacote, u_pacote_cliente, u_agendamento, u_sessao,                  │
│   u_consentimento, u_solicitacao_titular                                │
│  Acesso: GlideRecord / GlideAggregate  │  Repositórios (Script Includes) │
│  Auditoria: sys_audit (field auditing) │ Cache: ReferenceCacheService   │
│  Integrações: IntegrationHub Spokes (E-mail/SMS/WhatsApp), MID Server   │
└──────────────────────────────────────────────────────────────────────┘
         │                          │                        │
         ▼                          ▼                        ▼
   CRM/Marketing            Financeiro/Faturamento     Gateway Notificações
   (REST/IntegrationHub)    (REST/IntegrationHub)      (REST/IntegrationHub)
```

## 3. Decisões Arquiteturais (ADRs)

### ADR-001 — Construir como Custom App scoped (`x_espaco`)
- **Contexto**: Necessidade de isolamento, segurança e portabilidade entre instâncias ServiceNow.
- **Decisão**: Todo o desenvolvimento em aplicação scoped `x_espaco` vinculada a repositório Git.
- **Alternativas rejeitadas**: Aplicação global; customização direta em tabelas OOB.
- **Consequências**: Namespace isolado; upgrades da plataforma preservados; necessidade de cross-scope access policies para integrações.

### ADR-002 — Clean Architecture / DDD via Script Includes por camada
- **Contexto**: Regras de negócio complexas (agenda, pacotes, LGPD) que precisam ser testáveis e manuteníveis.
- **Decisão**: Separar Domínio, Aplicação e Infraestrutura em Script Includes distintos; BRs e REST Resources são finos.
- **Alternativas rejeitadas**: Lógica concentrada em Business Rules; código procedural nos Resources REST.
- **Consequências**: Maior organização e testabilidade (ATF); leve overhead de camadas.

### ADR-003 — Privacy by Design para LGPD/GDPR
- **Contexto**: Dados de saúde/estética são sensíveis (risco alto identificado).
- **Decisão**: Consentimento, anonimização, criptografia de campos e auditoria implementados desde a fundação.
- **Alternativas rejeitadas**: Adicionar controles LGPD ao final do projeto.
- **Consequências**: Conformidade legal desde o MVP; complexidade adicional nas ACLs de campo.

### ADR-004 — Business Rules para invariantes críticas
- **Contexto**: Consistência deve ser garantida mesmo em acessos diretos à tabela (fora da API).
- **Decisão**: RN-01 (consentimento), RN-02 (conflito de agenda), RN-03 (saldo), RN-04 (antecedência) implementadas em BRs que delegam a Script Includes.
- **Alternativas rejeitadas**: Validação apenas na camada de aplicação/API.
- **Consequências**: Integridade garantida a nível de dados; cuidado com performance de queries em BRs.

### ADR-005 — Arquitetura orientada a eventos para notificações/integrações
- **Contexto**: Notificações e integrações externas não devem acoplar o fluxo transacional.
- **Decisão**: Eventos de domínio via `gs.eventQueue`; Flow Designer/IntegrationHub reagem aos eventos.
- **Alternativas rejeitadas**: Chamadas síncronas às integrações dentro das BRs.
- **Consequências**: Desacoplamento, retry/fila; latência assíncrona nas notificações.

## 4. Padrões Escolhidos

- **Clean Architecture**: dependências apontam para o domínio; infraestrutura é detalhe.
- **DDD**: Entidades e Agregados (Cliente, Agendamento, Pacote), Objetos de Valor (período de vigência, slot de horário), Repositórios (Script Includes de infraestrutura).
- **REST API**: contratos JSON `{data, meta}` para listas, códigos HTTP semânticos.
- **Enterprise Patterns ServiceNow**: Flow Designer/IntegrationHub, Business Rules & Script Includes, Scripted REST API, Custom App scoped.

## 5. Fluxo de Dados — Exemplo: Agendar Sessão

```
Cliente (Widget Agendamento)
   │ POST /api/x_espaco/agendamento {clienteId, servicoId, profissionalId, dataHora}
   ▼
AgendamentosResource (Interface)  ── valida payload, autoriza (ACL role)
   │ delega
   ▼
AgendarSessaoUseCase (Aplicação)
   │ 1. ClienteEntity.temConsentimentoAtivo()   → RN-01
   │ 2. PacoteEntity.temSaldo()                 → RN-01/RN-05
   │ 3. AgendamentoEntity.verificarConflito()   → RN-02
   ▼
Business Rule (before insert em u_agendamento)  ── reforça invariantes
   ▼
GlideRecord insert em u_agendamento (Infraestrutura)
   ▼
gs.eventQueue('agendamento.criado', gr)  → Flow Designer envia confirmação
   ▼
Resposta 201 {data: agendamento, meta}
```

## 6. Tecnologias por Camada

| Camada | Tecnologias ServiceNow |
|---|---|
| Apresentação | Service Portal Widgets, UI Builder, Scripted REST API, ACLs, OAuth 2.0, SSO/SAML |
| Aplicação | Script Includes (scoped), Flow Designer, IntegrationHub Spokes |
| Domínio | Script Includes (client_callable=false), Business Rules, Event Registry |
| Infraestrutura | Tabelas scoped, GlideRecord, GlideAggregate, sys_audit, Connection & Credential Alias, MID Server |

## 7. Responsabilidades por Componente

- **REST Resources**: parsing/validação de request, autorização, serialização. Sem regra de negócio.
- **Use Cases**: orquestração do fluxo, coordenação entre agregados, disparo de eventos.
- **Entities/Aggregates**: regras invariantes, cálculo de saldo, validação de conflito e consentimento.
- **Repositórios (Infra)**: acesso GlideRecord, mapeamento tabela↔objeto.
- **Business Rules**: reforço de invariantes independentemente da origem do acesso.
- **Flows**: notificações, lembretes, aprovação LGPD, integrações externas.

## 8. Boas Práticas Adotadas

- Nomenclatura com prefixo de escopo (`x_espaco` / tabelas `u_`).
- Script Includes de domínio com `client_callable=false`.
- Evitar queries dentro de loops; usar `GlideAggregate` para dashboards.
- Paginação e carregamento assíncrono em widgets (RNF-06 < 3s).
- Segredos em Connection & Credential Alias — nunca em texto claro.
- HTTPS/TLS obrigatório em todas as integrações.
- Testes automatizados via ATF cobrindo regras críticas (≥80%).

## 9. Estratégia de Evolução

1. **Curto prazo**: MVP com clientes, agendamentos, pacotes e LGPD (Fases 1–4).
2. **Médio prazo**: Notificações omnicanal, dashboards de gestão e integrações CRM/Financeiro (Fases 5–6).
3. **Longo prazo**: Multi-tenant por franquia mais robusto, Performance Analytics avançado, app mobile (Now Mobile), automação de campanhas de retenção.
4. **Sustentação**: manter compatibilidade em upgrades da plataforma pelo isolamento scoped; expandir cobertura ATF; revisões periódicas de conformidade LGPD com o DPO.
