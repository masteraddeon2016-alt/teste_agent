# Requisitos — Espaço Laser

Este documento consolida os requisitos funcionais (RF), não-funcionais (RNF) e regras de negócio (RN) da plataforma **Espaço Laser** na ServiceNow (Custom App `x_espaco`).

## Legenda de Prioridade
- **P1 (Alta)**: essencial ao MVP / conformidade legal.
- **P2 (Média)**: importante, entrega nas fases intermediárias.
- **P3 (Baixa)**: desejável / evolução.

---

## Módulo 1 — Gestão de Clientes e LGPD

| ID | Requisito | Prioridade | Critérios de Aceite |
|---|---|---|---|
| RF-01 | Cadastro e manutenção de clientes com dados pessoais e de contato no Custom App | P1 | Cliente criado com nome, CPF, e-mail, telefone, data de nascimento; edição e inativação disponíveis |
| RF-13 | Registrar consentimento LGPD do cliente com data e finalidade | P1 | Aceite explícito obrigatório; grava data/hora, finalidade e versão do termo |
| RF-14 | Permitir solicitação de acesso, correção e exclusão de dados pelo titular | P1 | Solicitação criada em `u_solicitacao_titular`; fluxo de aprovação do DPO acionado |
| RF-16 | Exibir histórico de sessões e saldo de pacotes ao cliente | P2 | Widget exibe pacotes com saldo/vigência e lista de sessões realizadas |

**Regras de negócio associadas**: RN-07 (tratamento só com consentimento válido), RN-08 (exclusão requer aprovação do DPO), RN-09 (cliente vê apenas seus dados).

---

## Módulo 2 — Cadastros Base (Unidades, Profissionais, Serviços, Pacotes)

| ID | Requisito | Prioridade | Critérios de Aceite |
|---|---|---|---|
| RF-02 | Cadastro de unidades/franquias com horários de funcionamento | P1 | Unidade com nome, endereço, horário, status ativo |
| RF-03 | Cadastro de profissionais aplicadores e vinculação às unidades | P1 | Profissional com registro, vínculo `sys_user` e unidade |
| RF-04 | Cadastro de serviços/áreas corporais de tratamento | P1 | Serviço com nome, duração e descrição |
| RF-05 | Criação de pacotes de tratamento com quantidade de sessões e vigência | P1 | Pacote com qtd_sessoes, validade_meses, valor; N:N com serviços |

---

## Módulo 3 — Gestão de Agendamentos

| ID | Requisito | Prioridade | Critérios de Aceite |
|---|---|---|---|
| RF-06 | Agendamento de sessões via Widget no Service Portal | P1 | Cliente/recepção seleciona unidade, serviço, profissional, data/hora e confirma |
| RF-07 | Validar saldo de sessões do pacote antes de confirmar (Script Include) | P1 | Agendamento bloqueado sem saldo; mensagem clara ao usuário |
| RF-08 | Detectar e impedir conflitos de horário de profissionais (Business Rule) | P1 | Dois agendamentos ativos do mesmo profissional no mesmo horário são rejeitados |
| RF-09 | Reagendamento e cancelamento respeitando política de antecedência | P1 | Cancelamento/reagendamento <24h marca penalidade conforme política |
| RF-15 | Notificações de confirmação e lembrete de sessão via Flow Designer | P2 | Confirmação ao criar; lembrete X horas antes |
| RF-19 | Registrar no-show quando o cliente não comparecer | P2 | Status `no-show` disponível; evento `sessao.no_show` disparado |
| RF-20 | Controlar status do agendamento | P1 | Ciclo: agendado → confirmado → realizado → cancelado / no-show |

**Regras de negócio associadas**: RN-01 (saldo), RN-02 (conflito), RN-03 (antecedência 24h), RN-05 (pacote expirado), RN-06 (penalidade no-show).

---

## Módulo 4 — Execução de Sessões e Pacotes

