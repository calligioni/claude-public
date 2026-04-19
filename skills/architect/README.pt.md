# architect

## O que faz

Orquestra mudanças arquiteturais multi-feature usando agentes paralelos em worktrees. Implementa N features independentes simultaneamente, depois verifica (typecheck + build), revisa (segurança, tipos, padrões) e faz commit em lote. Ideal para refatorações, migrações de config e mudanças cross-cutting que podem ser paralelizadas.

## Como invocar

```
/architect implement the 5 action items from research.md
/architect evolve the auth module: add JWT refresh, add rate limiting, add audit logging
/architect from plan.md
```

Aceita plano inline, arquivo markdown ou referência a output anterior.

## Quando usar

- **Refatorações arquiteturais** com múltiplos features independentes
- **Migrações de configuração** que afetam vários módulos em paralelo
- **Multi-concern changes** que podem ser implementadas simultaneamente
- **Grandes planos** que precisam de orquestração, validação e review antes do merge
