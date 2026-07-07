# FASE 06 — Interface, Dashboard, Testes e Deploy

> Projeto: **Espaço Laser** — ServiceNow scoped `x_espaco`
> Duração estimada: **10 dias** (Semanas 9–12)
> Depende de: **FASE 01–05** concluídas

---

## 1. Objetivo

Entregar a **camada de apresentação** (telas / Widgets no Service Portal / UI Builder), o **Dashboard** de indicadores, a **suíte de testes ATF** de ponta a ponta (cobertura ≥80% das regras críticas) e o **pipeline CI/CD** com deploy até produção.

---

## 2. Pré-requisitos

- FASE 05 concluída.
- Plugins: Service Portal / UI Builder (Now Experience), ATF, Performance Analytics/Reports.
- Repositório Git `teste_agent` + GitHub Actions configurável.
- Ambientes: **dev → staging → prod**.

---

## 3. Telas / Widgets

Todas consomem as **Scripted REST APIs da Fase 3** e respeitam **ACLs/roles** (Fase 4).

| # | Tela | Rota | Componentes | Role |
|---|------|------|-------------|------|
| 1 | Lista de Clientes | `/clientes` | Tabela paginada, busca, botão Novo | recepcionista/gestor |
| 2 | Cadastro de Cliente | `/clientes/novo` | Form + **checkbox LGPD obrigatório** + Salvar | recepcionista |
| 3 | Agenda | `/agenda` | Calendário, filtro por profissional, modal de agendamento | recepcionista/profissional |
| 4 | Detalhe do Agendamento | `/agenda/:id` | Form, histórico, botão **Concluir** (registra sessão RF-06) | profissional |
| 5 | Pacotes do Cliente | `/clientes/:id/pacotes` | Lista, **barra de progresso de saldo**, botão Ajustar | gestor |
| 6 | Dashboard | `/dashboard` | Cards KPI, gráficos de ocupação e faturamento (RF-09/RF-17) | gestor |

### 3.1 Exemplo — Widget Cadastro de Cliente (Server Script)

```javascript
// Server Script do Widget espacolaser_cadastro_cliente
(function() {
    if (input && input.action === 'salvar') {
        if (!input.consentimentoLgpd) {
            data.erro = 'É obrigatório o aceite do termo LGPD.';
            return;
        }
        var out = new CadastrarClienteUseCase().execute({
            nome: input.nome, email: input.email,
            telefone: input.telefone, consentimentoLgpd: true
        });
        data.sucesso = true;
        data.clienteId = out.sys_id;
    }
})();
```

### 3.2 Exemplo — Widget Cadastro (Client Script)

```javascript
api.controller = function($scope) {
    var c = this;
    c.form = { nome: '', email: '', telefone: '', consentimentoLgpd: false };
    c.salvar = function() {
        if (!c.form.consentimentoLgpd) { c.erro = 'Aceite o termo LGPD.'; return; }
        c.data.action = 'salvar';
        angular.extend(c.data, c.form);
        c.server.update().then(function(r) {
            if (r.sucesso) c.msg = 'Cliente cadastrado!';
            else c.erro = r.erro;
        });
    };
};
```

### 3.3 Dashboard — KPIs

Usar **GlideAggregate** para performance:

```javascript
// Ocupação: sessões concluídas por profissional
var ga = new GlideAggregate('x_espaco_agendamento');
ga.addQuery('status', 'concluido');
ga.groupBy('profissional');
ga.addAggregate('COUNT');
ga.query();
// Faturamento: soma preço dos serviços de agendamentos concluídos no período
```

Indicadores: **Taxa de ocupação por profissional**, **sessões realizadas por período**, **faturamento por período**, **pacotes esgotados**.

---

## 4. Suíte de Testes ATF (E2E — cobertura ≥80%)

| Teste | Fluxo | Assert |
|-------|-------|--------|
| T1 | Cadastro cliente c/ consentimento | Cliente criado, consentimento=true |
| T2 | Cadastro sem consentimento | Bloqueado / erro |
| T3 | Agendar sessão sem conflito | 201 criado |
| T4 | Agendar sessão com conflito | 409 rejeitado (RN-02) |
| T5 | Registrar sessão concluída | status=concluido, evento sessao.concluida |
| T6 | Deduzir pacote sem saldo | bloqueado (RN-03) |
| T7 | Anonimização | dados anonimizados, histórico preservado |
| T8 | API paginação | meta.total e limit corretos |
| T9 | ACL field-level | role leitura não vê email/telefone |
| T10 | Performance API | resposta < 2s |

Executar via **ATF Test Suite** agrupando os testes das Fases 2–6.

---

## 5. Pipeline CI/CD (GitHub Actions + Update Sets)

### 5.1 Estratégia

```
dev  ──commit/PR──►  GitHub (teste_agent)
                         │
                 GitHub Actions
                 ├─ Lint / validação
                 ├─ Aplicar Update Set em STAGING
                 ├─ Executar ATF Test Suite (via API sn_atf)
                 └─ Se verde ─► Promover Update Set para PROD (rolling)
```

### 5.2 Exemplo `.github/workflows/deploy.yml`

