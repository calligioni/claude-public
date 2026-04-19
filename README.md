# Biblioteca Pública de Claude Code Skills

Uma coleção curada de **47+ skills prontos para produção** para trabalho real de engenharia, QA, pesquisa e growth. Cada skill é um comando slash que você executa no [Claude Code](https://claude.com/claude-code) para encadear agentes, ferramentas e MCPs em workflows repetíveis.

Cada skill tem documentação em português em `skills/<nome>/README.pt.md`.

---

## O que você pode fazer com isso

### Entregar features de ponta a ponta
- **`/ship`** — spec → plano → implementação → QA → fix → docs. Retomável entre sessões.
- **`/parallel-dev`** — desenvolve múltiplas features independentes em git worktrees isolados, em paralelo.
- **`/orchestrate`** — meta-orquestrador que roteia a intenção pela biblioteca inteira de skills, com aprovações gated.
- **`/deep-plan`** — três fases (pesquisa → plano → implementação) com artefatos markdown persistentes.

### Revisar e subir com confiança
- **`/cto`** — reviewers paralelos (arquitetura, segurança, performance, qualidade) para feedback de nível PR.
- **`/review-changes`** — pega bugs, problemas de segurança e qualidade antes do commit.
- **`/verify`** — roda typecheck, testes e build numa só chamada.
- **`/test-and-fix`** — corrige testes quebrados automaticamente em loop.

### QA em qualquer coisa
- **`/qa-cycle`** — orquestrador de QA project-agnostic: discovery, teste por persona, fix, verificação.
- **`/fulltest-skill`** — swarm paralelo de page-testers com detecção de padrões cross-page.
- **`/qa-fix`** / **``** — fecha o loop sobre issues abertas.

### Pesquisar como analista
- **`/deep-research`** — investigação multi-track paralela com hierarquia de evidências.
- **`/research`** — analisa qualquer URL, imagem ou ferramenta por fit estratégico.
- **`/firecrawl`** / **`/scrapling`** / **`/browserless`** / **`/agent-browser`** — web scraping do simples ao stealth-grade.

### Crescer produtos
- **`/growth`** — CRO de SaaS, pricing, signup, onboarding, SEO/GEO, prevenção de churn.
- **`/website-design`** — sites B2B SaaS, dashboards, landing pages.
- **`/cpo`** — Chief Product Officer AI: ciclo da ideia até produção.
- **`/llm-eval`** — pipelines de avaliação para features com IA.

### Gerenciar conhecimento
- **`/gbrain`** — brain de conhecimento pessoal com 30 ferramentas MCP.
- **`/wiki`** — base de conhecimento persistente e compounding.
- **`/qmd`** — busca semântica híbrida (BM25 + vetorial + rerank via LLM) sobre coleções markdown.
- **`/vault-bootstrap`** — inicializa um vault Obsidian/markdown com um contrato CLAUDE.md.

### Meta
- **`/first-principles`** — decompõe problemas difíceis antes de implementar.
- **`/skill-tree`** — divide docs grandes em hierarquias navegáveis.
- **`/tech-audit`** — audita sua stack contra o estado atual do mercado.
- **`/architecture`** — gera e mantém docs de arquitetura com diagramas Mermaid.

---

## Instalação

```bash
# Clone no seu diretório de configuração do Claude Code
git clone https://github.com/escotilha/claude-public ~/.claude

# Ou seletivamente: copie skills individuais
cp -r claude-public/skills/cto ~/.claude/skills/
```

Depois, no Claude Code, digite `/` para ver os comandos disponíveis.

Cada skill é auto-contida em `skills/<nome>/`:
- `SKILL.md` — a definição do skill (front-matter + instruções)
- `README.pt.md` — resumo em português
- Scripts de apoio, configs, templates

---

## Princípios de design

- **Skill-first** — verifique se um skill existente cobre antes de fazer trabalho ad-hoc.
- **Paralelo por padrão** — agrupe chamadas independentes de ferramentas, gere subagentes em paralelo quando o trabalho for independente.
- **Modelo do tamanho certo** — Haiku para trabalho mecânico, Sonnet para julgamento, Opus para arquitetura e reviews críticas.
- **Escopo mínimo viável** — sem abstração prematura, sem código especulativo, sem comentários inflados.

---

## Licença

MIT. Use, faça fork, adapte. Se um skill for útil, uma estrela é bem-vinda.

---

## Últimas 3 atualizações

- **2026-04-19** — auto: sync claude-setup
- **2026-04-19** — auto: sync claude-setup
- **2026-04-19** — auto: sync claude-setup

