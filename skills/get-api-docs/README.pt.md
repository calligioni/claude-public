# Get API Docs via chub

## O que faz

Busca documentação atual de APIs e SDKs (1.000+ bibliotecas: Supabase, Anthropic, Clerk, Prisma, Stripe, Playwright) via CLI `chub`. Retorna docs precisos e versionados em vez de confiar em dados de treinamento desatualizados.

## Como invocar

```
/get-api-docs <nome da biblioteca ou ID chub>
```

**Exemplos:**
- `/get-api-docs stripe` — busca docs do Stripe
- `/get-api-docs anthropic/sdk --lang ts` — Anthropic SDK em TypeScript
- `/get-api-docs openai/chat --version 1.0.0` — versão específica

Fluxo básico:
```bash
chub search "stripe"              # encontra ID correto
chub get stripe/api --lang ts     # fetch da documentação
```

## Quando usar

- **Escrever código contra APIs** — consultar docs atuais em vez de adivinhar
- **Validar comportamento de bibliotecas** — confirmar assinatura de funções, parâmetros obrigatórios
- **Versões específicas** — usar `--version` se o projeto fixa uma versão
- **Seções grandes** — usar `--file webhooks.md` para baixar só o necessário em contextos com agentes
