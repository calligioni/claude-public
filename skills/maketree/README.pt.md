# Maketree - Gerenciador de Worktrees

## O que faz

Cria e gerencia git worktrees para desenvolvimento paralelo. Use a flag nativa `claude --worktree` para casos simples, ou este skill para setups em lote e configurados. Automatiza a descoberta de branches, cria múltiplos worktrees simultaneamente e persiste preferências em `.worktree-scaffold.json`.

## Como invocar

```
/maketree                 # Detecta config local ou executa descoberta
/maketree list            # Lista worktrees ativos
/maketree clean           # Remove worktrees de features (mantém repo principal)
/maketree discover        # Força re-descoberta de branches
```

**Alternativa nativa (recomendada para caso único):**
```bash
claude --worktree feature-name
```

## Quando usar

- **Setups em lote**: Criar múltiplos worktrees de uma vez a partir de configuração
- **Workflows repetidos**: Salvar preferências de descoberta para reutilizar
- **Projetos complexos**: Gerenciar muitos branches com um único comando
- **Desenvolvimento paralelo**: Trabalhar em várias features sem fazer stash/commit
