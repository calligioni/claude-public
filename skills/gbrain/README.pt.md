# GBrain

## O que faz

GBrain é um sistema de gestão de conhecimento pessoal nativo em PostgreSQL com busca híbrida RAG. Armazena informações sobre pessoas, empresas, conceitos e reuniões como páginas com verdade compilada e timelines append-only, interligadas via grafo tipado. Combina busca por palavra-chave (tsvector), busca vetorial (embeddings 1536-dim) e fusão RRF para recuperação precisa e contextualizada.

Integra-se nativamente ao Claudia injetando conhecimento relevante antes de cada inferência, funcionando como Source 5 no context builder de memória.

## Como invocar

```
/gbrain <subcommand: setup | import | query | ingest | maintain | stats>
```

**Exemplos:**
- `/gbrain setup` — instala GBrain no VPS (uma única vez)
- `/gbrain import /path/to/markdown/` — indexa diretório de markdown
- `/gbrain query "O que sabemos sobre a Empresa X?"` — busca híbrida com expansão multi-query
- `/gbrain ingest` — processa novas informações e atualiza páginas
- `/gbrain stats` — estatísticas do brain

## Quando usar

- **Consultar conhecimento pessoal** antes de responder questões sobre pessoas, empresas ou conceitos já rastreados
- **Ingerir informações** de conversas, reuniões ou pesquisa para construir conhecimento composto automaticamente
- **Manter qualidade** — verificar saúde do brain, encontrar páginas órfãs ou obsoletas, consolidar entradas de timeline
- **Expandir capacidade** — importar arquivos markdown novos ou sincronizar repositórios existentes regularmente
