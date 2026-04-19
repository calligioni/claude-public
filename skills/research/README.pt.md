# Research

## O que faz

Analisa URLs e imagens (artigos, repositórios, tweets, ferramentas, screenshots, vídeos, podcasts) para identificar oportunidades de melhoria em skills, agentes e projetos. Extrai conteúdo via Firecrawl, Exa, Scrapling ou WebFetch, classifica por tipo (Tool/Pattern/Product/Infrastructure) e pontuação de relevância contra Claude Code, skills existentes, projetos ativos (ExampleProject, SourceRank, AgentWave, OpenClaw) e novas oportunidades.

## Como invocar

```
/research <url ou caminho da imagem>
```

**Exemplos:**
- `/research https://github.com/user/repo`
- `/research ~/screenshot.png`
- `/research https://www.youtube.com/watch?v=...`
- `research this` (em contexto de URL/imagem)

## Quando usar

- Descobrir padrões, ferramentas ou MCPs que possam melhorar a setup Claude Code
- Avaliar se um repositório, ferramenta ou padrão é útil para ExampleProject, SourceRank, AgentWave ou OpenClaw
- Extrair insights de artigos, vídeos ou documentação técnica para a base de conhecimento
- Identificar novas oportunidades de skills reutilizáveis baseadas em conteúdo encontrado
