# FASE 01 — Fundação da Aplicação Scoped e Modelo de Dados

> Projeto: **Espaço Laser** — Plataforma ServiceNow (Custom App scoped `x_espaco`)
> Duração estimada: **6 dias** (Semanas 1–2)
> Padrões: **Clean Architecture + DDD** adaptados ao ServiceNow

---

## 1. Objetivo

Criar a aplicação scoped `x_espaco` na plataforma ServiceNow, contendo:

- Modelo de dados completo (tabelas customizadas com campos, tipos, referências e índices).
- Roles de segurança scoped.
- Estrutura base de Script Includes organizada por camadas (Domínio, Aplicação, Infraestrutura).
- Repositório Git (`teste_agent`) vinculado para versionamento.

Esta fase é a **fundação** de todas as fases seguintes. Nenhuma regra de negócio, API ou tela é implementada aqui — apenas o esqueleto arquitetural e o modelo de persistência.

---

## 2. Pré-requisitos

| Item | Descrição |
|------|-----------|
| Instância ServiceNow | Instância dev com privilégios de admin (role `admin`) |
| Plugins | Service Portal, IntegrationHub, Flow Designer, Scripted REST API habilitados |
| Source Control | Repositório Git `teste_agent` acessível; credenciais em **Credential Alias** (NUNCA em texto claro) |
| Conhecimento | Studio, Table API, GlideRecord, Application Scopes |

> ⚠️ **Segurança:** Access tokens Git devem ser armazenados via `Connection & Credential Alias`. Nunca commitar tokens no código.

---

## 3. Modelo de Dados

### 3.1 Diagrama de Entidades (ASCII)

```
  x_espaco_cliente 1───────N x_espaco_agendamento N───────1 x_espaco_profissional
        │                          │
        │ 1                        │ N
        │                          │
        N                          1
  x_espaco_pacote            x_espaco_servico
```

### 3.2 Tabelas a Criar

#### `x_espaco_cliente`
| Campo | Tipo ServiceNow | Detalhes |
|-------|-----------------|----------|
| nome | String (100) | Obrigatório |
| email | String (100) | Dado pessoal |
| telefone | String (20) | Dado pessoal |
| consentimento_lgpd | True/False (Boolean) | Default false |
| data_cadastro | Glide Date/Time | Default now |
| ativo | True/False (Boolean) | Default true |

#### `x_espaco_servico`
| Campo | Tipo | Detalhes |
|-------|------|----------|
| nome | String (100) | Obrigatório |
| area_corporal | String (60) | Ex: axilas, pernas |
| duracao_minutos | Integer | Default 30 |
| preco | Currency (ou Integer) | Valor do serviço |

#### `x_espaco_profissional`
| Campo | Tipo | Detalhes |
|-------|------|----------|
| nome | String (100) | Obrigatório |
| especialidade | String (60) | |
| ativo | True/False | Default true |

#### `x_espaco_agendamento`
| Campo | Tipo | Detalhes |
|-------|------|----------|
| cliente | Reference → x_espaco_cliente | Obrigatório |
| servico | Reference → x_espaco_servico | Obrigatório |
| profissional | Reference → x_espaco_profissional | Obrigatório |
| data_hora | Glide Date/Time | Obrigatório |
| status | Choice | novo, confirmado, concluido, cancelado, reagendado |
| penalidade | True/False | Default false (usado na Fase 2) |

#### `x_espaco_pacote`
| Campo | Tipo | Detalhes |
|-------|------|----------|
| cliente | Reference → x_espaco_cliente | Obrigatório |
| total_sessoes | Integer | Obrigatório |
| sessoes_utilizadas | Integer | Default 0 |
| status | Choice | ativo, esgotado, expirado |

### 3.3 Índices de Banco

| Tabela | Campo(s) indexado(s) | Justificativa |
|--------|----------------------|---------------|
| x_espaco_agendamento | cliente | Busca por cliente |
| x_espaco_agendamento | data_hora | Busca de agenda / conflitos |
| x_espaco_pacote | cliente | Consulta de saldo |

