# Vault Bootstrap

## O que faz

Gera um contrato de API `CLAUDE.md` para vaults de conhecimento locais (Obsidian, markdown puro) de modo que Claude Code leia e escreva respeitando convenções. O contrato define: propósito do vault, organização, nomenclatura, permissões e restrições. Após 5 perguntas diagnósticas, gera também `memory.md` (contexto persistente entre sessões) e `_session.md` (rastreamento de mudanças por sessão).

## Como invocar

```
/vault-bootstrap
```

**Exemplos:**
- `/vault-bootstrap /Users/nome/Obsidian` — bootstrap vault existente
- `/vault-bootstrap` — skill pergunta o caminho

## Quando usar

- Você tem um vault Obsidian, Zettelkasten ou base de conhecimento em markdown e quer que Claude Code respeite sua estrutura
- Quer reutilizar o vault como contexto persistente entre sessões
- Está configurando um novo vault do zero
- Precisa definir explicitamente o que Claude pode/não pode fazer no seu vault
