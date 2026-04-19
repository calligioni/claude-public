# Codebase Cleanup

## O que faz

Analisa repositórios para identificar arquivos não utilizados, redundantes ou desnecessários. Detecta órfãos de código, arquivos temporários, backups, duplicatas e dependências não importadas. Gera relatório detalhado com confiança de cada achado e executa remoção segura apenas com permissão do usuário.

## Como invocar

```
/cleanup codebase
/cleanup unused files
/cleanup dead code
```

Exemplos:
- "Limpe arquivos não utilizados no meu projeto Node.js"
- "Identifique e remova código morto"
- "Encontre arquivos desnecessários"

## Quando usar

- Projeto está crescendo e precisa de manutenção
- Quer reduzir tamanho do repositório antes de migração
- Encontrou arquivos `.bak`, `.tmp` ou similares acumulados
- Precisa identificar dependências não importadas em `package.json`
- Refatorou código e quer limpar resquícios antigos
