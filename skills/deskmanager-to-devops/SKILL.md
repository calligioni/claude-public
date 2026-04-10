---
name: deskmanager-to-devops
description: "Integra chamados do Deskmanager no Azure DevOps como work items (Bug, Feature ou Task) no projeto KPL. Use sempre que o usuario pedir para integrar, sincronizar, exportar, criar work item ou adicionar na sprint a partir de um chamado Deskmanager. Tambem use quando o usuario mencionar um codigo de chamado (formato MMYY-NNNNNN como 0326-000312) junto com qualquer referencia ao DevOps, sprint, backlog ou work item. Triggers: integrar chamado, sincronizar ticket, exportar para devops, criar bug do deskmanager, ticket para sprint, adicionar chamado na sprint, integrar atividade."
user-invocable: true
tools: Bash, Read, Write, Glob, Grep
effort: medium
---

# Deskmanager → Azure DevOps Integration

Integra chamados do Deskmanager no Azure DevOps como work items no projeto KPL.
Suporta criacao de Bug, Feature e Task, com verificacao de duplicatas.

## Fluxo de Execucao

Siga estes passos na ordem. Execute as chamadas MCP em paralelo quando possivel.

### Passo 1: Extrair codigo do chamado

Identifique o codigo do chamado no formato `MMYY-NNNNNN` (ex: `0326-000312`) a partir da mensagem do usuario.
Se o usuario fornecer apenas um numero parcial, pergunte o codigo completo.

### Passo 2: Buscar dados do Deskmanager

Execute em paralelo:

1. **Buscar chamado** via `mcp__deskmanager__buscar_chamado` com o codigo para obter a chave numerica
2. Com a chave, buscar em paralelo:
   - `mcp__deskmanager__dados_chamado` — dados completos do chamado
   - `mcp__deskmanager__historico_chamado` — historico de interacoes

Extrair destes dados:
- **CodChamado**: codigo do chamado (ex: 0326-000312)
- **Cliente**: nome do campo CodCliente[0].text
- **Solicitante**: nome + email do solicitante
- **Assunto**: titulo do chamado
- **Descricao**: descricao do cliente (campo Descricao, decodificar HTML entities)
- **Categoria**: campo CodSubCategoria[0].text
- **Prioridade**: campo CodPrioridadeAtual[0].text
- **Observacao Interna**: do historico, buscar a acao que tem ObservacaoInterna preenchida (geralmente a acao do operador de suporte que redirecionou para tecnologia)
- **Analista**: nome do operador da acao com ObservacaoInterna

### Passo 3: Verificar duplicatas no Azure DevOps

Usar `mcp__azure-devops__search_workitem` com:
- searchText: codigo do chamado (ex: "0326-000312")
- project: ["KPL"]

**Se encontrar work item existente:**
- Informar ao usuario: "Work item #XXXXX ja existe para este chamado. Deseja atualizar?"
- Se sim → modo UPDATE (Passo 6b)
- Se nao → encerrar

**Se nao encontrar:** → modo CREATE (Passo 6a)

### Passo 4: Processar imagens imgur

Extrair o texto da ObservacaoInterna do historico e usar:
`mcp__deskmanager__processar_imagens_chamado` com o HTML da observacao interna.

Isso converte links imgur (`https://i.imgur.com/xxx.png`) em tags `<img>` renderizaveis.
Usar o HTML retornado nos ReproSteps.

### Passo 5: Determinar tipo de work item e sprint

**Tipo de work item** — mapear pela categoria do Deskmanager:

| Palavras na categoria | Tipo DevOps |
|---|---|
| "Erro", "Bug", "Rejeição" | Bug |
| "Configuração", "Dúvida", "Acesso" | Task |
| "Melhoria", "Novo Projeto", "Feature" | Feature |
| (default) | Bug |

Se o usuario especificou o tipo explicitamente, usar o que ele pediu.

**Sprint atual** — buscar via:
`mcp__azure-devops__work_list_team_iterations` com:
- project: "KPL"
- team: "KPL Team"
- timeframe: "current"

