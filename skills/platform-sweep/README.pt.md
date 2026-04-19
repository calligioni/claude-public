# Platform Sweep

## O que faz

Executa uma auditoria completa e paralela da plataforma em 5 trilhas simultâneas (UX, limpeza de código, segurança, dependências, performance), consolida achados em um relatório priorizado por severidade, e após aprovação do usuário, aplica automaticamente todas as correções em worktrees git isoladas.

Delega para skills especializados (`fulltest-skill`, `codebase-cleanup`, `tech-audit`, `cto`) e complementa com agentes customizados onde há gaps. Após a primeira execução bem-sucedida, gera automaticamente uma skill específica do projeto que encapsula o conhecimento adquirido (URLs, padrões recorrentes, checks customizados).

## Como invocar

```
/platform-sweep [--url <site-url>] [--tracks a,b,c,d,e | all] [--fix-mode auto|manual|report-only]
```

**Exemplos:**

- `/platform-sweep` — auditoria completa com correção automática
- `/platform-sweep --tracks security,deps` — apenas segurança e dependências
- `/platform-sweep --fix-mode report-only` — auditoria sem correções
- `/platform-sweep --url https://staging.conta.app` — URL customizada

## Quando usar

- **Auditoria completa da plataforma** — antes de releases importantes ou sprints de saúde técnica
- **Revisão de segurança e dependências** — quando há patches críticos ou CVEs anunciados
- **Identificar dead code e performance bottlenecks** — rotina trimestral de saúde do código
- **Validar stack técnico** — verificar EOL, deprecations e oportunidades de otimização
