# Modelo de Dados — Espaço Laser (Tabelas scoped `x_espaco`)

Todas as tabelas são criadas no escopo `x_espaco` sobre a base de dados da instância ServiceNow. Cada tabela herda automaticamente os campos de sistema (`sys_id`, `sys_created_on`, `sys_updated_on`, `sys_created_by`, `sys_updated_by`). Campos de referência usam o tipo `Reference` do ServiceNow.

## 1. Diagrama Entidade-Relacionamento (ASCII)

```
   u_unidade 1───N u_profissional
      │ 1                 │ 1
      │                   │
      N                   N
   u_agendamento ────────┘
      │ N        │ N          │ 1:1
      │          │            ▼
      N          N         u_sessao
      │          │
      ▼          ▼
 u_cliente    u_servico
   │ 1   │ 1     │ N
   │     │       │
   N     N       N
 u_consentimento │  u_pacote (N:N u_servico)
   │              │ 1
 u_solicitacao_   │ N
   titular     u_pacote_cliente
                  │ N:1 u_cliente
```

## 2. Dicionário de Dados

### 2.1 `u_cliente`
Dados pessoais do cliente (dados sensíveis — LGPD).

| Campo | Tipo ServiceNow | Descrição | Observações |
|---|---|---|---|
| nome | String(120) | Nome completo | Obrigatório |
| cpf | String(14) | CPF | **Criptografado** (Field Encryption) |
| email | String(120) | E-mail de contato | ACL field-level |
| telefone | String(20) | Telefone/celular | ACL field-level |
| data_nascimento | Glide Date/Time | Data de nascimento | Dado pessoal |
| consentimento_lgpd | True/False | Consentimento ativo | Default false |
| ativo | True/False | Cliente ativo | Default true |

**Índices**: `sys_id` (PK), `email`, `cpf`. **Auditoria**: habilitada (field auditing).

### 2.2 `u_unidade`
| Campo | Tipo | Descrição |
|---|---|---|
| nome | String(120) | Nome da unidade/franquia |
| endereco | String(255) | Endereço |
| horario_abertura | String(50) | Horário de funcionamento |
| ativa | True/False | Unidade ativa |

**Índices**: `nome`.

### 2.3 `u_profissional`
| Campo | Tipo | Descrição |
|---|---|---|
| nome | String(120) | Nome do profissional |
| registro | String(40) | Registro profissional |
| user | Reference → sys_user | Vínculo com usuário ServiceNow |
| unidade | Reference → u_unidade | Unidade de atuação |
| ativo | True/False | Profissional ativo |

**Índices**: `unidade`, `user`.

### 2.4 `u_servico`
| Campo | Tipo | Descrição |
|---|---|---|
| nome | String(120) | Nome do serviço / área corporal |
| duracao_minutos | Integer | Duração padrão da sessão |
| descricao | String(255) | Descrição do serviço |

**Índices**: `nome`. Dado de referência — elegível a cache.

### 2.5 `u_pacote`
| Campo | Tipo | Descrição |
|---|---|---|
| nome | String(120) | Nome do pacote |
| qtd_sessoes | Integer | Quantidade de sessões incluídas |
| validade_meses | Integer | Vigência em meses |
| valor | Currency | Valor do pacote |

Relacionamento **N:N** com `u_servico` via tabela associativa `u_pacote_servico` (`pacote` Reference, `servico` Reference).

### 2.6 `u_pacote_cliente`
Instância de pacote adquirida por um cliente.

| Campo | Tipo | Descrição |
|---|---|---|
| cliente | Reference → u_cliente | Cliente titular |
| pacote | Reference → u_pacote | Pacote base |
| saldo_sessoes | Integer | Sessões restantes |
| data_inicio | Glide Date/Time | Início da vigência |
| data_expiracao | Glide Date/Time | Fim da vigência |
| status | Choice[ativo,esgotado,expirado] | Situação do pacote |

**Índices**: `cliente`, `status`, `data_expiracao`.