Usar o IterationPath retornado (ex: `KPL\Sprint 136`).

### Passo 6a: Criar work item (novo)

Usar `mcp__azure-devops__wit_create_work_item` com:
- project: "KPL"
- workItemType: Bug/Feature/Task (conforme Passo 5)

Campos obrigatorios:

```
System.Title: #{CodChamado} - {Cliente} - {Assunto resumido}
System.Description: ##CodChamado\nCliente: {Cliente}\nSolicitante: {Solicitante} ({Email})\nPrioridade: {Prioridade}\nStatus DM: {Status}\nGrupo: {Grupo}\nDescrição: {Descricao resumida}
System.AreaPath: KPL
System.IterationPath: {Sprint atual do Passo 5}
Microsoft.VSTS.Common.Priority: 2
Microsoft.VSTS.Common.Activity: Development
Custom.Tipodedemanda: {Bug/Feature/Task}
Custom.Cliente: {NomeCliente SEM espacos}
Custom.615f4c84-21d6-4f16-a2f6-6af4f823cd60: {CodChamado}
Custom.Planejamento: Extra
Custom.Especificacao: Integrado
```

Se tipo Bug, adicionar tambem:
```
Microsoft.VSTS.Common.Severity: 3 - Medium
Microsoft.VSTS.TCM.ReproSteps: {HTML formatado — ver template abaixo}
```

### Passo 6b: Atualizar work item (existente)

Usar `mcp__azure-devops__wit_update_work_item` com o ID encontrado no Passo 3.
Atualizar os campos ReproSteps e Description com dados mais recentes.

### Passo 7: Confirmar ao usuario

Informar:
- Se foi criacao ou atualizacao
- ID do work item
- Link direto: `https://dev.azure.com/onclickbr/KPL/_workitems/edit/{ID}`
- Tipo criado (Bug/Feature/Task)
- Sprint atribuida

---

## Template HTML dos ReproSteps

Usar este template para montar o campo ReproSteps (formato Html):

```html
<h3>Chamado Deskmanager: {CodChamado}</h3>
<p>
  <b>Cliente:</b> {Cliente}<br>
  <b>Solicitante:</b> {Solicitante} ({Email})<br>
  <b>Analista:</b> {Analista}
</p>
<hr>
<h4>{Ambiente}</h4>
<p><b>Descricao do incidente:</b><br>{DescricaoIncidente}</p>

<h4>Simular o Erro/Problema:</h4>
{PassosReproducao com <img> inline}

<hr>
<p>
  <b>POPs/Artigos:</b> {POPs ou N/A}<br>
  <b>Comparativo:</b> {Comparativo ou N/A}<br>
  <b>Priorizacao:</b> {Prioridade}
</p>

<hr>
<h4>Dados de Acesso</h4>
<p>{DadosAcesso}</p>

<hr>
<h4>Historico de Interacoes</h4>
<p>
{Para cada acao do historico, do mais recente ao mais antigo:}
[{Data} - {Operador ou Solicitante}] {Resumo da acao}<br>
</p>
```

Os campos entre `{}` devem ser preenchidos com os dados extraidos no Passo 2.
A secao de reproducao deve conter as imagens processadas pelo Passo 4.
Se a ObservacaoInterna nao tiver secoes claras (Ambiente, Simular, etc.), adaptar o template.

---

## Notas importantes

- **Nunca criar duplicatas.** Sempre verificar no Passo 3 antes de criar.
- **Codigo do chamado** deve estar tanto na Description (como `##CodChamado`) quanto no campo custom Numero Ticket.
- **Cliente sem espacos**: "GIULIANA FLORES" → "GIULIANAFLORES", "SOCIAL COMMERCE" → "SOCIALCOMMERCE"
- **Imagens**: sempre processar via `processar_imagens_chamado` antes de montar o HTML dos ReproSteps.
- **Historico**: incluir todas as interacoes, com data e autor, do mais recente ao mais antigo.
- **Se o chamado nao tiver ObservacaoInterna** (analise do suporte), usar a Descricao do chamado nos ReproSteps.
