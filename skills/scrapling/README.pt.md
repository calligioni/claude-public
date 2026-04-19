# Scrapling

## O que faz

Web scraping com bypass anti-bot, impersonação TLS e rastreamento adaptativo de elementos via MCP do Scrapling. Oferece três modos de fetching: HTTP rápido, navegador stealth (Playwright) e automação full-browser. Detecta automaticamente bloqueios e escala para modos mais robustos conforme necessário.

## Como invocar

```
/scrapling [url] [modo] [seletor]
```

Exemplos:
- `/scrapling https://exemplo.com.br fetch` — HTTP rápido, sem anti-bot
- `/scrapling https://site-protegido.com stealthy_fetch div.produto` — Bypass Cloudflare + extração de elementos
- `/scrapling https://spa.com playwright_fetch` — Browser full para SPAs

## Quando usar

- **Sites com Cloudflare/DataDome** — use `stealthy_fetch` para bypass anti-bot
- **Páginas estáticas sem proteção** — use `fetch` (mais rápido e leve)
- **SPAs e conteúdo renderizado** — use `playwright_fetch` para automação full-browser
- **Firecrawl sem créditos** — Scrapling roda localmente, sem custos
