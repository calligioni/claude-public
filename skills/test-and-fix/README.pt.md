# Test and Fix

## O que faz

Executa a suite de testes do projeto e corrige falhas automaticamente em loop. Detecta o executor de testes a partir da configuração (package.json, pyproject.toml, go.mod, Cargo.toml), roda os testes, identifica erros e aplica correções no código-fonte. Repete o processo até que todos os testes passem ou atinja o limite de 3 iterações.

Prioriza corrigir o código-fonte em vez de alterar asserções de teste, a menos que a asserção esteja genuinamente errada. Mostra as mudanças realizadas após cada iteração.

## Como invocar

```
/test-and-fix
```

Executa automaticamente a detecção do test runner e inicia o loop de testes e correções.

## Quando usar

- Testes estão falhando e você precisa corrigi-los rapidamente
- Acabou de fazer mudanças no código e alguns testes quebraram
- Quer validar que todas as correções deixam a suite passando
- Precisa iterar sobre múltiplas falhas sem intervção manual a cada erro
