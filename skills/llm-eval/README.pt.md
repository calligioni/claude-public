# llm-eval

## O que faz

Pipeline estruturado para avaliar qualidade de saídas de LLM em produção. Implementa a metodologia de Hamel Husain em 6 fases: análise de falhas, geração de dados sintéticos, design de juízes LLM, calibração contra rótulos humanos, avaliação RAG (se aplicável) e automação em CI. Detecta automaticamente features com IA no codebase e monta infraestrutura de eval completa ou audita gaps em evals existentes.

## Como invocar

```
/llm-eval <feature ou "audit">
```

**Exemplos:**
- `/llm-eval audit` — Analisa evals existentes, encontra lacunas
- `/llm-eval "chat completion endpoint"` — Pipeline completo para a feature
- `/llm-eval rag eval` — Avaliação especializada em retrieval
- `/llm-eval full pipeline` — Audit + Build para todas as features com IA

## Quando usar

- **Antes de colocar feature com LLM em produção** — validar qualidade com juízes calibrados contra humanos
- **Regressão suspeita em outputs de IA** — auditar evals existentes ou executar pipeline de testes
- **Implementar RAG** — avaliar qualidade de retrieval separado de geração
- **Integrar evals em CI/CD** — automatizar testes de qualidade em PRs que tocam features com IA
