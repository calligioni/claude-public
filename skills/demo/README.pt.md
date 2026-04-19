# Demo — Documentos Demonstrativos Reproduzíveis com Showboat

## O que faz

Cria documentos narrativos executáveis que combinam comentários, blocos de código com saída capturada e imagens. Os documentos são markdown legível E verificáveis — `showboat verify` re-executa todo código e compara a saída. Ideal para documentar fluxos, features, ferramentas e scripts de forma reproduzível.

## Como invocar

```
/demo <o que demonstrar — feature, ferramenta, workflow ou script>
```

**Exemplos:**
- `/demo "autenticação de usuário"`
- `/demo "este projeto"`
- `/demo "showboat CLI"`
- `/demo "pipeline de deploy"`

## Quando usar

- Documentar fluxos complexos com captura de saída real
- Criar narrativas verificáveis que se mantêm atualizadas
- Demonstrar ferramentas ou APIs com exemplos executáveis
- Validar que código funciona antes de entregar ao usuário
- Extrair comandos reutilizáveis de uma demonstração (`showboat extract`)
