# QA Cycle

## O que faz

Orquestrador autônomo de QA que executa o ciclo completo de testes: detecção de projeto, design de personas, descoberta de bugs, triagem, correção de código, verificação e deploy. Funciona de forma independente com qualquer projeto, detectando automaticamente a stack tecnológica, rotas, features e credenciais de teste. Em execuções subsequentes, delega instantaneamente para skills específicos do projeto (`/qa-{project}`). Gerencia sua própria lista de tarefas, para apenas em operações destrutivas (DROP TABLE, force push, criar serviços pagos) e executa tudo mais autonomamente até atingir 100% de cobertura ou 10 ciclos.

## Como invocar

```
/qa-cycle                    # Ciclo completo autônomo
/qa-cycle --discover-only    # Apenas descoberta (sem fix/deploy)
/qa-cycle --fix-only         # Apenas corrigir issues abertas
/qa-cycle --verify-only      # Apenas verificar issues em TESTING
/qa-cycle --severity p0      # Ciclo completo apenas para P0
/qa-cycle --skip-fix         # Descoberta + relatório + verificação
/qa-cycle --regenerate       # Forçar redescoberta mesmo se skill existe
```

## Quando usar

- Executar QA completa em um projeto novo sem configuração prévia
- Validar cobertura de features e encontrar regressões
- Corrigir bugs descobertos de forma autônoma até 100% de cobertura
- Gerar skill específico do projeto para futuras execuções rápidas
- Testar múltiplas personas em paralelo contra um aplicativo web
