# manual

## O que faz

Constrói o manual do usuário do projeto em formato MkDocs, com suporte opcional a exportação para Word e captura automática de screenshots. Detecta automaticamente configurações existentes (`mkdocs-manual.yml`, `mkdocs.yml` ou diretório `manual/`) e gera documentação HTML ou Word conforme solicitado.

## Como invocar

```
/manual [formato] [url]
```

**Formatos disponíveis:**
- `/manual` ou `/manual html` — Constrói site MkDocs
- `/manual word` — Constrói e exporta para Word (.docx)
- `/manual screenshots [url]` — Captura screenshots (ex: `http://localhost:3000`)

**Exemplos:**
```
/manual
/manual word
/manual screenshots http://localhost:3000
```

## Quando usar

- Gerar documentação HTML a partir de arquivos markdown existentes
- Exportar manual completo para Word (útil para distribuição offline)
- Automatizar captura de screenshots da aplicação rodando localmente e embuti-las na documentação
- Manter manual estruturado com MkDocs sem gerenciar comandos manualmente
