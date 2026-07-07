# Plano de Testes — Espaço Laser

## 1. Estratégia

Testes automatizados em múltiplos níveis usando o **Automated Test Framework (ATF)** do ServiceNow, cobrindo regras de negócio críticas, contratos de API e fluxos ponta a ponta, complementados por UAT do cliente e testes de performance das APIs.

**Cobertura mínima**: **80%** das regras críticas.

## 2. Níveis de Teste

### 2.1 Testes Unitários (Script Includes de domínio)
- **Ferramenta**: ATF (server-side test steps) + assertions em Script Includes.
- **Escopo**: métodos de `PacoteEntity`, `AgendamentoEntity`, `ClienteEntity`.
- **Cenários**:
  - `PacoteEntity.deduzirSessao()` bloqueia quando `saldo_sessoes = 0` (RN-01).
  - Pacote muda para `esgotado` ao atingir total.
  - `ClienteEntity.temConsentimentoAtivo()` retorna false sem consentimento.

### 2.2 Testes de Integração (Business Rules + Tabelas)
- **Ferramenta**: ATF (Record insert/update steps).
- **Cenários**:
  - Insert de `u_agendamento` rejeitado quando profissional já ocupado no horário (RN-02).
  - Insert de agendamento rejeitado sem consentimento LGPD (RN-07).
  - Cancelamento < 24h marca `penalidade = true` (RN-04).
  - Evento `pacote.esgotado` disparado quando saldo chega a zero.

### 2.3 Testes de API (contratos REST)
- **Ferramenta**: ATF REST test steps + Postman/REST API Explorer.
- **Cenários**:
  - `POST /agendamento` → 201 com payload válido; 409 em conflito; 403 sem consentimento; 422 pacote expirado.
  - `GET /clientes?page=1&limit=20&search=Carla` → envelope `{data, meta}` correto.
  - `PUT /agendamento/{id}` reagenda e mantém validação de conflito.
  - `POST /sessao/concluir` deduz saldo e retorna `saldo_restante`.
  - `GET /cliente/{id}/pacotes` retorna 403 para titular diferente (RN-09).

### 2.4 Testes E2E (fluxos ponta a ponta)
- **Ferramenta**: ATF client + server tests.
- **Cenários**:
  1. Cadastrar cliente com consentimento → agendar sessão → check-in → concluir sessão → verificar débito de pacote.
  2. Solicitar exclusão LGPD → aprovação DPO → anonimização → verificação de auditoria.
  3. Cancelamento < 24h → penalidade → notificação disparada.

### 2.5 Testes de Performance
- **Ferramenta**: Postman runner / Performance Analytics.
- **Meta**: respostas de API < 2s (RNF-04); telas do portal < 3s (RNF-06).
- **Cenários**: listagem de agendamentos com 10k registros; dashboard com `GlideAggregate`.

### 2.6 Testes de Segurança
- **Cenários**:
  - `x_espaco.leitura` não acessa `email`/`telefone` (field ACL).
  - Cliente não acessa dados de outro titular.
  - Profissional só vê agenda de unidades vinculadas (RN-10).
  - Entradas malformadas nas APIs retornam 400 sem vazar stack trace.

## 3. Ferramentas

| Ferramenta | Uso |
|---|---|
| ServiceNow ATF | Unit, integration, e2e, API, security |
| Postman | Testes exploratórios e de contrato de API |
| REST API Explorer | Validação manual de endpoints |
| Performance Analytics | Métricas de performance e KPIs |

## 4. Dados de Teste

- **Cliente demo** com consentimento ativo e pacote com saldo 10.
- **Cliente sem consentimento** para validar bloqueio (RN-07).
- **Profissional** com agenda pré-ocupada para validar conflito (RN-02).
- **Pacote esgotado** para validar RN-01.
- **Pacote expirado** para validar RN-05.
- Fixtures carregadas apenas em ambientes ≠ produção.

## 5. Automação e CI/CD

- Suíte ATF executada automaticamente no pipeline **GitHub Actions** antes da promoção de Update Sets entre dev → staging → prod.
- Falha em qualquer teste crítico bloqueia a promoção.
- Relatório de cobertura anexado ao pipeline (meta ≥80%).

## 6. Matriz de Rastreabilidade Testes → Regras

| Regra | Teste |
|---|---|
| RN-01 saldo | Unit PacoteEntity + API 409 |
| RN-02 conflito | Integração BR + API 409 |
| RN-03 antecedência | Integração cancelamento < 24h |
| RN-04 débito ao realizar | E2E concluir sessão |
| RN-05 pacote expirado | API 422 |
| RN-07 consentimento | Integração + API 403 |
| RN-08 aprovação DPO | E2E exclusão LGPD |
| RN-09/RN-10 isolamento | Security tests |

## 7. Critérios de Saída (Exit Criteria)
- 100% dos cenários críticos executados.
- ≥80% de cobertura das regras críticas.
- Nenhum defeito de severidade alta em aberto.
- Performance dentro dos SLAs (API <2s, portal <3s).
- UAT aprovado pelo cliente e DPO.
