# CLAUDE.md — Instruções para o Claude Code

## Projeto: Espaço Laser — Plataforma de Gestão de Depilação a Laser (ServiceNow)

Este documento é a **Fonte Única da Verdade** para o desenvolvimento da aplicação scoped `x_espaco` na plataforma ServiceNow. Leia integralmente antes de qualquer implementação.

---

## 1. Visão Geral e Arquitetura

A solução é uma **Custom Application scoped ServiceNow** (namespace `x_espaco`) para gestão de clientes, agendamentos, pacotes de sessões, serviços e profissionais de um centro de depilação a laser (Espaço Laser).

### Padrões arquiteturais obrigatórios
- **Clean Architecture + DDD** adaptados ao contexto ServiceNow.
- **Privacy by Design** (LGPD/GDPR) desde o início.
- **Comunicação REST** via Scripted REST API.
- **Orquestração** via Flow Designer / IntegrationHub.

### Mapeamento de camadas (Clean Architecture no ServiceNow)

```
+---------------------------------------------------------------+
|  APRESENTAÇÃO / API (Interface)                               |
|  Service Portal Widgets, UI Builder, Scripted REST API, ACLs |
+---------------------------------------------------------------+
|  APLICAÇÃO (Casos de Uso)                                     |
|  Script Includes de UseCase, Flow Designer, IntegrationHub   |
+---------------------------------------------------------------+
|  DOMÍNIO (Regras de Negócio)                                 |
|  Script Includes de Entidade/Agregado, Business Rules (thin) |
+---------------------------------------------------------------+
|  INFRAESTRUTURA / PERSISTÊNCIA                               |
|  ServiceNow Tables, GlideRecord Repositories, Audit, Spokes  |
+---------------------------------------------------------------+
```

### Regra de dependência
As dependências apontam **sempre para dentro**: Apresentação → Aplicação → Domínio. A Infraestrutura implementa interfaces definidas pelo Domínio/Aplicação. **Nunca** coloque regra de negócio em Business Rule diretamente — a Business Rule deve ser *thin* e delegar para Script Includes de domínio.

---

## 2. Tecnologias Obrigatórias (EXCLUSIVAMENTE estas)

| Camada | Tecnologia ServiceNow |
|--------|----------------------|
| App | Custom Application scoped (`x_espaco`) |
| Persistência | ServiceNow Tables + GlideRecord |
| Domínio | Script Includes (server, `client_callable=false`) |
| Invariantes | Business Rules (before/after) |
| API | Scripted REST API (`/api/x_espaco/*`) |
| Orquestração | Flow Designer + IntegrationHub |
| UI | Service Portal Widgets / UI Builder |
| Testes | Automated Test Framework (ATF) |
| Auditoria | sys_audit / field auditing |
| Segurança | ACLs (record + field level), OAuth 2.0 |
| Versionamento | Source Control (Git) + Update Sets |

> **Proibido** utilizar qualquer tecnologia fora deste conjunto (ex.: Node.js standalone, bancos externos diretos, frameworks front-end fora do Service Portal/UI Builder).

---

## 3. Modelo de Dados (Tabelas `x_espaco`)

| Tabela | Campos principais |
|--------|-------------------|
| `x_espaco_cliente` | nome (string), email (string), telefone (string), consentimento_lgpd (boolean), consentimento_data (glide_date_time), consentimento_versao (string), data_cadastro (glide_date_time), ativo (boolean) |
| `x_espaco_servico` | nome (string), area_corporal (string), duracao_minutos (integer), preco (currency) |
| `x_espaco_profissional` | nome (string), especialidade (string), user (reference sys_user), ativo (boolean) |
| `x_espaco_pacote` | cliente (ref x_espaco_cliente), total_sessoes (integer), sessoes_utilizadas (integer), data_inicio (glide_date_time), data_expiracao (glide_date_time), status (choice: ativo, esgotado, expirado) |
| `x_espaco_agendamento` | cliente (ref), servico (ref), profissional (ref), unidade (ref), data_hora (glide_date_time), status (choice: novo, confirmado, concluido, cancelado, reagendado), penalidade (boolean) |

