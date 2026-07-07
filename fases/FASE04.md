# FASE 04 — Conformidade LGPD, Segurança e Auditoria

> Projeto: **Espaço Laser** — ServiceNow scoped `x_espaco`
> Duração estimada: **7 dias** (Semanas 6–8)
> Depende de: **FASE 01, 02, 03** concluídas
> Abordagem: **Privacy by Design**

---

## 1. Objetivo

Implementar controles completos de **LGPD/GDPR**, **ACLs** por role e campo, **auditoria** de dados sensíveis, **anonimização/exclusão** de dados do titular e **registro de consentimento** com finalidade e versão.

---

## 2. Pré-requisitos

- FASE 03 concluída (APIs).
- Envolvimento do DPO para definição de finalidades e termo de consentimento.
- Plugins: Flow Designer, Audit.

---

## 3. Modelo de Segurança (ACLs)

### 3.1 Matriz de Acesso

| Tabela / Campo | admin | gestor | recepcionista | profissional | leitura |
|----------------|:-----:|:------:|:-------------:|:------------:|:-------:|
| x_espaco_cliente (read) | ✅ | ✅ | ✅ | ✅ | ✅ |
| x_espaco_cliente (write) | ✅ | ✅ | ✅ | ❌ | ❌ |
| cliente.email (read) | ✅ | ✅ | ✅ | ✅ | ❌ |
| cliente.telefone (read) | ✅ | ✅ | ✅ | ✅ | ❌ |
| x_espaco_agendamento (write) | ✅ | ✅ | ✅ | ✅ | ❌ |
| x_espaco_pacote (write) | ✅ | ✅ | ❌ | ❌ | ❌ |

Criar ACLs **record-level** e **field-level** (`x_espaco_cliente.email`, `x_espaco_cliente.telefone`) restringindo leitura da role `x_espaco.leitura`.

---

## 4. Registro de Consentimento LGPD

Adicionar campos ao `x_espaco_cliente` (ou tabela `x_espaco_consentimento` conforme a análise):

| Campo | Tipo | Descrição |
|-------|------|-----------|
| consentimento_lgpd | Boolean | Aceite ativo |
| consentimento_data | Glide Date/Time | Data/hora do aceite |
| consentimento_versao | String | Versão do termo aceito |
| consentimento_finalidade | String | Finalidade do tratamento |

---

## 5. Anonimização (RN-05 / Direito do Titular)

### 5.1 `AnonimizacaoService`

```javascript
var AnonimizacaoService = Class.create();
AnonimizacaoService.prototype = {
    initialize: function() {},

    /**
     * Anonimiza dados pessoais do cliente mantendo integridade referencial
     * dos agendamentos históricos. Registra a operação em log.
     */
    anonimizarCliente: function(clienteId) {
        var gr = new GlideRecord('x_espaco_cliente');
        if (!gr.get(clienteId)) return false;

        var hash = new GlideDigest().getSHA256Base64(clienteId + gs.nowDateTime());
        gr.setValue('nome', 'ANONIMIZADO-' + hash.substr(0, 8));
        gr.setValue('email', 'anonimizado@lgpd.local');
        gr.setValue('telefone', '');
        gr.setValue('consentimento_lgpd', false);
        gr.setValue('ativo', false);
        gr.update();

        new AuditoriaAcessoService().registrar('ANONIMIZACAO', 'x_espaco_cliente', clienteId,
            'Dados pessoais anonimizados por solicitação do titular (LGPD).');
        gs.eventQueue('lgpd.dados_anonimizados', gr, clienteId, '');
        return true;
    },
    type: 'AnonimizacaoService'
};
```

### 5.2 `AuditoriaAcessoService`

```javascript
var AuditoriaAcessoService = Class.create();
AuditoriaAcessoService.prototype = {
    initialize: function() { this.TABLE = 'x_espaco_log_auditoria'; },

    registrar: function(acao, tabela, registroId, detalhe) {
        var gr = new GlideRecord(this.TABLE);
        gr.initialize();
        gr.setValue('acao', acao);
        gr.setValue('tabela', tabela);
        gr.setValue('registro_id', registroId);
        gr.setValue('usuario', gs.getUserID());
        gr.setValue('detalhe', detalhe);
        gr.setValue('data_hora', new GlideDateTime());
        return gr.insert();
    },
    type: 'AuditoriaAcessoService'
};
```

> Criar tabela `x_espaco_log_auditoria` (acao, tabela, registro_id, usuario, detalhe, data_hora).

---

## 6. Auditoria de Campos (Field Auditing)

Ativar **audit=true** nos campos sensíveis de `x_espaco_cliente` (email, telefone, consentimento_lgpd) e em `x_espaco_agendamento.status`. Isso alimenta `sys_audit` (RNF-07).

---

## 7. Flow de Exclusão/Anonimização com Aprovação

