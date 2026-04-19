# Verify Project Health

## O que faz

Verifica a saúde do projeto executando type-check, testes, build e lint após mudanças. Detecta automaticamente o tipo de projeto (Node.js, Python, Go, Rust) e roda os comandos aplicáveis de forma sequencial, reportando todos os problemas em uma tabela resumida.

## Como invocar

```
/verify [tipo: types|tests|build|all]
```

Exemplos:
- `/verify` — executa todos os checks disponíveis
- `/verify types` — apenas type-check
- `/verify tests` — apenas testes
- `/verify build` — apenas build

## Quando usar

- Após fazer alterações no código, antes de commitar
- Para validar que type-check, testes e build passam juntos
- Quando você quer um relatório rápido de problemas (sem modificar arquivos)
- Em projetos Node.js, Python, Go ou Rust com configuração padrão
