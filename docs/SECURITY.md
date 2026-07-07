# Segurança e Conformidade — Espaço Laser

Este documento descreve a estratégia de segurança, controle de acesso e conformidade LGPD/GDPR da aplicação scoped `x_espaco` na ServiceNow.

## 1. Autenticação

| Contexto | Mecanismo |
|---|---|
| Usuários internos (recepção, profissional, gestor, DPO, admin) | SSO / SAML integrado ao IdP corporativo |
| Clientes finais (portal self-service) | Autenticação ServiceNow (login do portal) |
| Integrações externas (CRM, Financeiro, Notificações) | OAuth 2.0 (client credentials / authorization code) |

- Tokens e credenciais armazenados **exclusivamente** em **Connection & Credential Alias** — nunca em texto claro no código.
- HTTPS/TLS obrigatório em todos os endpoints e integrações.

## 2. Autorização (RBAC via Roles ServiceNow)

| Role | Permissões |
|---|---|
| `x_espaco.cliente` | Acesso self-service ao portal; vê apenas seus dados (RN-09) |
| `x_espaco.recepcao` | Check-in, criação/ajuste de agendamentos, cadastro de clientes |
| `x_espaco.profissional` | Agenda das unidades vinculadas (RN-10), registro de sessão |
| `x_espaco.gestor` | Dashboards, configurações da unidade, gestão de pacotes |
| `x_espaco.dpo` | Gestão de solicitações LGPD, auditoria de dados sensíveis |
| `x_espaco.admin` | Administração completa do Custom App |
| `x_espaco.leitura` | Somente leitura (sem acesso a campos sensíveis) |

### ACLs (Access Control Lists)
- **Record-level**: leitura/escrita por role em `u_cliente`, `u_agendamento`, `u_pacote_cliente`, `u_sessao`.
- **Field-level**: `email`, `telefone`, `cpf`, `data_nascimento` ocultos para `x_espaco.leitura`.
- **Query Business Rules**: isolamento de dados por unidade (multi-tenant lógico — RNF-05) e restrição do cliente aos próprios registros (RN-09) e do profissional às unidades vinculadas (RN-10).

## 3. Conformidade LGPD / GDPR (Privacy by Design)

### 3.1 Base legal e finalidade
- Todo tratamento de dados pessoais exige **consentimento válido** registrado em `u_consentimento` com **finalidade** e **versão do termo** (RN-07).
- Minimização: coleta apenas de dados necessários ao atendimento.

### 3.2 Direitos do titular
- Solicitações de **acesso, correção e exclusão** registradas em `u_solicitacao_titular` (RF-14).
- Fluxo no Flow Designer cria tarefa para o DPO; exclusão só ocorre após **aprovação do DPO** (RN-08).
- **Anonimização** via `AnonimizacaoService.anonimizarCliente(clienteId)`: substitui dados pessoais por hashes/valores anonimizados, preservando integridade referencial dos agendamentos/sessões históricos.

### 3.3 Controles técnicos
| Controle | Implementação |
|---|---|
| Criptografia de campos sensíveis | Field Encryption em `cpf`, `data_nascimento` |
| Auditoria de dados pessoais | `sys_audit` (field auditing) em `u_cliente`, `u_sessao` |
| Log de acesso a dados sensíveis | `AuditoriaAcessoService` registra leituras/escritas |
| Retenção e descarte | Política de retenção por finalidade; anonimização ao fim |

## 4. Criptografia e Proteção de Dados
- **Em trânsito**: TLS 1.2+ em todas as chamadas REST e integrações.
- **Em repouso**: Field Encryption para CPF e data de nascimento; demais dados protegidos pela criptografia da instância.
- **Sanitização**: validação e sanitização de todas as entradas nas Scripted REST APIs (proteção contra injeção e dados malformados).

## 5. Auditoria e Logs de Segurança

| Evento | Registro |
|---|---|
| Alteração em dados pessoais | `sys_audit` com autor, campo, valor antigo/novo, timestamp |
| Solicitações LGPD e ações do DPO | Log dedicado em `u_solicitacao_titular` + histórico |
| Alteração de status de agendamentos | Auditoria de campo `status` em `u_agendamento` |
| Chamadas às Scripted REST APIs | Transaction/system logs por transação |
| Anonimização de titular | Log do `AnonimizacaoService` (quem, quando, protocolo) |

## 6. Segurança das Integrações
- OAuth 2.0 para autenticação de sistemas externos.
- Validação de escopo/role por endpoint.
- MID Server (agentes `localmachine`, `localmachine2`) para integrações on-premises quando necessário.
- Retry, fila e tratamento de falhas via IntegrationHub/Flow Designer.

## 7. Boas Práticas e Gestão de Riscos de Segurança
- Rotação periódica de credenciais; token Git armazenado em cofre seguro (mitigação de risco de exposição).
- Revisões de ACL a cada nova tabela/campo.
- Testes de segurança (ATF + revisão de ACL) na Fase 4 e no pipeline CI/CD.
- Envolvimento contínuo do DPO na modelagem e homologação.

## 8. Checklist de Conformidade (Fase 4)
- [ ] Usuário `x_espaco.leitura` não visualiza `email`/`telefone`.
- [ ] Anonimização remove dados pessoais mantendo histórico referencial.
- [ ] Alterações em dados sensíveis aparecem na trilha de auditoria.
- [ ] Consentimento obrigatório, com finalidade e versão registradas.
- [ ] Solicitação de exclusão exige aprovação do DPO.
- [ ] Credenciais fora do código-fonte.
