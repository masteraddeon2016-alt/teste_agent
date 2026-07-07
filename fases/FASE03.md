# FASE 03 — Casos de Uso e Scripted REST APIs

> Projeto: **Espaço Laser** — ServiceNow scoped `x_espaco`
> Duração estimada: **9 dias** (Semanas 4–6)
> Depende de: **FASE 01 e 02** concluídas

---

## 1. Objetivo

Implementar a camada de **Aplicação (casos de uso)** e expor os endpoints via **Scripted REST API** (`/api/x_espaco/*`), com validação de entrada, paginação, contratos REST definidos e tratamento centralizado de erros. Os *resources* REST são **finos** e delegam para Script Includes de caso de uso, que orquestram as entidades de domínio da Fase 2.

---

## 2. Pré-requisitos

- FASE 02 concluída (domínio + regras + eventos).
- Plugin **Scripted REST API** habilitado.
- Postman ou REST API Explorer para testes.

---

## 3. Contratos de API

| Método | Endpoint | Descrição | Role mínima |
|--------|----------|-----------|-------------|
| GET | `/api/x_espaco/clientes` | Lista paginada (page, limit, search) | leitura |
| POST | `/api/x_espaco/clientes` | Cria cliente + evento `cliente.cadastrado` | recepcionista |
| GET | `/api/x_espaco/servicos` | Lista serviços (cacheável) | leitura |
| GET | `/api/x_espaco/agendamentos` | Lista filtrada (data, profissionalId, clienteId) | leitura |
| POST | `/api/x_espaco/agendamentos` | Cria agendamento (valida regras) | recepcionista |
| PUT | `/api/x_espaco/agendamentos/{id}` | Reagenda / cancela | recepcionista |
| GET | `/api/x_espaco/pacotes` | Lista pacotes por clienteId | leitura |

### 3.1 Códigos HTTP

| Código | Uso |
|--------|-----|
| 200 | GET/PUT com sucesso |
| 201 | POST criação |
| 400 | Campos obrigatórios ausentes/inválidos |
| 401/403 | Sem autorização (ACL) |
| 404 | Recurso inexistente |
| 409 | Conflito de agenda (RN-02) |

### 3.2 Formato de resposta de lista

```json
{
  "data": [ { "..." } ],
  "meta": { "page": 1, "limit": 20, "total": 137 }
}
```

### 3.3 Formato de erro

```json
{ "error": { "code": 400, "message": "Campo 'email' é obrigatório." } }
```

---

## 4. Casos de Uso (Camada Aplicação)

### 4.1 `CadastrarClienteUseCase`

```javascript
var CadastrarClienteUseCase = Class.create();
CadastrarClienteUseCase.prototype = {
    initialize: function() {},

    execute: function(dto) {
        // dto: {nome, email, telefone, consentimentoLgpd}
        if (!dto.nome) throw { code: 400, message: "Campo 'nome' é obrigatório." };
        var gr = new GlideRecord('x_espaco_cliente');
        gr.initialize();
        gr.setValue('nome', dto.nome);
        gr.setValue('email', dto.email || '');
        gr.setValue('telefone', dto.telefone || '');
        gr.setValue('consentimento_lgpd', dto.consentimentoLgpd ? true : false);
        var id = gr.insert();
        gs.eventQueue('cliente.cadastrado', gr, id, '');
        return { sys_id: id, nome: dto.nome };
    },
    type: 'CadastrarClienteUseCase'
};
```

### 4.2 `AgendarSessaoUseCase`

```javascript
var AgendarSessaoUseCase = Class.create();
AgendarSessaoUseCase.prototype = {
    initialize: function() {},

    execute: function(dto) {
        // dto: {clienteId, servicoId, profissionalId, dataHora}
        ['clienteId','servicoId','profissionalId','dataHora'].forEach(function(f){
            if (!dto[f]) throw { code: 400, message: "Campo '" + f + "' é obrigatório." };
        });
        // Conflito (RN-02) — validação antecipada para retornar 409
        if (new AgendamentoEntity().existeConflito(dto.profissionalId, dto.dataHora, null)) {
            throw { code: 409, message: 'Profissional já possui agendamento neste horário.' };
        }
        var gr = new GlideRecord('x_espaco_agendamento');
        gr.initialize();
        gr.setValue('cliente', dto.clienteId);
        gr.setValue('servico', dto.servicoId);
        gr.setValue('profissional', dto.profissionalId);
        gr.setValue('data_hora', dto.dataHora);
        gr.setValue('status', 'novo');
        var id = gr.insert(); // BR da Fase 2 valida RN-01/RN-02
        if (!id) throw { code: 400, message: 'Não foi possível criar o agendamento (regra de negócio).' };
        return { sys_id: id, status: 'novo' };
    },
    type: 'AgendarSessaoUseCase'
};
```

---

## 5. Scripted REST API

Crie **Scripted REST API** com API ID `x_espaco` (base path `/api/x_espaco`).

### 5.1 Resource: POST /clientes

```javascript
(function process(request, response) {
    try {
        var body = request.body.data;
        var out = new CadastrarClienteUseCase().execute(body);
        response.setStatus(201);
        return { data: out };
    } catch (e) {
        response.setStatus(e.code || 500);
        return { error: { code: e.code || 500, message: e.message || 'Erro interno' } };
    }
})(request, response);
```

### 5.2 Resource: GET /clientes (paginação + busca)

