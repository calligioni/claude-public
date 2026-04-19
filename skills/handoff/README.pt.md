# Handoff — Checkpoint de Contexto

## O que faz

Cria um checkpoint durável antes de um `/clear` ou compactação. Anexa uma entrada de progresso no doc de plano do projeto (`docs/*-plan.md`, `PLAN.md`, etc.), faz commit + push, e imprime um bloco de retomada que o `/primer` consegue consumir na próxima sessão. É o produtor; `/primer` é o consumidor.

Resolve o problema de perder contexto quando a janela enche no meio de uma task longa: em vez de reconstruir estado do zero depois do `/clear`, o próximo sessão lê um arquivo e retoma em 3 passos.

## Como invocar

```
/handoff [caminho-do-plano.md]
```

Exemplos:
- `/handoff` — detecta o doc de plano automaticamente
- `/handoff docs/infra-separation-plan.md` — força um doc específico
- "checkpoint this before I clear" — trigger em linguagem natural

## Quando usar

- Contexto em 85%+ e a task não terminou
- Antes de um `/clear` ou `/compact` planejado
- Ao encerrar uma sessão agêntica longa que você quer retomar amanhã
- Antes de trocar de máquina no meio de um trabalho

## O que não faz

- Não roda `/clear` — quem decide é você
- Não escreve memórias de longo prazo (isso é `/meditate`)
- Não cria docs novos sem perguntar — reusa o plano existente
