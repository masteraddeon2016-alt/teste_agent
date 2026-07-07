# FASE 02 — Camada de Domínio e Regras de Negócio

> Projeto: **Espaço Laser** — ServiceNow scoped `x_espaco`
> Duração estimada: **8 dias** (Semanas 2–4)
> Depende de: **FASE 01** concluída

---

## 1. Objetivo

Implementar a camada de **Domínio (DDD)** com entidades, agregados e regras de negócio (invariantes), utilizando **Script Includes** e **Business Rules**. Registrar **eventos de domínio** e cobrir as regras críticas com **testes ATF**.

---

## 2. Pré-requisitos

- FASE 01 concluída (tabelas, roles, esqueletos de Script Includes).
- Plugin **ATF (Automated Test Framework)** habilitado.
- Acesso ao **Event Registry** (`sysevent_register`).

---

## 3. Regras de Negócio a Implementar

| Código | Regra | Onde |
|--------|-------|------|
| RN-01 | Agendamento exige consentimento LGPD do cliente | BR + ClienteEntity |
| RN-02 | Não permitir 2 agendamentos do mesmo profissional no mesmo horário | BR + AgendamentoEntity |
| RN-03 | Só deduzir sessão se `sessoes_utilizadas < total_sessoes` | PacoteEntity |
| RN-04 | Cancelamento < 24h da data_hora marca penalidade | BR |
| RN-05 | Pacote esgotado (saldo=0) marca status `esgotado` e emite evento | BR after update |

---

## 4. Eventos de Domínio (Event Registry)

| Evento | Disparado quando |
|--------|------------------|
| `cliente.cadastrado` | Cliente criado |
| `agendamento.criado` | Agendamento inserido |
| `agendamento.cancelado` | Agendamento cancelado |
| `sessao.concluida` | Agendamento concluído |
| `pacote.esgotado` | Saldo do pacote chega a 0 |

Registrar via **System Policy → Events → Registry** ou `sysevent_register.list`.

---

## 5. Implementação

### 5.1 `PacoteEntity` (Domínio) — RN-03 / RN-05

```javascript
// Script Include: PacoteEntity  (Camada DOMÍNIO, client_callable=false)
var PacoteEntity = Class.create();
PacoteEntity.prototype = {
    initialize: function(pacoteGr) {
        this.gr = pacoteGr; // GlideRecord x_espaco_pacote
    },

    temSaldo: function() {
        return parseInt(this.gr.getValue('sessoes_utilizadas'), 10) <
               parseInt(this.gr.getValue('total_sessoes'), 10);
    },

    /**
     * Deduz uma sessão. RN-03: só permite com saldo.
     * Marca 'esgotado' ao atingir o total (RN-05).
     * @returns {boolean} true se deduziu
     */
    deduzirSessao: function() {
        if (!this.temSaldo()) {
            gs.addErrorMessage('Pacote sem saldo de sessões disponível.');
            return false;
        }
        var usadas = parseInt(this.gr.getValue('sessoes_utilizadas'), 10) + 1;
        this.gr.setValue('sessoes_utilizadas', usadas);
        if (usadas >= parseInt(this.gr.getValue('total_sessoes'), 10)) {
            this.gr.setValue('status', 'esgotado');
        }
        this.gr.update();
        return true;
    },

    type: 'PacoteEntity'
};
```

### 5.2 `AgendamentoEntity` (Domínio) — RN-02

```javascript
// Script Include: AgendamentoEntity (Camada DOMÍNIO)
var AgendamentoEntity = Class.create();
AgendamentoEntity.prototype = {
    initialize: function() {},

    /**
     * RN-02: existe conflito se houver agendamento ativo do mesmo
     * profissional na mesma data_hora (exceto o próprio registro).
     */
    existeConflito: function(profissionalId, dataHora, ignoraSysId) {
        var gr = new GlideRecord('x_espaco_agendamento');
        gr.addQuery('profissional', profissionalId);
        gr.addQuery('data_hora', dataHora);
        gr.addQuery('status', 'IN', 'novo,confirmado');
        if (ignoraSysId) gr.addQuery('sys_id', '!=', ignoraSysId);
        gr.query();
        return gr.hasNext();
    },

    type: 'AgendamentoEntity'
};
```

### 5.3 Business Rule — RN-01 + RN-02 (before insert/update em `x_espaco_agendamento`)

```javascript
// Business Rule: 'Validar Agendamento' — When: before, Insert+Update
(function executeRule(current, previous) {
    // RN-01: cliente precisa de consentimento LGPD
    var cli = new GlideRecord('x_espaco_cliente');
    if (cli.get(current.getValue('cliente'))) {
        if (cli.getValue('consentimento_lgpd') != 'true') {
            gs.addErrorMessage('Cliente sem consentimento LGPD válido. Agendamento bloqueado.');
            current.setAbortAction(true);
            return;
        }
    }
    // RN-02: conflito de horário
    var ent = new AgendamentoEntity();
    if (ent.existeConflito(current.getValue('profissional'),
                           current.getValue('data_hora'),
                           current.getUniqueValue())) {
        gs.addErrorMessage('Profissional já possui agendamento neste horário.');
        current.setAbortAction(true);
        return;
    }
})(current, previous);
```

### 5.4 Business Rule — RN-04 (before update, cancelamento < 24h)