| ID | Requisito | Prioridade | Critérios de Aceite |
|---|---|---|---|
| RF-10 | Check-in de clientes na unidade | P1 | Recepção realiza check-in a partir da agenda do dia |
| RF-11 | Registrar execução da sessão com áreas tratadas e parâmetros | P1 | Profissional grava áreas e parâmetros; data de realização registrada |
| RF-12 | Debitar automaticamente sessão do saldo do pacote ao concluir | P1 | Ao status `Realizada`, saldo decrementa; pacote esgotado ao atingir zero |

**Regras de negócio associadas**: RN-04 (débito só ao realizar).

---

## Módulo 5 — Relatórios e Integrações

| ID | Requisito | Prioridade | Critérios de Aceite |
|---|---|---|---|
| RF-17 | Dashboards operacionais para gestores de franquia | P2 | KPIs de ocupação, sessões e ranking de profissionais |
| RF-18 | Expor Scripted REST API para integração externa (CRM/financeiro) | P2 | Endpoints `/api/x_espaco/*` autenticados via OAuth 2.0 |

---

## Requisitos Não-Funcionais

| ID | Requisito | Prioridade | Critérios de Aceite |
|---|---|---|---|
| RNF-01 | Solução desenvolvida como Custom App scoped | P1 | Todos os artefatos no escopo `x_espaco` |
| RNF-02 | Lógica reutilizável em Script Includes seguindo DDD | P1 | Domínio/Aplicação/Infra separados |
| RNF-03 | Interfaces via Widgets do Service Portal | P1 | Telas do portal implementadas |
| RNF-04 | Integrações externas via Scripted REST API e IntegrationHub | P1 | Integrações usam Spokes/Scripted REST |
| RNF-05 | Suporte a múltiplas unidades/franquias (multi-tenant lógico) | P1 | Isolamento de dados por unidade via query BR |
| RNF-06 | Tempo de resposta das telas do portal < 3s | P2 | Medição em homologação |
| RNF-07 | Conformidade LGPD/GDPR para dados sensíveis | P1 | Consentimento, anonimização, auditoria ativos |
| RNF-08 | Controle de acesso por roles (ACLs) | P1 | ACLs por role e campo |
| RNF-09 | Registro de auditoria em operações sobre dados pessoais | P1 | `sys_audit` habilitado nas tabelas sensíveis |
| RNF-10 | Disponibilidade ≥ 99,5% (SLA da instância) | P2 | Monitoramento contínuo |
| RNF-11 | Código em camadas conforme Clean Architecture | P1 | Estrutura de Script Includes por camada |

---

## Regras de Negócio Consolidadas

| ID | Regra |
|---|---|
| RN-01 | Agendamento só confirma se houver saldo de sessões no pacote |
| RN-02 | Proibido dois agendamentos do mesmo profissional no mesmo horário |
| RN-03 | Cancelamento/reagendamento respeita antecedência mínima de 24h |
| RN-04 | Sessão só é debitada quando status = `Realizada` |
| RN-05 | Pacote expirado não permite novos agendamentos |
| RN-06 | No-show pode gerar penalidade conforme política da unidade |
| RN-07 | Dados pessoais só tratados mediante consentimento válido |
| RN-08 | Exclusão LGPD requer aprovação do DPO antes da anonimização |
| RN-09 | Cliente visualiza apenas seus próprios dados e agendamentos |
| RN-10 | Profissional acessa apenas a agenda das unidades vinculadas |

## Rastreabilidade Requisito → Fase

| Fase | Requisitos cobertos |
|---|---|
| 1 — Fundação e Modelo de Dados | RF-01..05, RNF-01, RNF-02, RNF-11 |
| 2 — Domínio e Regras | RF-07, RF-08, RF-12, RN-01..06 |
| 3 — Casos de Uso e REST APIs | RF-06, RF-09, RF-16, RF-18, RNF-04 |
| 4 — LGPD, Segurança e Auditoria | RF-13, RF-14, RNF-07..09, RN-07..09 |
| 5 — Fluxos e Notificações | RF-15, RF-19, RNF-05 |
| 6 — Interface, Dashboard, Testes, Deploy | RF-10, RF-11, RF-17, RF-20, RNF-06, RNF-10 |
