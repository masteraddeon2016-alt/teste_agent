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

## [0.3.0] - planejado — REST APIs (Fase 3)
### Added
- Scripted REST APIs sob `/api/x_espaco/*` (8 endpoints).
- Script Includes de casos de uso.
- Paginação, validação de entrada e tratamento de erros HTTP.

## [0.4.0] - planejado — LGPD e Segurança (Fase 4)
### Added
- ACLs record e field level por role.
- `AnonimizacaoService`, `AuditoriaAcessoService`.
- Auditoria de campos em tabelas de dados pessoais.
- Flow de aprovação de solicitações do titular.

## [0.5.0] - planejado — Notificações e Integrações (Fase 5)
### Added
- Flows de confirmação, lembrete e cancelamento.
- `ReferenceCacheService` com invalidação por Business Rule.
- Integrações CRM, Financeiro e Gateway de Notificações.

## [1.0.0] - planejado — Go-Live (Fase 6)
### Added
- Telas do Service Portal e dashboard de KPIs.
- Suíte ATF completa (cobertura ≥80%).
- Pipeline CI/CD com GitHub Actions e promoção de Update Sets.
- Deploy em produção.
