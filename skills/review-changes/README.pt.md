# Review Changes

## O que faz

Analisa alterações não commitadas em busca de vulnerabilidades de segurança, erros e problemas de qualidade antes do commit. Classifica arquivos por risco (CRITICAL, HIGH, MEDIUM, LOW) e executa duas passagens: a primeira identifica questões que bloqueiam o commit (injeção SQL, XSS, hardcoded secrets, race conditions); a segunda lista achados informativos (bugs, gaps de teste, código debug).

## Como invocar

```
/review-changes
```

Executa automaticamente contra staged changes (`git diff --cached`) ou, se nenhum estiver staged, contra unstaged changes (`git diff`). Também verifica arquivos não rastreados.

## Quando usar

- Antes de fazer commit em código crítico (autenticação, autorização, criptografia, pagamentos)
- Para auditar remoções de código, especialmente em arquivos Tier 1-2
- Quando há dúvida sobre injeção, TOCTOU, ou padrões inseguros (fail-open)
- Para detectar debug code, secrets acidentais e problemas de concorrência