```javascript
(function process(request, response) {
    var page  = parseInt(request.queryParams.page  || '1', 10);
    var limit = Math.min(parseInt(request.queryParams.limit || '20', 10), 100);
    var search = request.queryParams.search || '';
    var offset = (page - 1) * limit;

    var gr = new GlideRecord('x_espaco_cliente');
    if (search) gr.addQuery('nmeILIKE', search).addOrCondition('email', 'CONTAINS', search);
    gr.orderBy('nome');
    gr.chooseWindow(offset, offset + limit);
    gr.query();

    var data = [];
    while (gr.next()) {
        data.push({
            sys_id: gr.getUniqueValue(),
            nome: gr.getValue('nome'),
            email: gr.getValue('email'),
            telefone: gr.getValue('telefone'),
            consentimento_lgpd: gr.getValue('consentimento_lgpd')
        });
    }
    var count = new GlideAggregate('x_espaco_cliente');
    count.addAggregate('COUNT');
    count.query();
    var total = count.next() ? parseInt(count.getAggregate('COUNT'), 10) : 0;

    return { data: data, meta: { page: page, limit: limit, total: total } };
})(request, response);
```

### 5.3 Resource: POST /agendamentos

```javascript
(function process(request, response) {
    try {
        var out = new AgendarSessaoUseCase().execute(request.body.data);
        response.setStatus(201);
        return { data: out };
    } catch (e) {
        response.setStatus(e.code || 500);
        return { error: { code: e.code || 500, message: e.message } };
    }
})(request, response);
```

### 5.4 Resource: PUT /agendamentos/{id}

```javascript
(function process(request, response) {
    var id = request.pathParams.id;
    var body = request.body.data;
    var gr = new GlideRecord('x_espaco_agendamento');
    if (!gr.get(id)) {
        response.setStatus(404);
        return { error: { code: 404, message: 'Agendamento não encontrado.' } };
    }
    if (body.dataHora) { gr.setValue('data_hora', body.dataHora); gr.setValue('status', 'reagendado'); }
    if (body.status)   { gr.setValue('status', body.status); }
    if (!gr.update()) {
        response.setStatus(409);
        return { error: { code: 409, message: 'Conflito ao atualizar agendamento.' } };
    }
    return { data: { sys_id: id, status: gr.getValue('status') } };
})(request, response);
```

---

## 6. Segurança (ACL nos Resources)

Em cada resource, defina **Requires ACL authorization** e associe a role adequada, ou valide via `gs.hasRole('x_espaco.recepcionista')` para POST/PUT.

---

## 7. Testes

### 7.1 Postman / REST API Explorer

```
POST /api/x_espaco/clientes
{ "nome":"Carla", "email":"carla@x.com", "consentimentoLgpd": true }
-> 201 { data: { sys_id, nome } }

POST /api/x_espaco/clientes
{ "email":"x@x.com" }
-> 400 { error: { message: "Campo 'nome' é obrigatório." } }

POST /api/x_espaco/agendamentos (horário já ocupado)
-> 409 conflito
```

### 7.2 ATF REST

Crie testes ATF do tipo **REST** validando status codes 201/400/404/409 e paginação.

---

## 8. Critérios de Aceite

- [ ] Os 7 endpoints funcionando conforme contrato.
- [ ] Paginação (page, limit≤100) e busca funcionais.
- [ ] Validação retorna 400/404/409 corretamente.
- [ ] Regras da Fase 2 respeitadas via API (RN-01/RN-02/RN-03).
- [ ] Respostas < 2s (RNF-04).
- [ ] Resources delegam para casos de uso (thin resources).
- [ ] Contratos documentados.

---

## 9. Checklist

```
[ ] CadastrarClienteUseCase / AgendarSessaoUseCase / RegistrarSessaoUseCase / GerenciarPacoteUseCase
[ ] Scripted REST API x_espaco (base /api/x_espaco)
[ ] GET/POST clientes, GET servicos, GET/POST/PUT agendamentos, GET pacotes
[ ] Paginação + busca + formato {data, meta}
[ ] Tratamento de erros {error:{code,message}}
[ ] ACLs por role nos resources
[ ] Testes REST (Postman + ATF)
[ ] Git commit
```

---

## 10. PROMPT PARA O CLAUDE CODE

```
Implemente a camada de aplicação (casos de uso) e as Scripted REST APIs da aplicação scoped
x_espaco. Tecnologias: ServiceNow Scripted REST API, Script Includes de aplicação, GlideRecord,
GlideAggregate, RESTAPIRequest/RESTAPIResponse. Arquitetura Clean: resources REST finos que
delegam para Script Includes de caso de uso (CadastrarClienteUseCase, AgendarSessaoUseCase,
RegistrarSessaoUseCase, GerenciarPacoteUseCase) que usam as entidades de domínio da Fase 2.

Crie a Scripted REST API base namespace x_espaco (/api/x_espaco) com os recursos:
- GET /clientes (page, limit default 20 max 100, search) -> lista paginada {data, meta}
- POST /clientes (nome, email, telefone, consentimentoLgpd) -> cria e dispara cliente.cadastrado (201)
- GET /servicos -> lista serviços (cacheável)
- GET /agendamentos (data, profissionalId, clienteId) -> lista filtrada
- POST /agendamentos (clienteId, servicoId, profissionalId, dataHora) -> cria validando regras (201/409)
- PUT /agendamentos/{id} (dataHora, status) -> reagenda/cancela (200/404)
- GET /pacotes (clienteId) -> pacotes do cliente

Implemente: paginação padrão, validação de obrigatórios com HTTP 400 estruturado, 404 para
inexistente, 409 para conflito de agenda (RN-02). Aplique ACLs para respeitar as roles
(recepcionista cria cliente/agendamento, leitura apenas GET). Respostas de lista no formato
{data, meta}; tratamento centralizado de erros {error:{code,message}}. Documente os contratos.

Critérios: 7 endpoints respondem corretamente, paginação e filtros funcionam, validações
retornam códigos HTTP corretos, regras da Fase 2 respeitadas, respostas < 2s.
```