> No Studio: **Tables → [tabela] → Database Indexes → New**.

---

## 4. Roles Scoped

| Role | Descrição |
|------|-----------|
| `x_espaco.admin` | Administração total do app |
| `x_espaco.gestor` | Dashboards, pacotes, configurações |
| `x_espaco.recepcionista` | Check-in, criação de clientes e agendamentos |
| `x_espaco.profissional` | Agenda e registro de sessões |
| `x_espaco.leitura` | Somente leitura (sem dados sensíveis — ver Fase 4) |

---

## 5. Estrutura de Script Includes (Clean Architecture / DDD)

Crie os Script Includes como **esqueletos** (métodos vazios documentados). A implementação real ocorre na Fase 2/3.

```
x_espaco (scoped app)
│
├── Domínio (client_callable = false)
│   ├── ClienteEntity          // Regras e invariantes do agregado Cliente
│   ├── AgendamentoEntity       // Regras do agregado Agendamento
│   ├── PacoteEntity            // Controle de saldo de sessões
│   ├── ServicoEntity           // Value object / referência
│   └── ProfissionalEntity      // Agregado Profissional
│
├── Aplicação (casos de uso)
│   ├── CadastrarClienteUseCase
│   ├── AgendarSessaoUseCase
│   ├── RegistrarSessaoUseCase
│   └── GerenciarPacoteUseCase
│
└── Infraestrutura (repositórios)
    ├── ClienteRepository       // GlideRecord de x_espaco_cliente
    ├── AgendamentoRepository   // GlideRecord de x_espaco_agendamento
    └── PacoteRepository        // GlideRecord de x_espaco_pacote
```

### 5.1 Exemplo de esqueleto — `ClienteEntity` (Domínio)

```javascript
// Script Include: ClienteEntity
// Camada: DOMÍNIO — encapsula regras e invariantes do agregado Cliente.
// client_callable = FALSE (uso apenas server-side)
var ClienteEntity = Class.create();
ClienteEntity.prototype = {
    initialize: function(gr) {
        // gr: GlideRecord de x_espaco_cliente (opcional)
        this.gr = gr || null;
    },

    /**
     * Verifica se o cliente possui consentimento LGPD válido.
     * Regra RN-01 (implementação completa na Fase 2).
     * @returns {boolean}
     */
    temConsentimentoValido: function() {
        // TODO Fase 2
        return this.gr ? this.gr.getValue('consentimento_lgpd') == 'true' : false;
    },

    type: 'ClienteEntity'
};
```

### 5.2 Exemplo de esqueleto — `ClienteRepository` (Infraestrutura)

```javascript
// Script Include: ClienteRepository
// Camada: INFRAESTRUTURA — acesso a dados via GlideRecord.
var ClienteRepository = Class.create();
ClienteRepository.prototype = {
    initialize: function() {
        this.TABLE = 'x_espaco_cliente';
    },

    findById: function(sysId) {
        var gr = new GlideRecord(this.TABLE);
        return gr.get(sysId) ? gr : null;
    },

    type: 'ClienteRepository'
};
```

---

## 6. Passo a Passo de Execução

1. **Studio → Create Application** → nome `Espaço Laser`, scope `x_espaco`.
2. Vincular ao **Source Control** (`teste_agent`) via Credential Alias.
3. Criar as 5 tabelas conforme a seção 3 (Studio → Create → Table).
4. Adicionar campos, tipos e reference fields.
5. Criar Choice lists para `status` de agendamento e pacote.
6. Criar os 3 índices de banco.
7. Criar as 5 roles scoped (Studio → Create → Role).
8. Criar os Script Includes esqueleto por camada (client_callable=false nos de domínio).
9. Commit inicial no Git.

---

## 7. Testes desta Fase

Como não há lógica, os testes são de **estrutura/smoke**:

```javascript
// Background Script (verificação manual)
['x_espaco_cliente','x_espaco_servico','x_espaco_profissional',
 'x_espaco_agendamento','x_espaco_pacote'].forEach(function(t){
    var gr = new GlideRecord(t);
    gs.info(t + ' existe: ' + gr.isValid());
});
```

Resultado esperado: todas as tabelas retornam `existe: true`.

---

## 8. Critérios de Aceite

- [ ] Aplicação scoped `x_espaco` criada e publicada.
- [ ] As 5 tabelas existem com todos os campos e tipos corretos.
- [ ] Reference fields entre agendamento/cliente/servico/profissional funcionando.
- [ ] Choice lists de status criadas.
- [ ] 3 índices de banco criados.
- [ ] 5 roles scoped criadas e atribuíveis.
- [ ] Script Includes esqueleto por camada criados (domínio com client_callable=false).
- [ ] Commit inicial realizado no repositório `teste_agent`.

---

## 9. Checklist de Conclusão

```
[ ] App scoped x_espaco publicada
[ ] x_espaco_cliente (6 campos)
[ ] x_espaco_servico (4 campos)
[ ] x_espaco_profissional (3 campos)
[ ] x_espaco_agendamento (6 campos + reference)
[ ] x_espaco_pacote (4 campos + reference)
[ ] Índices: agendamento.cliente, agendamento.data_hora, pacote.cliente
[ ] Roles: admin, gestor, recepcionista, profissional, leitura
[ ] Script Includes: Domínio (5), Aplicação (4), Infra (3)
[ ] Git commit inicial
```

---

## 10. PROMPT PARA O CLAUDE CODE

```
Implemente a fundação de uma aplicação ServiceNow scoped chamada 'Espaço Laser' com
namespace 'x_espaco'. Tecnologias: ServiceNow scoped application, Table API, GlideRecord,
Source Control (Git). Arquitetura: Clean Architecture + DDD adaptados ao ServiceNow.

Crie:
1. A aplicação scoped x_espaco vinculada ao repositório Git 'teste_agent' (credenciais
   via Credential Alias, nunca em texto claro).
2. Tabelas:
   - x_espaco_cliente (nome string, email string, telefone string, consentimento_lgpd
     boolean default false, data_cadastro glide_date_time default now, ativo boolean default true)
   - x_espaco_servico (nome string, area_corporal string, duracao_minutos integer default 30, preco currency)
   - x_espaco_profissional (nome string, especialidade string, ativo boolean default true)
   - x_espaco_agendamento (cliente reference->x_espaco_cliente, servico reference->x_espaco_servico,
     profissional reference->x_espaco_profissional, data_hora glide_date_time,
     status choice[novo,confirmado,concluido,cancelado,reagendado], penalidade boolean default false)
   - x_espaco_pacote (cliente reference->x_espaco_cliente, total_sessoes integer,
     sessoes_utilizadas integer default 0, status choice[ativo,esgotado,expirado])
3. Índices de banco: agendamento.cliente, agendamento.data_hora, pacote.cliente.
4. Roles scoped: x_espaco.admin, x_espaco.gestor, x_espaco.recepcionista, x_espaco.profissional, x_espaco.leitura.
5. Script Includes esqueleto organizados em camadas:
   - Domínio (client_callable=false): ClienteEntity, AgendamentoEntity, PacoteEntity, ServicoEntity, ProfissionalEntity
   - Aplicação: CadastrarClienteUseCase, AgendarSessaoUseCase, RegistrarSessaoUseCase, GerenciarPacoteUseCase
   - Infraestrutura: ClienteRepository, AgendamentoRepository, PacoteRepository
   Cada Script Include deve conter comentário indicando sua camada e responsabilidade.

Padrões: prefixo x_espaco em tudo, client_callable=false nos Script Includes de domínio.
Critérios de validação: as 5 tabelas existem com todos os campos/tipos, reference fields
funcionam, roles criadas, e commit inicial realizado no Git.
```
