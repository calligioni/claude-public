# Tech Stack Audit

## O que faz

Realiza auditoria abrangente da stack tecnológica do projeto contra o estado atual do mercado. Identifica bibliotecas em fim de vida (EOL), riscos de segurança, defasagem de versões e oportunidades de atualização com recomendações priorizadas por severidade. Executa pesquisa paralela por domínio (frontend, backend, infraestrutura, IA/ML) usando web search para verificar versões atuais, analisa impacto de breaking changes e agrupa atualizações em ondas compatíveis.

## Como invocar

```
/tech-audit
/tech-audit frontend
/tech-audit backend
/tech-audit infra
/tech-audit critical
```

**Exemplos:**
- `/tech-audit` — auditoria completa de todas as dependências
- `/tech-audit backend` — apenas dependências de servidor (framework, ORM, auth, cache)
- `/tech-audit critical` — apenas EOL, abandono e riscos de segurança (mais rápido)

## Quando usar

- Projeto ficou estagnado e você quer saber quais dependências estão desatualizadas
- Planejar ciclo de atualização de forma segura e priorizada
- Identificar bibliotecas em fim de vida ou com vulnerabilidades conhecidas
- Monorepo com versões divergentes da mesma dependência entre apps/packages
