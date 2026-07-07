# FASE 05 — Fluxos, Notificações e Integrações

> Projeto: **Espaço Laser** — ServiceNow scoped `x_espaco`
> Duração estimada: **6 dias** (Semanas 8–9)
> Depende de: **FASE 01–04** concluídas

---

## 1. Objetivo

Orquestrar os **fluxos de negócio** e **notificações** (confirmação, lembrete, cancelamento, esgotamento de pacote) usando **Flow Designer** e **IntegrationHub**, conectados aos **eventos de domínio** da Fase 2. Implementar **cache de dados de referência** (serviços) com invalidação.

---

## 2. Pré-requisitos

- FASE 04 concluída.
- Plugins: Flow Designer, IntegrationHub (Spoke E-mail/SMS).
- Eventos de domínio registrados (Fase 2): `cliente.cadastrado`, `agendamento.criado`, `agendamento.cancelado`, `sessao.concluida`, `pacote.esgotado`.
- Credenciais do gateway de notificação em **Connection & Credential Alias**.

---

## 3. Fluxos a Implementar

### 3.1 Mapeamento Evento → Flow

```
agendamento.criado    ──► Flow "Confirmação de Agendamento"  ──► E-mail ao cliente
(scheduled X horas)    ──► Flow "Lembrete de Sessão"         ──► E-mail/SMS ao cliente
agendamento.cancelado ──► Flow "Aviso de Cancelamento"       ──► E-mail (inclui penalidade se houver)
pacote.esgotado       ──► Flow "Renovação de Pacote"         ──► E-mail gestor + cliente
```

### 3.2 Flow: Confirmação de Agendamento (RF-10 / RF-15)

**Trigger:** Event → `agendamento.criado`

**Passos:**
1. Look Up Record `x_espaco_agendamento` pelo `event.parm1`/glide_record.
2. Get cliente, servico, profissional (dot-walk).
3. Verificar consentimento LGPD (Data privacy — só notifica se `consentimento_lgpd=true`).
4. **Subflow `EnviarNotificacao`** com: destinatário=email cliente, template=confirmacao, dados={servico, profissional, data_hora}.

### 3.3 Flow: Lembrete de Sessão (agendado)

**Trigger:** Scheduled (a cada hora).
**Lógica:** buscar agendamentos com `status IN (novo,confirmado)` cuja `data_hora` esteja entre `now+23h` e `now+24h`, enviar lembrete via subflow (E-mail/SMS).

### 3.4 Flow: Aviso de Cancelamento (RN-04)

**Trigger:** Event → `agendamento.cancelado`.
**Lógica:** notificar cliente; se `penalidade=true`, incluir aviso da política de penalidade.

### 3.5 Flow: Renovação de Pacote

**Trigger:** Event → `pacote.esgotado`.
**Lógica:** notificar gestor (role `x_espaco.gestor`) e cliente para renovação.

---

## 4. Subflow Reutilizável `EnviarNotificacao`

Inputs: `destinatarioEmail`, `destinatarioTelefone`, `template`, `dados` (objeto).
Ações:
- Se e-mail disponível → **Send Email** (Notification record).
- Se telefone disponível e canal SMS → **IntegrationHub REST Step** para o gateway `https://notify.espacolaser.com/api/send` (credencial via alias).
- Retry/erro tratado (política de retry do IntegrationHub).

---

## 5. Cache de Dados de Referência

### 5.1 `ReferenceCacheService`

```javascript
var ReferenceCacheService = Class.create();
ReferenceCacheService.prototype = {
    initialize: function() { this.KEY = 'x_espaco.servicos.cache'; },

    getServicos: function() {
        var cache = gs.getSession().getProperty(this.KEY);
        if (cache) return JSON.parse(cache);
        var list = [];
        var gr = new GlideRecord('x_espaco_servico');
        gr.orderBy('nome');
        gr.query();
        while (gr.next()) {
            list.push({ sys_id: gr.getUniqueValue(), nome: gr.getValue('nome'),
                        area: gr.getValue('area_corporal'),
                        duracao: gr.getValue('duracao_minutos') });
        }
        gs.getSession().putProperty(this.KEY, JSON.stringify(list));
        return list;
    },

    invalidar: function() {
        gs.getSession().clearProperty(this.KEY);
    },
    type: 'ReferenceCacheService'
};
```