### 2.7 `u_agendamento`
| Campo | Tipo | Descrição |
|---|---|---|
| cliente | Reference → u_cliente | Cliente |
| profissional | Reference → u_profissional | Profissional aplicador |
| unidade | Reference → u_unidade | Unidade |
| servico | Reference → u_servico | Serviço/área |
| pacote_cliente | Reference → u_pacote_cliente | Pacote a debitar |
| data_hora | Glide Date/Time | Data/hora da sessão |
| status | Choice[agendado,confirmado,realizado,cancelado,no_show,reagendado] | Status |
| penalidade | True/False | Marcação de penalidade (RN-06) |

**Índices**: `cliente`, `data_hora`, composto (`profissional`,`data_hora`) para RN-02. **Auditoria**: histórico de status habilitado.

### 2.8 `u_sessao`
| Campo | Tipo | Descrição |
|---|---|---|
| agendamento | Reference → u_agendamento | Agendamento origem (1:1) |
| areas_tratadas | String(255) | Áreas corporais tratadas |
| parametros | String(500) | Parâmetros da aplicação |
| data_realizacao | Glide Date/Time | Data efetiva da sessão |

**Auditoria**: habilitada (dado sensível de saúde/estética).

### 2.9 `u_consentimento`
| Campo | Tipo | Descrição |
|---|---|---|
| cliente | Reference → u_cliente | Titular |
| finalidade | String(255) | Finalidade do tratamento |
| versao_termo | String(20) | Versão do termo aceito |
| data_consentimento | Glide Date/Time | Data do aceite |
| ativo | True/False | Consentimento ativo/revogado |

### 2.10 `u_solicitacao_titular`
| Campo | Tipo | Descrição |
|---|---|---|
| cliente | Reference → u_cliente | Titular solicitante |
| tipo | Choice[acesso,correcao,exclusao] | Tipo de solicitação |
| status | Choice[nova,em_analise,aprovada,rejeitada,concluida] | Status |
| data_solicitacao | Glide Date/Time | Data da solicitação |
| aprovador | Reference → sys_user | DPO responsável |

## 3. Constraints e Invariantes (reforçadas por Business Rules)

- **UNIQUE lógico** (`profissional`,`data_hora`) em `u_agendamento` para status ativos → RN-02.
- **CHECK lógico**: `u_pacote_cliente.saldo_sessoes >= 0` → RN-01.
- **FK obrigatórias**: `u_agendamento.cliente`, `.profissional`, `.unidade`, `.servico`.
- **Consentimento obrigatório**: insert em `u_agendamento` exige `cliente.consentimento_lgpd = true` → RN-07.

## 4. Índices Planejados

| Tabela | Índice | Justificativa |
|---|---|---|
| u_agendamento | (cliente) | Busca por cliente / RF-16 |
| u_agendamento | (data_hora) | Filtro de agenda diária |
| u_agendamento | (profissional, data_hora) | Detecção de conflito RN-02 |
| u_pacote_cliente | (cliente, status) | Consulta de saldo RF-07 |
| u_cliente | (email), (cpf) | Buscas de identificação |

## 5. Migrations Planejadas (ordem de criação)

1. `u_unidade`, `u_servico`, `u_pacote` (cadastros base sem dependências).
2. `u_pacote_servico` (associativa N:N).
3. `u_cliente` + criptografia de `cpf`, auditoria de campos.
4. `u_profissional` (referência a `u_unidade` e `sys_user`).
5. `u_pacote_cliente` (referências a `u_cliente`, `u_pacote`).
6. `u_agendamento` (todas as referências) + índices.
7. `u_sessao` (referência 1:1 a `u_agendamento`).
8. `u_consentimento`, `u_solicitacao_titular`.

Cada migration é versionada via Update Set / Source Control (Git `teste_agent`).

## 6. Estratégia de Seed (dados de exemplo)

- **Unidades**: 2 unidades ativas (ex.: "Espaço Laser Centro", "Espaço Laser Zona Sul").
- **Serviços**: Axila (15min), Pernas (45min), Virilha (20min), Rosto (10min).
- **Pacotes**: "Pacote 10 sessões Axila" (10 sessões, 12 meses), "Pacote Corpo Completo" (10 sessões, 18 meses).
- **Profissionais**: 3 profissionais vinculados às unidades.
- **Cliente demo** com consentimento LGPD ativo e 1 `u_pacote_cliente` com saldo 10.

Seed executado por script de fixture no escopo `x_espaco`, condicionado a ambiente ≠ produção.
