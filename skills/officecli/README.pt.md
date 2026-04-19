# officecli

## O que faz

Cria, analisa, valida e modifica documentos Office (.docx, .xlsx, .pptx) via CLI sem dependências externas. Trabalha em três camadas: L1 (leitura e inspeção), L2 (operações DOM com `set`, `add`, `remove`), e L3 (manipulação direta de XML). Suporta busca e substituição de texto com regex, formatação de runs, operações em lote, e seleção visual via navegador com `watch`.

## Como invocar

`/officecli`

**Exemplos:**
```bash
officecli create report.docx
officecli view report.docx issues
officecli set report.docx /body/p[1] --prop text="Novo texto" --prop bold=true
officecli add slides.pptx '/slide[1]' --type shape --prop text="Título" --prop color=FFFFFF
officecli query data.xlsx 'cell[value>=100]'
officecli batch report.docx --input updates.json
```

## Quando usar

- Gerar ou modificar relatórios, apresentações e planilhas programaticamente
- Validar formatação, estrutura e conteúdo de documentos Office
- Buscar/substituir texto em massa com regex em múltiplos elementos
- Operações multi-etapa em arquivos grandes (modo resident com `open`/`close`)
- Inspecionar estrutura XML e extrair dados via queries CSS-like
