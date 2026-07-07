# Espaço Laser — Plataforma de Gestão de Depilação a Laser

Aplicação **enterprise scoped ServiceNow** (`x_espaco`) para gestão do ciclo de atendimento de um centro de depilação corporal a laser: clientes, agendamentos, pacotes de sessões, serviços, profissionais e conformidade LGPD/GDPR.

---

## 📋 Descrição

A plataforma centraliza e automatiza:
- Cadastro de clientes com **consentimento LGPD** obrigatório.
- Agendamento, reagendamento e cancelamento de sessões com validação de conflito de agenda.
- Gestão de **pacotes de tratamento** e saldo de sessões.
- Registro de execução de sessões (áreas tratadas, parâmetros).
- Notificações e lembretes via Flow Designer / IntegrationHub.
- Dashboards operacionais de ocupação e faturamento.
- Portal self-service para clientes (Service Portal).
- Direitos do titular de dados (acesso, correção, exclusão/anonimização).

### Arquitetura
Clean Architecture + DDD adaptados ao ServiceNow, com comunicação REST e privacy by design. Ver [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) e [`CLAUDE.md`](CLAUDE.md).

---

## ✅ Pré-requisitos

- Instância **ServiceNow** (Utah ou superior recomendado).
- Plugins/licenças:
  - Service Portal
  - Custom Application (scoped)
  - Scripted REST API
  - Flow Designer
  - IntegrationHub
  - Automated Test Framework (ATF)
- **MID Server** configurado (para integrações on-premises) nos agentes `localmachine` / `localmachine2`.
- Repositório Git `teste_agent` vinculado ao Source Control da instância.
- Configuração de SSO/SAML para usuários internos e OAuth 2.0 para integrações externas.
- .NET 8 SDK (para o Agente Bridge que roda nesta pasta).

---

## 🚀 Como Instalar e Executar

1. **Clonar o repositório**
   ```bash
   git clone https://github.com/espacolaser/teste_agent.git
   cd teste_agent
   ```
2. **Configurar o Agente Bridge**
   ```bash
   cp appsettings.example.json appsettings.json
   # edite appsettings.json e insira o token do Bridge
   cp .env.example .env
   # preencha as variáveis de ambiente
   ```
3. **Importar a aplicação no ServiceNow**
   - Studio → *Import Application from Source Control* → apontar para o repo `teste_agent`.
   - Selecionar o escopo `x_espaco`.
4. **Atribuir roles** ao usuário: `x_espaco.admin`, `x_espaco.gestor`, `x_espaco.recepcionista`, `x_espaco.profissional`, `x_espaco.leitura`.
5. **Acessar as telas** no Service Portal (ver rotas abaixo).

### Rotas do Portal
| Tela | Rota |
|------|------|
| Agendamento | `/sp?id=espacolaser_agendamento` |
| Meus Agendamentos | `/sp?id=espacolaser_meus_agendamentos` |
| Meus Pacotes | `/sp?id=espacolaser_pacotes` |
| Histórico de Sessões | `/sp?id=espacolaser_historico` |
| Check-in (Recepção) | `/sp?id=espacolaser_checkin` |
| Agenda do Profissional | `/sp?id=espacolaser_agenda_profissional` |
| Dashboard Gestor | `/nav_to.do?uri=x_espacolaser_dashboard` |

---

## 📁 Estrutura de Diretórios

```
teste_agent/
├── x_espaco/src/            # Aplicação scoped exportada (tabelas, scripts, flows, widgets, ACLs)
│   ├── script_include/
│   │   ├── domain/          # Entidades e regras de negócio (DDD)
│   │   ├── application/     # Casos de uso
│   │   └── infrastructure/  # Repositórios GlideRecord, serviços LGPD, cache
│   ├── business_rule/       # Invariantes (thin)
│   ├── sys_ws_definition/   # Scripted REST APIs
│   ├── flow/                # Flow Designer
│   ├── sp_widget/           # Widgets Service Portal
│   ├── sys_security_acl/    # ACLs
│   └── sys_atf_test/        # Testes ATF
├── docs/                    # ARCHITECTURE.md, API_CONTRACTS.md
├── workflow/                # BUILD, QA, TESTS, RELEASE, CI, CD
├── CLAUDE.md                # Instruções para o Claude Code
├── AGENTS.md                # Documentação dos agentes Bridge
├── README.md
├── appsettings.example.json
├── .env.example
└── .gitignore
```

---

## 🛠️ Tecnologias Utilizadas

| Categoria | Tecnologia |
|-----------|-----------|
| Plataforma | ServiceNow (Custom App scoped `x_espaco`) |
| Persistência | ServiceNow Tables + GlideRecord |
| Domínio | Script Includes (DDD) |
| Invariantes | Business Rules |
| API | Scripted REST API (`/api/x_espaco/*`) |
| Orquestração | Flow Designer + IntegrationHub |
| UI | Service Portal Widgets / UI Builder |
| Testes | Automated Test Framework (ATF) + Postman |
| Segurança | ACLs, OAuth 2.0, Field Encryption, LGPD |
| CI/CD | GitHub Actions + Source Control + Update Sets |

---

## 🧪 Como Rodar Testes

- **ATF**: *Automated Test Framework > Test Suites* → executar `x_espaco - Regras Críticas`.
- **API**: importar a collection em `docs/API_CONTRACTS.md` no Postman.
- **Cobertura mínima**: 80% das regras críticas.
- Detalhes completos em [`workflow/TESTS.md`](workflow/TESTS.md).

---

## 📦 Como Fazer Deploy

Estratégia **rolling** entre `dev → staging → prod` via Update Sets promovidos por GitHub Actions. Detalhes em [`workflow/CD.md`](workflow/CD.md) e [`workflow/RELEASE.md`](workflow/RELEASE.md).

---

## 🤝 Contribuição

1. Crie uma branch `feature/fase-<n>-<descricao>`.
2. Siga as convenções em [`CLAUDE.md`](CLAUDE.md).
3. Garanta ATF verde e cobertura ≥80%.
4. Abra PR para `develop` com evidências de teste.
5. Aguarde CI verde + 1 revisão.

---

## 🔒 Conformidade LGPD/GDPR

Dados pessoais sensíveis (saúde/estética) são tratados com consentimento registrado, ACLs por campo, auditoria e anonimização mediante aprovação do DPO. Nunca comite dados reais ou credenciais.

---

## 📄 Licença

Uso interno — Espaço Laser. Todos os direitos reservados.
