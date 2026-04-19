# Claude API

## O que faz

Fornece dois caminhos principais para integrar Claude em aplicações: a **Messages API** para controle fino com prompting direto e streaming de respostas, e **Claude Managed Agents** (beta) para executar tarefas autônomas com acesso a ferramentas como bash, leitura/escrita de arquivos, web search e busca de conteúdo em URLs em um ambiente gerenciado na nuvem.

## Como invocar

```
/claude-api
```

**Exemplos:**
- Implementar chat com streaming: `client.messages.stream(...)`
- Usar tool use para integrar APIs externas
- Criar um agente autônomo com Managed Agents para automação de tarefas
- Configurar extended thinking para problemas complexos

## Quando usar

- **Messages API:** quando precisa de controle fino sobre loops de agente, streaming em tempo real, ou tool use com execução no cliente
- **Managed Agents:** para tarefas de longa duração, automação com sandbox gerenciado (bash, file ops, web search), ou infraestrutura mínima
- **Tool use:** integrar APIs externas, executar ações em sistemas externos de forma estruturada
- **Extended thinking:** problemas que exigem raciocínio complexo e profundo (Opus 4.6)