```yaml
name: CI-CD Espaco Laser
on:
  push:
    branches: [ main ]
jobs:
  build-test-deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Apply to Staging (Update Set)
        run: |
          curl -s -u "$SN_USER:$SN_PASS" -X POST \
            "$SN_STAGING/api/now/table/sys_update_set" -d @update_set.json
        env:
          SN_USER: ${{ secrets.SN_USER }}
          SN_PASS: ${{ secrets.SN_PASS }}
          SN_STAGING: ${{ secrets.SN_STAGING_URL }}
      - name: Run ATF Suite
        run: |
          curl -s -u "$SN_USER:$SN_PASS" -X POST \
            "$SN_STAGING/api/sn_cicd/testsuite/run?test_suite_sys_id=$ATF_SUITE"
        env:
          SN_USER: ${{ secrets.SN_USER }}
          SN_PASS: ${{ secrets.SN_PASS }}
          ATF_SUITE: ${{ secrets.ATF_SUITE_ID }}
      - name: Promote to Prod
        if: success()
        run: echo "Promover Update Set aprovado para PROD (rolling)"
```

> ⚠️ Secrets (`SN_USER`, `SN_PASS`, `SN_STAGING_URL`, `ATF_SUITE_ID`) em **GitHub Secrets** — nunca em texto claro.

---

## 6. Testes de Performance (RNF-06/RNF-04)

- Medir tempo de resposta dos 7 endpoints com carga simulada → alvo **< 2s** (API) e **< 3s** (portal).
- Verificar índices (Fase 1) e uso de GlideAggregate nos dashboards.

---

## 7. Critérios de Aceite

- [ ] As 6 telas implementadas e navegáveis conforme rotas.
- [ ] Cadastro exige consentimento LGPD obrigatório.
- [ ] Dashboard exibe ocupação e faturamento corretos.
- [ ] Suíte ATF passa com cobertura ≥80% das regras críticas.
- [ ] Pipeline CI/CD promove dev→staging→prod com ATF automático.
- [ ] Respostas de API < 2s; portal < 3s.
- [ ] Deploy em produção realizado com sucesso (disponibilidade ≥99%).

---

## 8. Checklist

```
[ ] Widget Lista de Clientes (/clientes)
[ ] Widget Cadastro de Cliente com consentimento LGPD (/clientes/novo)
[ ] Widget Agenda com calendário e filtro (/agenda)
[ ] Widget Detalhe do Agendamento + Concluir (/agenda/:id)
[ ] Widget Pacotes com barra de saldo (/clientes/:id/pacotes)
[ ] Dashboard KPIs com GlideAggregate (/dashboard)
[ ] ATF Test Suite (T1–T10) cobertura ≥80%
[ ] .github/workflows/deploy.yml (dev->staging->prod)
[ ] Secrets em GitHub Secrets
[ ] Testes de performance < 2s API
[ ] Deploy em produção
[ ] Git commit final
```

---

## 9. PROMPT PARA O CLAUDE CODE

```
Implemente a camada de apresentação, dashboard, testes e deploy da aplicação scoped x_espaco no
ServiceNow. Tecnologias: Service Portal / UI Builder (Now Experience), Performance Analytics/Reports,
ATF, Source Control (Git), GitHub Actions, Update Sets.

Crie as telas (widgets), todas consumindo as Scripted REST APIs da Fase 3 e respeitando ACLs/roles:
1. Lista de Clientes (/clientes): tabela paginada, filtro/busca, botão Novo.
2. Cadastro de Cliente (/clientes/novo): formulário com checkbox obrigatório de consentimento LGPD
   (bloqueia salvar sem aceite) e botão Salvar (chama CadastrarClienteUseCase).
3. Agenda (/agenda): calendário de agendamentos, filtro por profissional, modal de agendamento.
4. Detalhe do Agendamento (/agenda/:id): formulário, histórico e botão Concluir (registra sessão RF-06,
   deduz pacote via RegistrarSessaoUseCase).
5. Pacotes do Cliente (/clientes/:id/pacotes): lista, barra de progresso de saldo, botão Ajustar.
6. Dashboard (/dashboard): cards de KPI e gráficos de ocupação e faturamento (RF-09/RF-17) usando GlideAggregate.

Implemente uma suíte ATF cobrindo ponta a ponta: cadastro com consentimento, cadastro sem consentimento
bloqueado, agendamento sem/ com conflito (409), registro de sessão, dedução de pacote sem saldo bloqueada,
anonimização, paginação de API, ACL field-level, performance <2s — atingindo cobertura mínima de 80% das
regras críticas. Agrupe em um ATF Test Suite.

Configure o pipeline CI/CD: repositório Git teste_agent com GitHub Actions (.github/workflows/deploy.yml)
que valida, aplica Update Set em staging, executa o ATF Test Suite via API sn_cicd e, se verde, promove
para produção (estratégia rolling). Secrets em GitHub Secrets (nunca em texto claro).

Execute testes de performance garantindo respostas de API < 2s (RNF-04) e portal < 3s.

Critérios: 6 telas funcionam e navegáveis conforme rotas; dashboard exibe indicadores corretos; suíte ATF
passa com cobertura ≥80%; pipeline promove até produção com sucesso.
```
