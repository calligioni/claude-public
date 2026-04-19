# Ship — Implementação End-to-End de Features

## O que faz

O `/ship` é um skill disciplinado que leva uma feature de especificação até produção em 7 fases: detecção do projeto → spec de produto → spec técnica → plano de implementação → execução com swarm de agentes → QA com ciclo de correção → documentação. Cada fase produz artefatos persistentes. Todo o progresso fica em `.claude/ship/{feature-slug}/` permitindo retomar após context clears com `/ship --resume`.

Usa decisões de design baseadas em pesquisa Anthropic: avaliadores independentes para detectar viés de auto-avaliação (Phase 4.7), handoff estruturado em vez de compactação de contexto, e roteamento de modelos calibrado (haiku/sonnet/opus) por tipo de tarefa. Integra MCP para learnings persistentes que melhoram cada execução.

## Como invocar

```bash
/ship "Descrição da feature"
/ship "Ler .claude/ship/sprint-2/plan.md e executar"
/ship --resume
```

Exemplos:
- `/ship "Adicionar preferências de notificação com email e in-app"`
- `/ship --resume` (continua após context clear)
- `/ship --phase=qa` (apenas QA na execução atual)

## Quando usar

- **Implementar features médias-grandes** (5+ tarefas): automação end-to-end com review em duas fases evita retrabalho pós-QA
- **Projetos com histórico**: learnings capturados aceleram futuras features via model routing e fix patterns conhecidos
- **Equipes distribuídas**: swarm execution com isolamento de worktree permite paralelização sem conflitos; handoff estruturado documenta decisões
- **Especificações que evoluem**: hard-gates em Phase 1 e 2 (aprovação seção-por-seção) impedem re-trabalho
