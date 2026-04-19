# PinchTab

## O que faz

Automação local de navegador via servidor HTTP lightweight + CLI. Utiliza árvores de acessibilidade com referências estáveis de elementos em vez de screenshots — **5-13x mais barato em tokens**. Ideal para interação com páginas, extração de dados e testes automatizados com Chrome controlado via IA.

Oferece perfis persistentes com cookies/sessões, tab locking para segurança multi-agente, modo stealth e API HTTP para contextos não-Bash.

## Como invocar

```bash
/pinchtab
```

**Workflow padrão: navegue → capture → aja → re-capture**

```bash
# Navegar
pinchtab nav "https://example.com"
sleep 3

# Capturar elementos interativos (compacto)
pinchtab snap -i -c

# Agir usando referências
pinchtab click e5
pinchtab fill e12 "busca"
pinchtab press e12 Enter

# Re-capturar para verificar
pinchtab snap -i -c
```

**Comandos essenciais:**
- `pinchtab snap -i -c` — elementos interativos (~2.000 tokens)
- `pinchtab text` — extrair texto (~800 tokens)
- `pinchtab ss -o arquivo.jpg` — screenshot
- `pinchtab eval "<js>"` — executar JavaScript
- `pinchtab pdf -o arquivo.pdf` — exportar PDF

## Quando usar

- **Preenchimento e submissão de formulários** — login, busca, cadastro com rastreamento de elementos
- **Extração de dados estruturados** — tabelas, listas, painéis com `text` ou `eval`
- **Testes multi-página** — validar navegação e conteúdo em URLs diferentes
- **Sessões autenticadas persistentes** — gerenciar perfis Chrome com cookies/login mantidos entre execuções