> Índices obrigatórios: `x_espaco_agendamento.cliente`, `x_espaco_agendamento.data_hora`, `x_espaco_agendamento.profissional`.

---

## 4. Convenções de Código Obrigatórias

### Nomenclatura
- **Prefixo de escopo**: tudo com `x_espaco`.
- **Tabelas**: `x_espaco_<entidade>` (snake_case).
- **Script Includes de Domínio**: `<Entidade>Entity` (ex.: `ClienteEntity`, `AgendamentoEntity`).
- **Script Includes de Caso de Uso**: `<Acao><Entidade>UseCase` (ex.: `AgendarSessaoUseCase`).
- **Script Includes de Infra/Repositório**: `<Entidade>Repository`.
- **Script Includes de Serviço LGPD**: `AnonimizacaoService`, `AuditoriaAcessoService`.
- **Scripted REST API**: namespace `x_espaco`, resources em plural (`clientes`, `agendamentos`).

### Padrões de código
- Script Includes de domínio: `client callable = false`, `Accessible from = This application scope only`.
- Comentar a responsabilidade da camada no topo de cada Script Include.
- **Nunca** executar `GlideRecord` dentro de loops — usar queries agregadas (`GlideAggregate`) e batch.
- Sempre usar `gs.eventQueue()` para eventos de domínio.
- Respostas REST de lista no formato `{ "data": [...], "meta": { "page", "limit", "total" } }`.
- Códigos HTTP: `201` criação, `400` validação, `404` inexistente, `409` conflito de agenda, `403` sem permissão.

### Eventos de domínio (Event Registry)
`cliente.cadastrado`, `agendamento.criado`, `agendamento.confirmado`, `agendamento.cancelado`, `agendamento.reagendado`, `sessao.checkin_realizado`, `sessao.concluida`, `sessao.no_show`, `pacote.saldo_atualizado`, `pacote.esgotado`, `lgpd.solicitacao_criada`, `lgpd.dados_anonimizados`.

---

## 5. Estrutura de Diretórios (Source Control export)

```
x_espaco/
├── src/
│   ├── sys_scope/                     # Definição da app scoped
│   ├── table/                         # Definições das 5 tabelas
│   ├── sys_dictionary/                # Campos e tipos
│   ├── sys_db_object_index/           # Índices
│   ├── script_include/
│   │   ├── domain/                     # ClienteEntity, AgendamentoEntity, PacoteEntity...
│   │   ├── application/                # *UseCase
│   │   └── infrastructure/             # *Repository, AnonimizacaoService, ReferenceCacheService
│   ├── business_rule/                  # Invariantes (thin)
│   ├── sys_ws_definition/              # Scripted REST APIs
│   ├── sys_ws_operation/               # Resources REST
│   ├── flow/                           # Flow Designer flows
│   ├── sp_widget/                      # Widgets Service Portal
│   ├── sys_security_acl/               # ACLs
│   ├── sys_user_role/                  # Roles
│   ├── sys_event_register/             # Eventos de domínio
│   ├── sys_notification/               # Notification records
│   └── sys_atf_test/                   # Testes ATF
├── docs/
│   ├── ARCHITECTURE.md
│   └── API_CONTRACTS.md
├── workflow/
├── CLAUDE.md
├── AGENTS.md
├── README.md
├── appsettings.example.json
├── .env.example
└── .gitignore
```

---

## 6. Como Executar o Projeto

1. Instância ServiceNow com Service Portal + IntegrationHub + Flow Designer + Scripted REST API + Custom App (scoped) licenciados.
2. Importe a aplicação via **Source Control** (Git repo `teste_agent`) em *Studio > Import Application from Source Control*.
3. Ative o escopo `x_espaco` em *Application Scope Selector*.
4. Atribua as roles de teste (`x_espaco.admin`, etc.) ao seu usuário.
5. Acesse os widgets em `/sp?id=espacolaser_agendamento` (e demais rotas).
6. Teste as APIs em `/api/x_espaco/*` via REST API Explorer.

