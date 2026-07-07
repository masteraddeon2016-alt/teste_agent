# AGENTS.md — Agentes Bridge do Projeto Espaço Laser

Este documento descreve os **Agentes Bridge** selecionados para automação de tarefas de desenvolvimento, integração e deploy da aplicação scoped `x_espaco` no ServiceNow.

---

## Visão Geral

Os Agentes Bridge executam tarefas locais (MID Server / integrações on-premises, build, promoção de Update Sets, execução de scripts de automação e sincronização com Git). Cada agente tem responsabilidades e permissões de arquivo bem definidas para garantir isolamento e rastreabilidade.

| Agente | ID | Responsabilidade principal |
|--------|----|----------------------------|
| `localmachine` | `43fed37d-d7a7-4c34-9cc4-cdce81fdda48` | Build, sincronização Git e execução de tarefas de desenvolvimento |
| `localmachine2` | `ce9423e3-ab2c-457e-a1f6-62ff93fdfdbd` | Integrações externas (MID Server), notificações e deploy/CD |

---

## Agente: `localmachine`

### Objetivo
Responsável pelo ciclo de desenvolvimento local: sincronizar o repositório Git `teste_agent`, aplicar/exportar Update Sets, executar validações estáticas e disparar suítes de teste ATF.

### Responsabilidades
- Clonar/atualizar o repositório Git da aplicação scoped.
- Exportar e importar Update Sets entre a instância dev e o Git.
- Executar scripts de validação de convenções (nomenclatura `x_espaco`, escopo).
- Disparar execução de testes ATF via API.
- Gerar artefatos de build para promoção.

### Arquivos que PODE criar/modificar
- `x_espaco/src/**` (definições exportadas da app scoped)
- `docs/**`
- `workflow/**`
- `.gitignore`, `README.md`, `CLAUDE.md`, `AGENTS.md`
- `appsettings.example.json`, `.env.example`

### Arquivos PROIBIDOS
- `appsettings.json` (configuração real do próprio Agente Bridge)
- `.env` (segredos reais)
- Qualquer arquivo fora de `x_espaco/`, `docs/`, `workflow/`
- Credenciais, tokens ou chaves privadas

### Habilidades esperadas
- Git (clone, commit, push, branch, PR).
- ServiceNow Source Control e Update Sets.
- Execução de ATF via REST.
- Shell scripting para automação de build.

---

## Agente: `localmachine2`

### Objetivo
Responsável por integrações externas via MID Server (CRM, Financeiro, Gateway de Notificações), orquestração de deploy (CD) e promoção entre ambientes staging/prod.

### Responsabilidades
- Executar chamadas a APIs on-premises via MID Server.
- Suportar IntegrationHub Spokes de notificação (E-mail/SMS/WhatsApp).
- Promover Update Sets de staging para produção (estratégia rolling).
- Executar smoke tests pós-deploy.
- Monitorar disponibilidade das integrações.

### Arquivos que PODE criar/modificar
- `workflow/CD.md`, `workflow/RELEASE.md`
- `x_espaco/src/flow/**` (definições de flows exportadas)
- `x_espaco/src/sys_ws_definition/**` (integrações REST exportadas)
- Logs de deploy em `workflow/logs/**`

### Arquivos PROIBIDOS
- `appsettings.json` real do agente
- `.env` com segredos reais
- Código de domínio (`x_espaco/src/script_include/domain/**`) — somente `localmachine` altera domínio
- Testes ATF (`x_espaco/src/sys_atf_test/**`)

### Habilidades esperadas
- MID Server e IntegrationHub.
- Connection & Credential Alias (gestão segura de segredos).
- Promoção de Update Sets e rollback.
- Monitoramento e health checks.

---

## Fluxo de Comunicação entre Agentes

```
   Desenvolvimento (Claude Code)
            |
            v
   +--------------------+       git push / Update Set        +----------------------+
   |    localmachine    |----------------------------------->|   Repositório Git    |
   |  (build + testes)  |<-----------------------------------|     teste_agent      |
   +--------------------+       pull / validação             +----------------------+
            |
            | artefato validado + ATF verde
            v
   +--------------------+       promoção rolling             +----------------------+
   |    localmachine2   |----------------------------------->|  Staging -> Prod (SN) |
   |  (integrações/CD)  |       smoke tests + notificações   +----------------------+
            |
            v
   Integrações externas (CRM / Financeiro / Notificações via MID Server)
```

### Regras de coordenação
1. `localmachine` **sempre** valida e roda ATF antes de sinalizar artefato pronto.
2. `localmachine2` **só** promove artefatos com ATF verde e cobertura ≥80%.
3. Segredos trafegam exclusivamente via Credential Alias — nunca por arquivos versionados.
4. Conflitos de escopo de arquivos são resolvidos pela matriz de PROIBIDOS acima.
