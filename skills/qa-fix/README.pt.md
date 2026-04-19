# QA Fix

## O que faz

Lê issues abertos no banco de dados de QA, prioriza por severidade e investiga o codebase para implementar correções. O skill marca issues como `assigned` → `in_progress` → `pr_created` (ou resolvido), documentando cada etapa da investigação e fix aplicado.

Executa de forma totalmente autônoma: processa todos os issues correspondentes em uma única execução sem pausas, aplica fixes diretos no código, atualiza status no BD e finaliza com um sumário.

## Como invocar

```
/qa-fix                          # Fixa issues P0 e P1 abertos
/qa-fix --issue 42               # Fixa issue específico por ID
/qa-fix --severity p0            # Apenas issues críticos
/qa-fix --severity p0,p1,p2      # Issues P0 até P2
/qa-fix --limit 5                # Máximo 5 issues
/qa-fix --dry-run                # Preview sem aplicar mudanças
```

## Quando usar

- **Issues críticos (P0) em produção** que causam bloqueio de usuários
- **Bugs de API** como erros 500, validação incorreta, queries com problema
- **Issues de permissão** onde checagem de acesso está faltando
- **Bugs de UI/navegação** que impedem fluxo do usuário ou carregamento de dados
