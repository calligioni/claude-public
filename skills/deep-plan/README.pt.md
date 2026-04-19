# Deep Plan

## O que faz

Fluxo de trabalho disciplinado em três fases (pesquisa → planejamento → implementação) que produz artefatos markdown persistentes. Nunca escreve código antes da aprovação explícita do usuário sobre o plano escrito. Mantém estado da sessão em `.deep-plan-state.json` para retomar de onde parou.

## Como invocar

```
/deep-plan <descrição da feature ou tarefa>
```

**Exemplos:**
- `/deep-plan Implementar autenticação OAuth2`
- `/deep-plan Refatorar sistema de cache`
- `/deep-plan Adicionar exportação em PDF aos relatórios`

## Quando usar

- **Planejar features complexas** com múltiplas camadas ou dependências
- **Revisar arquitetura** antes de grandes mudanças de código
- **Documentar decisões** de design e trade-offs
- **Trabalhos interruptíveis** que precisam retomar do ponto exato com `research.md` e `plan.md` como referência
