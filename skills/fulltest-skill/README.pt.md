# Full-Spectrum Testing Skill

## O que faz

Testa automaticamente todo um site de forma paralela, detectando falhas visuais, erros JavaScript, links quebrados e recursos não carregados. Mapeia a estrutura do site, executa testes simultâneos em múltiplas páginas, compartilha falhas em tempo real entre testadores, detecta padrões de erro recorrentes e aplica correções automáticas. Após fixes, re-testa incrementalmente até que todos os testes passem ou o limite de iterações seja atingido.

## Como invocar

```
/fulltest
/full test
/site test
/test all pages
```

**Exemplos:**
- `/fulltest` — testa site atual
- `teste http://localhost:3000` — testa URL específica
- `fulltest e corrija os problemas` — testa e aplica fixes automaticamente

## Quando usar

- **Garantir cobertura visual**: Verificar se CSS, fonts e imagens carregam em todas as páginas
- **Encontrar erros sistêmicos**: Detectar o mesmo erro em múltiplas páginas (ex: null reference em 3 páginas = problema raiz único)
- **Regressão visual**: Capturar screenshots de falhas para análise
- **Antes de deploy**: Validar que site inteiro funciona antes de enviar para produção
