# agent-browser

## O que faz

CLI nativo em Rust para automação de navegador via CDP. Substitui os CLIs `browse` e PinchTab. Oferece navegação, snapshots com árvore de acessibilidade, cliques, preenchimento de inputs, screenshots, PDFs, modo batch, diff visual, interceptação de rede e persistência de sessão.

## Como invocar

```bash
agent-browser open <url>
agent-browser snapshot
agent-browser click <seletor ou @ref>
agent-browser fill <seletor ou @ref> <texto>
agent-browser screenshot [caminho]
agent-browser batch  # stdin com JSON
```

**Antes de qualquer comando, carregue a referência atualizada:**
```bash
agent-browser skills get agent-browser
```

## Quando usar

- Automação multi-etapas com modo batch (especialmente para subagentes de QA)
- Testes de regressão visual com diff contra baselines
- Coleta de dados de página com árvore de acessibilidade e refs estruturados
- Fluxos que exigem entrada real de teclado ou interceptação de requisições de rede
