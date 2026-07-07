# Changelog — Espaço Laser

Todas as mudanças notáveis deste projeto serão documentadas neste arquivo.

O formato é baseado em [Keep a Changelog](https://keepachangelog.com/pt-BR/1.0.0/) e o projeto adere ao [Versionamento Semântico](https://semver.org/lang/pt-BR/).

## [Unreleased]
### Planejado
- Fase 5: Flows de notificação/lembrete e integrações CRM/Financeiro.
- Fase 6: Telas do Service Portal, dashboard de KPIs, suíte ATF ≥80% e pipeline CI/CD.

## [0.1.0] - 2024-XX-XX — Fundação (Fase 1)
### Added
- Criação do Custom App scoped `x_espaco` vinculado ao repositório Git `teste_agent`.
- Modelo de dados inicial: `u_cliente`, `u_unidade`, `u_profissional`, `u_servico`, `u_pacote`, `u_pacote_cliente`, `u_agendamento`, `u_sessao`, `u_consentimento`, `u_solicitacao_titular`.
- Relacionamentos por reference fields entre entidades.
- Índices em `u_agendamento` (`cliente`, `data_hora`, composto `profissional`+`data_hora`).
- Roles scoped: `x_espaco.admin`, `x_espaco.gestor`, `x_espaco.recepcao`, `x_espaco.profissional`, `x_espaco.dpo`, `x_espaco.leitura`, `x_espaco.cliente`.
- Esqueleto de Script Includes por camada (Domínio, Aplicação, Infraestrutura).

## [0.2.0] - planejado — Domínio e Regras (Fase 2)
### Added
- Script Includes de domínio: `ClienteEntity`, `AgendamentoEntity`, `PacoteEntity`, `ProfissionalEntity`, `ServicoEntity`, `SessaoEntity`.
- Business Rules de invariantes: RN-01 (saldo), RN-02 (conflito), RN-03 (antecedência), RN-04 (débito ao realizar).
- Eventos de domínio: `cliente.cadastrado`, `agendamento.criado`, `agendamento.cancelado`, `sessao.concluida`, `pacote.esgotado`.
- Testes ATF das regras críticas.

## [0.3.0] - 2026-07-07 — REST APIs (Fase 3)
### Added
- Casos de uso implementados: `CadastrarClienteUseCase`, `AgendarSessaoUseCase`, `RegistrarSessaoUseCase`, `GerenciarPacoteUseCase`.
- Scripted REST API `x_espaco` (`/api/x_espaco/*`) com 7 resources: `GET/POST clientes`, `GET servicos`, `GET/POST agendamentos`, `PUT agendamentos/{id}`, `GET pacotes`.
- Paginação (`page`/`limit`≤100) e busca nas listagens; respostas no formato `{data, meta}`.
- Tratamento de erros `{error:{code,message}}` com HTTP 400 (validação), 404 (inexistente) e 409 (conflito de agenda, RN-02).
- Verificação de role por resource via `gs.hasRole` (recepcionista/gestor/admin escrevem, demais papéis leem).
- Teste ATF tipo REST cobrindo 201/400/409 e paginação.

## [0.4.0] - 2026-07-07 — LGPD e Segurança (Fase 4)
### Added
- ACLs record-level em `x_espaco_cliente`/`x_espaco_agendamento`/`x_espaco_pacote` (leitura ampla, escrita restrita por role) e field-level em `cliente.email`/`cliente.telefone` bloqueando a role `x_espaco.leitura`.
- Campos de consentimento em `x_espaco_cliente`: `consentimento_data`, `consentimento_versao`, `consentimento_finalidade` (obrigatórios quando `consentimentoLgpd=true` no cadastro).
- Tabela `x_espaco_log_auditoria` e Script Include `AuditoriaAcessoService.registrar`.
- Script Include `AnonimizacaoService.anonimizarCliente` (hash SHA256, preserva histórico de agendamentos, dispara `lgpd.dados_anonimizados`).
- Field auditing (`audit=true`) em `cliente.email`, `cliente.telefone`, `cliente.consentimento_lgpd` e `agendamento.status`.
- Tabela `x_espaco_solicitacao_titular` (tipo/status) e Flow "Solicitação de Exclusão LGPD": aprovação (role `x_espaco.admin` atuando como DPO — o modelo de roles da Fase 1 não previu uma role `dpo` dedicada) → `AnonimizacaoService` → notificação do titular.
- Evento `lgpd.solicitacao_criada` (Business Rule thin) somado aos eventos já existentes.
- Sanitização de entrada reforçada em `CadastrarClienteUseCase` (regex de email/telefone, `GlideStringUtil.escapeHTML` no nome) e `AgendarSessaoUseCase` (formato de `dataHora`).
- 2 testes ATF: bloqueio de campo sensível para role `leitura` e anonimização com preservação de histórico + log de auditoria.

## [0.5.0] - 2026-07-07 — Notificações e Integrações (Fase 5)
### Added
- 4 Flows acionados por evento/agendamento: "Confirmação de Agendamento" (`agendamento.criado`, respeita consentimento LGPD), "Lembrete de Sessão" (scheduled, ~24h antes), "Aviso de Cancelamento" (`agendamento.cancelado`, inclui penalidade), "Renovação de Pacote" (`pacote.esgotado`, notifica gestor e cliente).
- Subflow reutilizável `EnviarNotificacao` (e-mail via Notification record; SMS via IntegrationHub Spoke com Credential Alias).
- `ReferenceCacheService` (cache de serviços em sessão) + Business Rule `Invalidar Cache de Servicos` (insert/update/delete em `x_espaco_servico`).
- 4 Notification records: `confirmacao`, `lembrete`, `cancelamento`, `renovacao`.
- Credential Alias `espacolaser_notify_gateway` (sem segredo em texto claro — valor real configurado apenas na instância).
- Teste ATF cobrindo a invalidação/repopulação do cache de serviços.

## [1.0.0] - planejado — Go-Live (Fase 6)
### Added
- Telas do Service Portal e dashboard de KPIs.
- Suíte ATF completa (cobertura ≥80%).
- Pipeline CI/CD com GitHub Actions e promoção de Update Sets.
- Deploy em produção.