```javascript
// Business Rule: 'Penalidade Cancelamento' — before, Update
// Condition: current.status.changesTo('cancelado')
(function executeRule(current, previous) {
    var agora = new GlideDateTime();
    var dataHora = new GlideDateTime(current.getValue('data_hora'));
    var difMs = dataHora.getNumericValue() - agora.getNumericValue();
    var horas = difMs / (1000 * 60 * 60);
    if (horas < 24) {
        current.setValue('penalidade', true);
    }
    gs.eventQueue('agendamento.cancelado', current, current.getValue('cliente'), '');
})(current, previous);
```

### 5.5 Business Rule — eventos de criação/conclusão/esgotamento

```javascript
// BR after insert em x_espaco_agendamento -> agendamento.criado
gs.eventQueue('agendamento.criado', current, current.getValue('cliente'), '');

// BR after update em x_espaco_agendamento (status -> concluido) -> sessao.concluida
// Condition: current.status.changesTo('concluido')
gs.eventQueue('sessao.concluida', current, current.getValue('cliente'), '');

// BR after update em x_espaco_pacote (status -> esgotado) -> pacote.esgotado
// Condition: current.status.changesTo('esgotado')
gs.eventQueue('pacote.esgotado', current, current.getValue('cliente'), '');
```

---

## 6. Testes ATF

Crie os testes em **ATF → Tests**:

### Teste 1 — Conflito de horário bloqueado (RN-02)
1. Record Insert: cria agendamento A (profissional P, data D).
2. Record Insert: cria agendamento B (mesmo P, mesma D) → **deve falhar** (assert insert rejeitado).

### Teste 2 — Dedução sem saldo bloqueada (RN-03)
1. Cria pacote com total_sessoes=1, sessoes_utilizadas=1.
2. Run Server Side Script: `new PacoteEntity(gr).deduzirSessao()` → assert retorno `false`.

### Teste 3 — Agendamento sem consentimento bloqueado (RN-01)
1. Cria cliente com consentimento_lgpd=false.
2. Tenta inserir agendamento → assert insert rejeitado.

### Exemplo de Server Side Script Step (ATF)

```javascript
(function(outputs, steps, stepResult, assertEqual) {
    var gr = new GlideRecord('x_espaco_pacote');
    gr.get(steps('criar_pacote').record_id);
    var ok = new PacoteEntity(gr).deduzirSessao();
    assertEqual({ name: 'sem saldo bloqueado', shouldbe: false, value: ok });
})(outputs, steps, stepResult, assertEqual);
```

---

## 7. Critérios de Aceite

- [ ] Impossível criar 2 agendamentos do mesmo profissional no mesmo horário (RN-02).
- [ ] Impossível deduzir sessão de pacote sem saldo (RN-03).
- [ ] Agendamento bloqueado se cliente sem consentimento LGPD (RN-01).
- [ ] Cancelamento < 24h marca penalidade (RN-04).
- [ ] Pacote esgotado altera status e emite evento (RN-05).
- [ ] 5 eventos de domínio registrados e disparados.
- [ ] 3 testes ATF passando.

---

## 8. Checklist

```
[ ] PacoteEntity.deduzirSessao (RN-03/RN-05)
[ ] AgendamentoEntity.existeConflito (RN-02)
[ ] ClienteEntity.temConsentimentoValido (RN-01)
[ ] BR before Validar Agendamento (RN-01+RN-02)
[ ] BR Penalidade Cancelamento (RN-04)
[ ] BR eventos criado/concluido/esgotado
[ ] Eventos registrados no Event Registry
[ ] ATF: conflito, saldo, consentimento
[ ] Git commit
```

---

## 9. PROMPT PARA O CLAUDE CODE

```
Implemente a camada de domínio e regras de negócio da aplicação scoped x_espaco no ServiceNow,
seguindo DDD. Tecnologias: Script Includes (scoped, server-side, client_callable=false),
Business Rules (before/after), GlideRecord, Event Registry, ATF.

Crie Script Includes de domínio:
- ClienteEntity.temConsentimentoValido() -> RN-01
- AgendamentoEntity.existeConflito(profissionalId, dataHora, ignoraSysId) -> RN-02
- PacoteEntity.deduzirSessao() -> RN-03 (só permite se sessoes_utilizadas < total_sessoes)
  e marca status 'esgotado' ao atingir o total -> RN-05

Business Rules:
(a) before insert/update em x_espaco_agendamento: rejeita se cliente sem consentimento_lgpd (RN-01)
    e se houver conflito de horário do mesmo profissional (RN-02) via AgendamentoEntity.
(b) before update ao cancelar (status changesTo 'cancelado'): se faltar <24h para data_hora,
    marca penalidade=true (RN-04) e dispara evento agendamento.cancelado.
(c) after insert: dispara agendamento.criado.
(d) after update status->concluido: dispara sessao.concluida.
(e) after update em x_espaco_pacote status->esgotado: dispara pacote.esgotado.

Registre no Event Registry: cliente.cadastrado, agendamento.criado, agendamento.cancelado,
sessao.concluida, pacote.esgotado. Dispare via gs.eventQueue.

Padrão thin BR: Business Rules chamam os Script Includes de domínio.

Crie testes ATF: conflito de horário bloqueado, dedução de pacote sem saldo bloqueada,
agendamento sem consentimento bloqueado.

Critérios: RN-01 a RN-05 impostas e cobertas por ATF passando.
```
