# Architecture — Gerador de Documentação de Arquitetura de Software

## O que faz

Gera e mantém automaticamente documentação de arquitetura completa para qualquer projeto, com diagramas Mermaid, backups versionados e exportação para PDF/DOCX. Detecta mudanças no repositório e atualiza incrementalmente apenas as seções afetadas, sem reescrever o documento inteiro a cada execução.

## Como invocar

```
/architecture [formato: md|pdf|docx] [--force]
```

**Exemplos:**
- `/architecture` — Gera/atualiza markdown
- `/architecture pdf` — Gera markdown + exporta para PDF
- `/architecture docx` — Gera markdown + exporta para Word
- `/architecture md --force` — Regenera do zero

## Quando usar

- **Primeira documentação arquitetural:** Geração inicial detecta automaticamente tech stack, componentes, fluxos de dados e integração
- **Após mudanças significativas:** Atualiza incrementalmente seções afetadas (novos serviços, migrações DB, rotas API, infraestrutura)
- **Exportação para stakeholders:** Gera PDF/DOCX com diagramas renderizados para apresentações e relatórios
- **Auditoria e conformidade:** Mantém histórico versionado com backups dos 3 últimos snapshots

## Estrutura de saída

```
docs/architecture/
├── ARCHITECTURE.md                 # Versão atual
├── .architecture-meta.json         # Metadados (versão, SHA, timestamp)
├── backups/ARCHITECTURE.v{N}.md    # Últimas 3 versões
└── exports/ARCHITECTURE.{pdf,docx} # Exportações
```