---

## 7. Fases do Projeto — Ordem OBRIGATÓRIA

| Fase | Nome | Não avançar sem |
|------|------|-----------------|
| 1 | Fundação Scoped e Modelo de Dados | 5 tabelas + relacionamentos + roles + índices + commit Git |
| 2 | Domínio e Regras de Negócio | RN-01 a RN-04 impostas + eventos + ATF passando |
| 3 | Casos de Uso e Scripted REST APIs | 7 endpoints + paginação + validação + códigos HTTP |
| 4 | LGPD, Segurança e Auditoria | ACLs por role/campo + anonimização + auditoria + consentimento |
| 5 | Fluxos, Notificações e Integrações | Flows por evento + notificações + cache com invalidação |
| 6 | Interface, Dashboard, Testes e Deploy | 6 telas + dashboard + ATF ≥80% + pipeline CI/CD em prod |

> **REGRA CRÍTICA**: NÃO inicie uma fase enquanto todos os critérios de aceite da fase anterior não estiverem cumpridos e commitados.

---

## 8. Checklist Antes de Finalizar Cada Fase

- [ ] Todos os critérios de aceite da fase atendidos.
- [ ] Código dentro do escopo `x_espaco` (nada em global).
- [ ] Nomenclatura seguindo Seção 4.
- [ ] Regras de negócio no domínio (Business Rules thin).
- [ ] Testes ATF criados/atualizados e passando.
- [ ] Dados sensíveis (email, telefone, cpf) com ACL/field-level quando aplicável.
- [ ] Sem `GlideRecord` em loops.
- [ ] Commit no Git com mensagem padronizada (Seção 9).
- [ ] Documentação (`docs/`) atualizada.

---

## 9. Padrões de Commit, Branch e PR

### Branches
- `main` — produção (protegida).
- `develop` — integração.
- `feature/fase-<n>-<descricao>` — ex.: `feature/fase-2-regras-negocio`.
- `fix/<descricao>` — correções.

### Commits (Conventional Commits)
```
feat(fase-2): adiciona validacao de conflito de agenda (RN-02)
fix(api): corrige http 409 no POST /agendamentos
test(atf): cobre deducao de pacote sem saldo
docs(arch): atualiza diagrama de camadas
chore(scoped): adiciona indice em data_hora
```

### Pull Requests
- Base: `develop`. Título com prefixo da fase.
- Descrição com: fase, requisitos atendidos (RF/RN), evidências ATF.
- Mínimo 1 revisão + CI verde (ATF + validação de Update Set).

---

## 10. Como Rodar Testes

- **ATF**: *Automated Test Framework > Tests* → executar suíte `x_espaco - Regras Críticas`.
- **REST**: Postman/collection em `docs/API_CONTRACTS.md` ou REST API Explorer.
- **Performance**: validar APIs de listagem < 2s com 1000+ registros.
- Cobertura mínima de regras críticas: **80%**.

---

## 11. Proibições Explícitas

1. ❌ **NÃO** desenvolver em escopo global — tudo em `x_espaco`.
2. ❌ **NÃO** colocar lógica de negócio dentro de Business Rules (devem ser thin).
3. ❌ **NÃO** expor CPF/dados sensíveis sem criptografia/ACL field-level.
4. ❌ **NÃO** armazenar tokens/credenciais em texto claro — usar Connection & Credential Alias.
5. ❌ **NÃO** remover ou alterar código/tabelas de fases anteriores sem justificativa documentada.
6. ❌ **NÃO** avançar de fase sem cumprir critérios de aceite.
7. ❌ **NÃO** usar `GlideRecord` dentro de loops.
8. ❌ **NÃO** modificar arquivos fora do escopo do projeto (`x_espaco/`).
9. ❌ **NÃO** criar tabelas OOB customizadas — usar apenas as `x_espaco_*` definidas.
10. ❌ **NÃO** permitir agendamento/tratamento de dados sem consentimento LGPD registrado.