### 5.2 Business Rule de Invalidação

```javascript
// BR after insert/update/delete em x_espaco_servico
new ReferenceCacheService().invalidar();
```

> Alternativamente usar `gs.cacheFlush()` de escopo ou `GlideScopedEvaluator` conforme padrão da instância.

---

## 6. Notification Records

Criar Notifications (System Notification → Email) para os templates: `confirmacao`, `lembrete`, `cancelamento`, `renovacao`, com variáveis de mesclagem (cliente, serviço, data_hora).

---

## 7. Testes

### 7.1 Manual / ATF
- Criar agendamento via API (Fase 3) → verificar que o Flow de confirmação disparou (checar Flow execution + email log).
- Cancelar agendamento < 24h → verificar aviso com penalidade.
- Alterar serviço → verificar que `ReferenceCacheService.getServicos()` retorna dados atualizados.
- Executar flow agendado manualmente → verificar lembretes para agendamentos na janela.

### 7.2 Verificação de Eventos

```javascript
// Background: confirmar disparo
gs.eventQueue('agendamento.criado', new GlideRecord('x_espaco_agendamento'), 'teste', '');
```

---

## 8. Critérios de Aceite

- [ ] Cliente notificado ao criar agendamento (RF-10/RF-15).
- [ ] Lembretes enviados antes da sessão (flow agendado).
- [ ] Aviso de cancelamento com penalidade quando aplicável.
- [ ] Notificação de pacote esgotado a gestor e cliente.
- [ ] Todos os eventos de domínio acionam seus flows.
- [ ] Cache de serviços invalidado ao alterar dados de referência.
- [ ] Credenciais via Credential Alias; HTTPS.

---

## 9. Checklist

```
[ ] Flow Confirmação de Agendamento (evento agendamento.criado)
[ ] Flow Lembrete de Sessão (scheduled)
[ ] Flow Aviso de Cancelamento (evento agendamento.cancelado)
[ ] Flow Renovação de Pacote (evento pacote.esgotado)
[ ] Subflow EnviarNotificacao (E-mail/SMS via IntegrationHub)
[ ] ReferenceCacheService + BR de invalidação
[ ] Notification records (4 templates)
[ ] Credenciais via Credential Alias
[ ] Testes de disparo de eventos e cache
[ ] Git commit
```

---

## 10. PROMPT PARA O CLAUDE CODE

```
Implemente os fluxos de negócio, notificações e integrações da aplicação scoped x_espaco usando
Flow Designer e IntegrationHub. Tecnologias: Flow Designer, IntegrationHub Spokes (E-mail/SMS),
Event Registry, Notification records, Script Includes de cache, Connection & Credential Alias.

Crie:
1. Flow acionado pelo evento agendamento.criado que envia notificação de confirmação por e-mail
   ao cliente (RF-10/RF-15), incluindo serviço, profissional e data/hora. Só notifica se o cliente
   tem consentimento_lgpd=true.
2. Flow scheduled (a cada hora) que envia lembrete ao cliente ~24h antes da data_hora via e-mail/SMS
   através de um IntegrationHub Spoke, para agendamentos com status novo/confirmado.
3. Flow acionado por agendamento.cancelado que notifica o cliente e, se penalidade=true, inclui aviso (RN-04).
4. Flow acionado por pacote.esgotado que notifica gestor (role x_espaco.gestor) e cliente para renovação.
5. Subflow reutilizável EnviarNotificacao (inputs: destinatarioEmail, destinatarioTelefone, template, dados)
   que envia e-mail via Notification e SMS via REST Step ao gateway https://notify.espacolaser.com/api/send.
6. Vincule os eventos de domínio (cliente.cadastrado, agendamento.criado, agendamento.cancelado,
   sessao.concluida, pacote.esgotado) aos flows correspondentes.
7. Script Include ReferenceCacheService que cacheia a lista de serviços e método invalidar(); Business Rule
   em x_espaco_servico (insert/update/delete) que invalida o cache.
8. Notification records: confirmacao, lembrete, cancelamento, renovacao.

Configure credenciais via Connection & Credential Alias. Flows desacoplados via eventos, subflows reutilizáveis.

Critérios: criar agendamento via API notifica o cliente; cancelar avisa; lembretes disparados pelo flow
agendado; alterar serviço invalida o cache; todos os eventos acionam seus flows.
```
