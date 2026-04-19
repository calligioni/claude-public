# Run Local - Gerenciador de Ambiente de Desenvolvimento

## O que faz

Detecta automaticamente a estrutura do seu projeto, instala dependências e inicia todos os serviços locais (backend, frontend, bancos de dados, cache) com verificações de saúde. Cria um arquivo de configuração `.run-local.json` na primeira execução, permitindo restarts rápidos sem redetecção.

## Como invocar

```
/run-local              # Inicia ambiente de desenvolvimento
/run-local status       # Verifica saúde dos serviços
/run-local stop         # Para todos os serviços
/run-local logs         # Mostra logs agregados
```

**Exemplos:**
- `Preciso rodar a app localmente` → `/run-local`
- `Quais serviços estão rodando?` → `/run-local status`

## Quando usar

- Começar desenvolvimento em um novo projeto
- Iniciar múltiplos serviços simultaneamente (API, frontend, banco de dados)
- Verificar se todos os serviços estão saudáveis antes de commitar
- Parar ambiente sem matar processos manualmente
