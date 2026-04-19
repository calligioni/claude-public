# Revert Track

## O que faz

Reverte uma unidade lógica de trabalho — uma feature, fase de deep-plan ou intervalo manual de commits — como uma operação única e limpa. Identifica todos os commits pertencentes a um track e os reverte em conjunto, preservando o histórico via `git revert`.

Lê estado de `.parallel-dev-state.json`, `.deep-plan-state.json` e `/ship` para mapear features e commits automaticamente.

## Como invocar

```
/revert-track <feature-id | 'last' | commit-range> [--dry-run]
```

**Exemplos:**

- `/revert-track auth` — reverte a feature "auth"
- `/revert-track last` — reverte o último track completado
- `/revert-track abc1234..def5678` — reverte intervalo manual
- `/revert-track auth --dry-run` — mostra o que seria revertido

## Quando usar

- **Feature não funciona ou quebra produção** — reverte todos os commits da feature em uma única operação
- **Fase de deep-plan com erro** — desfaz a implementação inteira mantendo histórico
- **Commits acumulados sem lógica clara** — especifica intervalo manual para reverter
- **Validação antes de revert** — usa `--dry-run` para inspecionar impacto sem executar
