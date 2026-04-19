# Investigate

## O que faz

Depuração sistemática com investigação de causa raiz. Aplica a **Iron Law**: sem consertos antes de entender a raiz do problema. Passa por cinco fases — coleta de sintomas, lock de escopo, teste de hipóteses, implementação mínima e verificação — produzindo um DEBUG REPORT estruturado. Regra das 3 tentativas: se três hipóteses falham, escala para revisão humana em vez de tentar uma quarta.

## Como invocar

```
/investigate [descrição do bug ou erro]
```

Exemplos:
- `/investigate 500 no POST /api/orders após o deploy de ontem`
- `/investigate por que o logout não invalida a sessão`
- `/investigate pipeline do Celery crashando de forma intermitente`

## Quando usar

- Bug reproduzível em produção ou staging
- Regressão após deploy recente (“funcionava ontem”)
- Stack trace ou erro 500 que você não entende de imediato
- Sempre que a tentação de aplicar um "quick fix" aparecer — o skill força tracing da causa raiz antes de qualquer edição
