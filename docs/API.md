# API — Espaço Laser (Scripted REST API `/api/x_espaco/*`)

Base URL: `https://<instância>.service-now.com/api/x_espaco`

## Convenções
- **Autenticação**: OAuth 2.0 (Bearer token) para integrações externas; sessão ServiceNow (SSO/SAML) para usuários internos.
- **Formato**: `application/json`.
- **Listas**: envelope `{ "data": [...], "meta": { "page", "limit", "total" } }`.
- **Erros**: `{ "error": { "code", "message", "details" } }`.
- **Paginação**: `page` (default 1), `limit` (default 20, máx 100).
- **Autorização por role**: `x_espaco.recepcao`, `x_espaco.profissional`, `x_espaco.gestor`, `x_espaco.dpo`, `x_espaco.leitura`.

---

## 1. GET /agenda/disponibilidade
Retorna horários disponíveis por unidade, serviço e profissional.

**Query params**: `unidade_id` (obrigatório), `servico_id` (obrigatório), `data` (YYYY-MM-DD, obrigatório), `profissional_id` (opcional).

**Response 200**:
```json
{
  "data": [
    { "profissional_id": "a1b2", "profissional": "Rafael", "slots": ["09:00","09:20","10:00"] }
  ],
  "meta": { "unidade_id": "u1", "servico_id": "s1", "data": "2024-07-01" }
}
```
**Códigos**: 200 OK, 400 (params ausentes), 401, 403.

---

## 2. POST /agendamento
Cria um novo agendamento validando saldo de pacote (RN-01) e conflito de agenda (RN-02).

**Roles**: `x_espaco.recepcao`, `x_espaco.cliente`.

**Request body**:
```json
{
  "cliente_id": "c123",
  "profissional_id": "p456",
  "unidade_id": "u1",
  "servico_id": "s1",
  "pacote_cliente_id": "pc789",
  "data_hora": "2024-07-01T09:00:00"
}
```
**Response 201**:
```json
{
  "data": {
    "sys_id": "ag001",
    "cliente_id": "c123",
    "profissional_id": "p456",
    "data_hora": "2024-07-01T09:00:00",
    "status": "agendado"
  }
}
```
**Códigos**: 201 Created, 400 (validação), 403 (sem consentimento LGPD / RN-07), 409 (conflito de agenda RN-02 ou sem saldo RN-01), 422 (pacote expirado RN-05).

---

## 3. PUT /agendamento/{id}
Reagenda ou cancela um agendamento existente (RN-03 antecedência 24h).

**Roles**: `x_espaco.recepcao`, `x_espaco.cliente`.

**Path**: `id` = sys_id do agendamento.
**Request body**:
```json
{ "acao": "reagendar", "nova_data_hora": "2024-07-02T10:00:00" }
```
ou
```json
{ "acao": "cancelar" }
```
**Response 200**:
```json
{ "data": { "sys_id": "ag001", "status": "reagendado", "penalidade": false } }
```
**Códigos**: 200 OK, 400, 404 (não encontrado), 409 (novo horário em conflito), 422 (viola antecedência com penalidade aplicada).

---

## 4. POST /sessao/checkin
Realiza o check-in de um cliente para a sessão (RF-10).

**Roles**: `x_espaco.recepcao`.
**Request body**: `{ "agendamento_id": "ag001" }`
**Response 200**:
```json
{ "data": { "agendamento_id": "ag001", "status": "confirmado", "checkin_em": "2024-07-01T08:55:00" } }
```
**Códigos**: 200, 400, 404, 409 (status incompatível).

---

## 5. POST /sessao/concluir
Registra conclusão da sessão e debita saldo do pacote (RF-11, RF-12, RN-04).

**Roles**: `x_espaco.profissional`.
**Request body**:
```json
{
  "agendamento_id": "ag001",
  "areas_tratadas": "Axila esquerda, Axila direita",
  "parametros": "Fluência 12 J/cm², spot 10mm"
}
```
**Response 200**:
```json
{
  "data": {
    "sessao_id": "se001",
    "agendamento_status": "realizado",
    "saldo_restante": 9
  }
}
```
**Códigos**: 200, 400, 404, 409 (sem saldo / status inválido).

---

## 6. GET /cliente/{id}/pacotes
Consulta pacotes e saldos do cliente (RF-16).

**Roles**: `x_espaco.cliente` (apenas próprios / RN-09), `x_espaco.recepcao`, `x_espaco.gestor`.
**Response 200**:
```json
{
  "data": [
    { "pacote_cliente_id": "pc789", "pacote": "Pacote 10 sessões Axila", "saldo_sessoes": 9, "data_expiracao": "2025-07-01", "status": "ativo" }
  ]
}
```
**Códigos**: 200, 403 (acesso a outro titular), 404.

---

## 7. GET /cliente/{id}/historico
Retorna histórico de sessões realizadas do cliente (RF-16).

**Roles**: `x_espaco.cliente` (próprio), `x_espaco.profissional`, `x_espaco.gestor`.
**Query params**: `page`, `limit`, `data_inicio`, `data_fim`.
**Response 200**:
```json
{
  "data": [
    { "sessao_id": "se001", "servico": "Axila", "data_realizacao": "2024-06-01T09:00:00", "areas_tratadas": "Axila" }
  ],
  "meta": { "page": 1, "limit": 20, "total": 1 }
}
```
**Códigos**: 200, 403, 404.

---

## 8. POST /lgpd/solicitacao
Registra solicitação de titular de dados (RF-14, RN-08).

**Roles**: `x_espaco.cliente`, `x_espaco.dpo`.
**Request body**: `{ "cliente_id": "c123", "tipo": "exclusao" }`
**Response 201**:
```json
{ "data": { "protocolo": "LGPD-2024-000123", "tipo": "exclusao", "status": "nova" } }
```
**Códigos**: 201, 400 (tipo inválido), 403.

---

## Endpoints Auxiliares (CRUD de cadastros — camada de aplicação)

| Método | Rota | Descrição | Roles |
|---|---|---|---|
| GET | /clientes | Lista paginada de clientes (`page`,`limit`,`search`) | recepcao, gestor, leitura |
| POST | /clientes | Cria cliente + consentimento LGPD | recepcao |
| GET | /servicos | Lista serviços (cache de referência) | todas |
| GET | /agendamentos | Lista filtrada (`data`,`profissional_id`,`clienteId`) | recepcao, profissional, gestor |
| GET | /pacotes | Pacotes de um cliente (`clienteId`) | recepcao, gestor |

### Exemplo — POST /clientes
```json
// Request
{ "nome": "Carla Souza", "email": "carla@ex.com", "telefone": "+5511999999999", "consentimentoLgpd": true, "finalidade": "Prestação de serviço de depilação", "versaoTermo": "1.0" }
// Response 201
{ "data": { "sys_id": "c123", "nome": "Carla Souza", "consentimento_lgpd": true } }
```
Dispara evento `cliente.cadastrado`.

## Tabela de Códigos HTTP
| Código | Significado no contexto |
|---|---|
| 200 | Operação bem-sucedida |
| 201 | Recurso criado |
| 400 | Erro de validação de entrada |
| 401 | Não autenticado |
| 403 | Sem permissão / consentimento LGPD ausente |
| 404 | Recurso não encontrado |
| 409 | Conflito (agenda/saldo) |
| 422 | Regra de negócio violada (pacote expirado, antecedência) |
| 500 | Erro interno |

## Performance
Todas as respostas devem ficar abaixo de 2s (RNF-04). Uso de `GlideAggregate` para agregações e cache de referência (`ReferenceCacheService`) para `/servicos`.