Criar Flow **"Solicitação de Exclusão LGPD"**:
1. Trigger: registro criado em `x_espaco_solicitacao_titular` (tipo=exclusao).
2. Ação: **Ask for Approval** ao grupo/role DPO (`x_espaco.dpo` ou `x_espaco.admin`).
3. Se aprovado → chamar `AnonimizacaoService.anonimizarCliente()` via Script Action.
4. Registrar log e notificar titular.

---

## 8. Validação de Entrada nas APIs

Reforçar sanitização nos resources da Fase 3: rejeitar caracteres inválidos em email/telefone, validar tipos e tamanho. Usar `GlideStringUtil` para escape.

---

## 9. Segurança de Credenciais

- Tokens/credenciais de integração via **Connection & Credential Alias**.
- HTTPS/TLS obrigatório em todas as chamadas REST externas.

---

## 10. Testes

### 10.1 ATF — ACL field-level
1. Impersonar usuário com role `x_espaco.leitura`.
2. Ler cliente → assert que `email`/`telefone` **não** são visíveis.

### 10.2 ATF — Anonimização
1. Criar cliente com agendamento histórico.
2. Executar `AnonimizacaoService.anonimizarCliente(id)`.
3. Assert: nome/email anonimizados, agendamento histórico ainda referencia o cliente, log de auditoria criado.

### 10.3 Auditoria
- Alterar email de um cliente → verificar registro em `sys_audit`.

---

## 11. Critérios de Aceite

- [ ] Acesso a dados pessoais restrito por role (RNF-06/RNF-08).
- [ ] Role `leitura` não visualiza email/telefone (field ACL).
- [ ] Solicitação de exclusão anonimiza dados mantendo histórico (RN-05).
- [ ] Alterações em dados sensíveis registradas em auditoria (RNF-07/RNF-09).
- [ ] Consentimento obrigatório com finalidade e versão registrados.
- [ ] Flow de aprovação DPO funcionando.
- [ ] Credenciais em Credential Alias, HTTPS obrigatório.

---

## 12. Checklist

```
[ ] ACLs record-level (cliente, agendamento, pacote) por role
[ ] ACLs field-level (cliente.email, cliente.telefone) restringindo leitura
[ ] Campos de consentimento (data, versao, finalidade)
[ ] Tabela x_espaco_log_auditoria
[ ] AnonimizacaoService.anonimizarCliente
[ ] AuditoriaAcessoService.registrar
[ ] Field auditing (audit=true) em campos sensíveis
[ ] Flow Solicitação de Exclusão LGPD com aprovação DPO
[ ] Validação/sanitização nas APIs
[ ] ATF: field ACL, anonimização, auditoria
[ ] Git commit
```

---

## 13. PROMPT PARA O CLAUDE CODE

```
Implemente os controles de conformidade LGPD/GDPR, segurança e auditoria da aplicação scoped
x_espaco no ServiceNow, adotando privacy by design. Tecnologias: ACLs (record e field level),
Audit (sys_audit / field auditing), Script Includes, Business Rules, Flow Designer, GlideDigest.

Crie:
1. ACLs record-level para x_espaco_cliente, x_espaco_agendamento, x_espaco_pacote restringindo
   leitura/escrita conforme roles (x_espaco.admin, gestor, recepcionista, profissional, leitura).
   ACLs field-level em cliente.email e cliente.telefone bloqueando leitura para role leitura.
2. Campos de consentimento em x_espaco_cliente: consentimento_data (glide_date_time),
   consentimento_versao (string), consentimento_finalidade (string). Consentimento obrigatório
   e registrado com finalidade e versão.
3. Tabela x_espaco_log_auditoria (acao, tabela, registro_id, usuario, detalhe, data_hora).
4. Script Include AnonimizacaoService.anonimizarCliente(clienteId): substitui dados pessoais
   por valores anonimizados/hash (GlideDigest SHA256), mantém integridade referencial dos
   agendamentos históricos, registra log e dispara evento lgpd.dados_anonimizados (RN-05).
5. Script Include AuditoriaAcessoService.registrar(acao, tabela, registroId, detalhe) que grava
   em x_espaco_log_auditoria com usuário e data/hora.
6. Ative field auditing (audit=true) nos campos sensíveis (email, telefone, consentimento_lgpd,
   agendamento.status) para trilha em sys_audit (RNF-07).
7. Validação/sanitização de entrada nas Scripted REST APIs contra dados malformados.
8. Flow no Flow Designer 'Solicitação de Exclusão LGPD' com aprovação do DPO que, ao aprovar,
   chama AnonimizacaoService.anonimizarCliente e notifica o titular.

Garanta HTTPS e credenciais em Connection & Credential Alias (nunca texto claro).

Critérios: role leitura não vê email/telefone; anonimização remove dados mantendo histórico;
alterações em dados sensíveis aparecem na auditoria; consentimento obrigatório com finalidade e versão.
```
