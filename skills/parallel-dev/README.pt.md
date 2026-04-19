# parallel-dev

## O que faz

Orquestra desenvolvimento paralelo de features usando git worktrees e agentes especializados. Cria branches isoladas para múltiplas features, executa agentes em paralelo, monitora progresso via CI, e faz merge progressivo quando tudo passa nos testes. Delega automaticamente para CLI `ao` quando disponível.

Útil para implementar múltiplas features simultaneamente em projetos que suportam isolamento via git (sem conflitos de arquivo). Controla dependências entre features, reexecuta automaticamente quando CI falha, e escalona bloqueios para humanos.

## Como invocar

```bash
/parallel-dev
```

Apresenta um formulário interativo para configurar slots (agente, workspace, rastreamento, notificações). Depois pede as features em markdown:

```markdown
## Feature: Autenticação
type: backend
- Login OAuth2 Google/GitHub
- Gerenciamento de sessão Redis
- Refresh de JWT

## Feature: Dashboard
type: frontend
dependsOn: [autenticacao]
- Cards de stats em tempo real
- Gráficos com Recharts
- Modo escuro
```

Alternativas:
- `/parallel-dev --from-cpo` — lê stages de `master-project.json`
- `/parallel-dev --config arquivo.json` — carrega features de arquivo
- `/parallel-dev status` — mostra dashboard sem criar novos agentes
- `/parallel-dev resume` — continua sessão interrompida
- `/parallel-dev --quick` — pula prompt interativo, usa defaults

## Quando usar

- Implementar **múltiplas features independentes** em paralelo (reduz tempo de delivery)
- Features com **dependências claras** (autenticação → dashboard → integração)
- Projeto com **CI/CD configurado** (reage automaticamente a falhas de teste)
- Equipes que precisam **progresso visível e monitorável** (dashboard em tempo real, notificações Telegram/Slack)
