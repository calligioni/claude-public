# Browserless - Automação de Headless Browser

## O que faz

Executa automação de navegador headless Chrome via Browserless em VPS auto-hospedado. Gera PDFs, captura screenshots, extrai conteúdo renderizado com JavaScript, executa auditorias Lighthouse e contorna proteções anti-bot. Ideal para processamento remoto de páginas dinâmicas e geração de documentos.

## Como invocar

```
/browserless <tarefa>
```

**Exemplos:**

- `/browserless gerar PDF de https://exemplo.com/relatorio`
- `/browserless screenshot da página https://site.com`
- `/browserless extrair conteúdo JS de https://spa.com/dashboard`
- `/browserless auditoria Lighthouse em https://exemplo.com`
- `/browserless acessar https://site-protegido.com contornando bot detection`

## Quando usar

- **PDF/Screenshots**: Converter páginas ou HTML em documentos visuais
- **Conteúdo dinâmico**: Extrair HTML após renderização JavaScript (SPAs, dashboards)
- **Auditorias de performance**: Análise Lighthouse de acessibilidade, performance e SEO
- **Scraping anti-bot**: Acessar sites com proteção usando stealth mode e bypass
