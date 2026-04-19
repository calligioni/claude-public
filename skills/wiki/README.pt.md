# LLM Wiki

## O que faz

Base de conhecimento persistente e composta usando o padrão Karpathy LLM Wiki. Ingere fontes (URLs, emails, textos), armazena em páginas estruturadas, permite consultas e síntese socráticas entre documentos. Auto-coleta de Gmail, pesquisas de tendências e filas de URLs. Mantém índice, log de operações e detecta problemas de saúde (páginas órfãs, links quebrados, conteúdo desatualizado).

## Como invocar

```
/wiki ingest <url-ou-texto>     — ingere fonte e cria/atualiza páginas
/wiki <pergunta>                — consulta rápida contra o acervo
/wiki query <pergunta>          — consulta explícita com síntese
/wiki think <tópico>            — síntese socrática (detecta contradições, conexões)
/wiki harvest                   — auto-ingere Gmail starred, URLs em fila
/wiki lint                      — verifica saúde (órfãs, links quebrados, stale)
/wiki stats                     — contagem de páginas e fontes
```

**Exemplos:**
- `/wiki ingest https://exemplo.com/artigo`
- `/wiki qual é a melhor arquitetura de LLMs?`
- `/wiki think padrões de raciocínio em IA`

## Quando usar

- **Ingesta**: artigos, estudos, documentos que você quer reter e conectar a conhecimento existente
- **Query**: perguntas que precisam de resposta fundamentada em múltiplas fontes do acervo
- **Think**: explorar contradições, gerar insights não-óbvios ou identificar lacunas em um tema
- **Harvest**: manter wiki atualizada automaticamente via email starred e URLs enfileiradas
