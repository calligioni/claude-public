# Skill Tree — Hierarchical Knowledge Splitter

## O que faz

Divide documentação grande em uma árvore navegável de arquivos indexados, reduzindo bloat de contexto. Agentes leem apenas o índice e as seções relevantes, pulando o resto. Ideal para APIs grandes, SKILLs extensos ou research monolíticos que múltiplos agentes precisam de slices diferentes.

## Como invocar

```
/skill-tree <caminho-arquivo | URL | tópico>
```

**Exemplos:**
- `/skill-tree docs/api.md`
- `/skill-tree https://stripe.com/docs/webhooks`
- `/skill-tree Stripe webhooks`

## Quando usar

- Documentação da API retornada por `chub get` é muito grande para contexto de subagente
- Um SKILL.md cresceu além de ~300 linhas cobrindo múltiplos domínios
- Output de research é monolítico e apenas partes são relevantes por query
- Material de referência que múltiplos agentes precisam de seções diferentes

## Saída

Diretório `.skill-trees/<nome>/` com:
- `_index.md` — índice navegável (leia primeiro)
- `seção-1.md`, `seção-2.md`, etc. — sub-arquivos por tema

Cada sub-arquivo tem 50-200 linhas. Alvo: 4-12 seções totais.
