# Freeze

## O que faz

Restringe edições (Edit/Write) a um diretório específico durante a sessão. Um hook PreToolUse **bloqueia** (não apenas avisa) qualquer tentativa de edição fora do boundary definido. Útil para prevenir scope creep durante debugging — enquanto você caça um bug em `src/auth/`, o skill garante que nenhum arquivo fora dessa pasta seja modificado acidentalmente. Comandos Bash (incluindo `sed`) continuam sem restrição — é uma trava de disciplina, não uma fronteira de segurança.

## Como invocar

```
/freeze <caminho>
```

Exemplos:
- `/freeze src/auth/`
- `/freeze /Users/ps/code/example-project/apps/api`

Para desligar:
```
/unfreeze
```

## Quando usar

- Durante `/investigate` após formar hipótese de causa raiz — trava o escopo na área afetada
- Refatoração focada em um módulo, prevenindo edits acidentais em código adjacente
- Trabalhando em features paralelas onde cada branch deve tocar apenas uma pasta
- Sessões longas onde o contexto pode levar a sugestões fora do escopo pretendido
