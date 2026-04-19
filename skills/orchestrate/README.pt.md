# /orchestrate — Meta-Orchestrador

## O que faz

`/orchestrate` compõe a biblioteca de 83 skills existentes em execuções end-to-end, nunca reimplementando. Sua lógica nova é apenas: refinamento de intenção, roteamento dinâmico, portais de aprovação, estado por fase, enforcement de orçamento e relatórios finais.

Executa uma máquina de estados de 9 fases: captura de intenção → refinamento → planejamento → aprovação → execução (com fan-out sequencial ou paralelo) → verificação → ship → deploy (sempre com portal) → relatório. Suporta routines agendadas, retomadas de execuções interrompidas e parada automática sob pressão de contexto (≥80%).

## Como invocar

```bash
/orchestrate "<intenção>"
```

**Modos:**
- `--gated` (padrão): portal em cada limite de fase, digite `go` para aprovar
- `--autonomous`: sem portais exceto gatilhos obrigatórios (deploy prod, ops destrutivas, migração DB, breach de orçamento)
- `--approve-at=plan,deploy`: portais granulares apenas nas fases listadas

**Exemplos:**
```bash
/orchestrate "implementar toggle de dark mode"

/orchestrate "checar estratégia GEO diariamente" --autonomous

/orchestrate "enviar mudanças não commitadas" --approve-at=plan,deploy

/orchestrate "pesquisa profunda mercado de browser agent" --budget=15

/orchestrate "rodar /chief-geo diariamente 8am BRT" --as-routine "0 8 * * *"

/orchestrate --resume 2026-04-17-abc123

/orchestrate --list
```

## Quando usar

- **Feature end-to-end**: intent → plan → code → verify → commit → deploy, com aprovações em portais críticos
- **Releases e deploys**: automatiza sequência de review, testes e deploy com hard-gates antes de produção
- **Pesquisa + build**: combina `/deep-research` + `/deep-plan` + execução
- **Rotinas agendadas**: registra como Routine para execução contínua (sem gates interativas; gates críticas usam Slack/Discord)

**Restrições v1:** ExampleProject only, orçamento $10 warn/$50 cap (sobrescritível), senha de aprovação é a palavra literal `go`.

# O que faz

`/orchestrate` compõe a biblioteca de 83 skills existentes em execuções end-to-end, nunca reimplementando. Sua lógica nova é apenas: refinamento de intenção, roteamento dinâmico, portais de aprovação, estado por fase, enforcement de orçamento e relatórios finais.

Executa uma máquina de estados de 9 fases: captura de intenção → refinamento → planejamento → aprovação → execução (com fan-out sequencial ou paralelo) → verificação → ship → deploy (sempre com portal) → relatório. Suporta routines agendadas, retomadas de execuções interrompidas e parada automática sob pressão de contexto (≥80%).

## Como invocar

```bash
/orchestrate "<intenção>"
```

**Modos:**
- `--gated` (padrão): portal em cada limite de fase, digite `go` para aprovar
- `--autonomous`: sem portais exceto gatilhos obrigatórios (deploy prod, ops destrutivas, migração DB, breach de orçamento)
- `--approve-at=plan,deploy`: portais granulares apenas nas fases listadas

**Exemplos:**
```bash
/orchestrate "implementar toggle de dark mode"

/orchestrate "checar estratégia GEO diariamente" --autonomous

/orchestrate "enviar mudanças não commitadas" --approve-at=plan,deploy

/orchestrate "pesquisa profunda mercado de browser agent" --budget=15

/orchestrate "rodar /chief-geo diariamente 8am BRT" --as-routine "0 8 
