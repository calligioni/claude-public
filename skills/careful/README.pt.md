# Careful

## O que faz

Ativa um hook PreToolUse que avisa antes de comandos bash destrutivos — `rm -rf`, `DROP TABLE`, `DELETE FROM`, `TRUNCATE`, `git push --force`, `git reset --hard`, `git branch -D`, `kubectl delete`, `docker system prune`. O hook usa um state file como gate: enquanto o modo não é ativado, ele faz no-op (zero overhead). Exceções seguras (`rm -rf node_modules`, `.next`, `dist`, etc.) passam sem aviso.

## Como invocar

```
/careful
```

Para desligar:
```
/uncareful
```

## Quando usar

- Antes de mexer em produção (deploys, migrações, hotfixes)
- Sessões longas de debugging onde a fadiga pode levar a comandos destrutivos acidentais
- Trabalhando em infra compartilhada (VPS, K8s, bancos de dados)
- Combinado com `/freeze` para guardrails completos de destruição + escopo de edição
