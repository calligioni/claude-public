# QMD — Busca Semântica na Base de Conhecimento

## O que faz

Realiza busca semântica híbrida (BM25 + vetores + reranqueamento com LLM) sobre collections de markdown: skills, agents, rules e memory. Combina busca por palavras-chave e similaridade semântica para encontrar padrões, decisões e documentação em toda a base de conhecimento do claude-setup.

## Como invocar

```
/qmd <sua consulta>
```

**Exemplos:**
- `/qmd como fazer auditoria de segurança`
- `/qmd skill para validar entrada de usuário`
- `/qmd padrão de tratamento de erros`

## Quando usar

- **Procurar skills ou agents** por funcionalidade ("qual skill faz parsing de JSON?")
- **Encontrar padrões e decisões** já documentadas na base
- **Buscar em memory** por contexto de sessões anteriores
- **Localizar documentação** em collections específicas quando a busca deve ser scope (ex: apenas em rules)
