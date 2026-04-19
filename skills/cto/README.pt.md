# CTO - Assessor Técnico de IA Universal

## O que faz

Analisa codebases, avalia arquitetura, identifica vulnerabilidades e guia decisões técnicas. Funciona em **modo sequencial** (análise focada em uma área) ou **modo swarm** (4 analistas especializados em paralelo para revisões completas). Detecta automaticamente padrões problemáticos, dívida técnica, falhas de segurança e oportunidades de otimização, integrando-se com memory para aprender padrões recorrentes.

Aplica a metodologia Glasswing para encontrar vulnerabilidades em código antigo e verificação de injeção de IA em aplicações com agentes.

## Como invocar

```
/cto [pergunta ou área para revisar]
```

**Exemplos:**

- `/cto revisar segurança do módulo de autenticação`
- `/cto avaliação completa de escalabilidade`
- `/cto isso é uma boa arquitetura?` (sequencial)
- `Revisar este projeto como CTO` (swarm automático)

## Quando usar

- **Pré-lançamento**: Auditoria completa antes de produção
- **Revisão de segurança**: Análise de vulnerabilidades OWASP e padrões fail-open
- **Decisões técnicas**: Avaliar alternativas de tech stack ou arquitetura
- **Refatoração**: Priorizar débito técnico e gerar planos de implementação
