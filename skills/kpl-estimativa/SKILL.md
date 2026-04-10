---
name: kpl-estimativa
description: "Automatiza estimativa tecnica de PBIs do KPL no Azure DevOps. Analisa o codebase Delphi/SQL/.NET, consulta Desk Manager, calcula horas de desenvolvimento, preenche a aba Dev no DevOps e cria task filha 'Desenvolver'. Use sempre que o usuario pedir para estimar, orcar horas, fazer estimativa, calcular esforco de um work item ou PBI do DevOps. Tambem use quando o usuario mencionar /kpl-estimativa seguido de IDs numericos. Triggers: estimar chamado, orcar horas devops, estimativa tecnica, calcular esforco PBI, analisar complexidade work item."
user-invocable: true
tools: Bash, Read, Glob, Grep, Write, Edit
effort: high
---

# KPL Estimativa Tecnica

Automatiza o processo completo de estimativa tecnica para Product Backlog Items (PBIs) do projeto KPL no Azure DevOps. Para cada PBI, analisa o codebase, estima horas de desenvolvimento, preenche a aba Dev e cria uma task filha "Desenvolver".

## Entrada

O usuario fornece um ou mais IDs de work items do DevOps, separados por virgula:
- `/kpl-estimativa 94462`
- `/kpl-estimativa 94462,94463,94464`

## Fluxo de Execucao

Siga estes passos na ordem. Execute chamadas MCP em paralelo sempre que possivel.

### Passo 1: Buscar Work Items no Azure DevOps

Para cada ID fornecido, buscar em paralelo via `mcp__azure-devops__wit_get_work_item`:
- project: "KPL"
- expand: "all" (para incluir attachments e relations)

Extrair de cada work item:
- **Title**: `System.Title`
- **Description**: `System.Description` (HTML com analise tecnica detalhada)
- **IterationPath**: `System.IterationPath` (ex: `KPL\Sprint 137`)
- **Cliente**: `Custom.Cliente`
- **Ticket Desk**: `Custom.615f4c84-21d6-4f16-a2f6-6af4f823cd60`
- **Attachments**: verificar se ha PDFs anexados com prints de telas
- **Effort atual**: `Microsoft.VSTS.Scheduling.Effort` (verificar se ja tem horas)

Se o PBI ja tiver Effort preenchido (> 0), avisar o usuario e perguntar se deseja sobrescrever.

### Passo 2: Buscar no Desk Manager

Extrair o numero do ticket Desk de duas fontes possiveis:
1. Campo custom `Custom.615f4c84-21d6-4f16-a2f6-6af4f823cd60`
2. Regex no titulo: `#(\d{4}-\d{6})`

Se encontrou o ticket, buscar via `mcp__deskmanager__buscar_chamado` com o numero para obter contexto adicional (descricao do cliente, status, prioridade).

### Passo 3: Explorar o Codebase KPL

Esta e a etapa mais importante. Com base na descricao do PBI, identificar as areas do codebase afetadas.

#### 3a. Consultar Knowledge Graph

Usar `mcp__memory__search_nodes` para buscar padroes de arquitetura KPL relevantes:
- Buscar por termos-chave da descricao (ex: "financeiro", "estoque", "pedido", "nota fiscal")
- Buscar padroes de implementacao (ex: "Delphi_DataModule_Pattern", "SOAP_WebMethod_Pattern", "Worker_ServiceThread_Pattern")

#### 3b. Explorar Codebase

Lancar agentes Explore (ate 3 em paralelo) para investigar o codebase. As buscas devem cobrir:

**Delphi (Aplicacoes/BackOfficeDelphi/):**
- Forms afetados: `**/*KEYWORD*.pas`, `**/*KEYWORD*.dfm`
- Data modules: buscar queries SQL, datasets, stored procedures referenciadas
- Validacoes existentes: buscar metodos como `Validate`, `BeforePost`, `AfterPost`
- Combos/Grids: entender como dados sao populados

**SQL (Scripts/BackOffice/ e Aplicacoes/SQLBackOffice/):**
- Stored procedures: `**/*KEYWORD*.sql`, `**/P{MOD}_*.sql`
- Tabelas envolvidas: grep por nomes de tabela (TFIN_, TCOM_, TGEN_, TEST_, etc.)
- Scripts de versao: verificar se ha implementacoes recentes relacionadas

**.NET (quando aplicavel):**
- WebServices: `Aplicacoes/Webservices/`
- APIs REST: `Aplicacoes/KPL.ONCLICK.Api/`

#### 3c. Identificar o que precisa mudar

Para cada PBI, documentar:
- **Arquivos a alterar**: paths completos dos .pas, .dfm, .sql
- **Queries a modificar**: nome do dataset/query e SQL atual
- **Tabelas envolvidas**: com campos relevantes
- **Padroes reutilizaveis**: implementacoes similares ja existentes no codebase
- **Riscos/Edge cases**: fallbacks necessarios, impactos em outras telas

### Passo 4: Calcular Estimativa

Com base na analise do Passo 3, estimar as horas usando estas heuristicas como referencia:

| Tipo de alteracao | Faixa de horas |
|---|---|
| Validacao simples em 1 form Delphi (ex: bloquear acao) | 2-4h |
| Filtro em combo/query + evento de refresh | 4-6h |
| Replicacao de padrao existente para outro modulo | 4-6h |
| Alteracao em SP existente + form Delphi | 6-8h |
| Nova tabela + CRUD + associacao em form existente | 8-12h |
| Novo webservice/API SOAP | 12-20h |
| Novo worker/servico AbacosService | 16-24h |
| Integracao com sistema externo | 20-40h |

Adicionar a cada estimativa:
- +1-2h por tela adicional afetada para testes manuais
- +2h se envolver alteracao de schema (nova tabela, ALTER TABLE)
- +1h para script de migracao/versao

**SEMPRE usar o valor MAIS ALTO da faixa estimada** (ceiling). Isso garante margem para imprevistos.

### Passo 5: Gerar Descricao Tecnica HTML

Montar um HTML estruturado com a analise tecnica. Este conteudo sera usado tanto na aba Dev do PBI quanto na description da Task.

Template:

```html
<div>
  <h3>Alteracoes Previstas - [descricao curta]</h3>
  <p><b>Problema:</b> [descricao do problema atual]</p>
  <p><b>Solucao:</b> [descricao da solucao proposta, incluindo fallbacks]</p>
  <p><b>Arquivos a alterar:</b></p>
  <ul>
    <li><b>[arquivo1.pas/.dfm]</b> - [o que mudar neste arquivo]</li>
    <li><b>[arquivo2.sql]</b> - [o que mudar neste arquivo]</li>
  </ul>
  <p><b>Tabelas:</b> [lista de tabelas com campos relevantes]</p>
  <p><b>Estimativa: [X] horas</b></p>
</div>
```

A descricao deve ser em portugues (pt-BR), concisa mas tecnica o suficiente para lembrar o que precisa ser feito.

### Passo 6: Atualizar PBI no Azure DevOps

Usar `mcp__azure-devops__wit_update_work_item` com:
- id: ID do PBI
- updates:
  1. `/fields/Microsoft.VSTS.Scheduling.Effort` = horas estimadas (numero inteiro)
  2. `/fields/Custom.578f70b4-505a-4b78-8ae7-6a18e68b14ec` = HTML tecnico do Passo 5

O campo `Custom.578f70b4-505a-4b78-8ae7-6a18e68b14ec` e o campo da aba "Dev" no formulario do PBI (label: "Conclusao da analise origem do bug", tipo HtmlFieldControl).

### Passo 7: Criar Task Filha

Usar `mcp__azure-devops__wit_add_child_work_items` com:
- parentId: ID do PBI
- project: "KPL"
- workItemType: "Task"
- items: array com 1 item:
  - title: "Desenvolver - [descricao curta extraida do titulo do PBI, sem o prefixo #XXXX-XXXXXX e sem [ORCAR HORAS]]"
  - description: mesmo HTML do Passo 5
  - iterationPath: mesmo IterationPath do PBI pai

Apos criar a task, atualizar as horas via `mcp__azure-devops__wit_update_work_item`:
- id: ID da task recem-criada (extrair do response)
- updates:
  1. `/fields/Microsoft.VSTS.Scheduling.OriginalEstimate` = horas estimadas
  2. `/fields/Microsoft.VSTS.Scheduling.RemainingWork` = horas estimadas

### Passo 8: Relatorio Final

Apresentar ao usuario uma tabela resumo:

```
| PBI | Desk | Descricao | Effort | Task ID |
|-----|------|-----------|--------|---------|
| XXXXX | XXXX-XXXXXX | descricao curta | Xh | YYYYY |
```

E para cada item, um resumo de 2-3 linhas do que precisa ser feito.

---

## Processamento em Lote

Quando multiplos IDs sao fornecidos:

1. **Paralelo**: Buscar todos os work items do DevOps e Desk Manager em paralelo (Passos 1-2)
2. **Sequencial/Paralelo**: Explorar codebase — se os items sao do mesmo modulo, agrupar a exploracao. Se sao de modulos diferentes, lancar agentes em paralelo (Passo 3)
3. **Paralelo**: Atualizar todos os PBIs e criar tasks em paralelo (Passos 6-7)
4. **Relatorio**: Tabela consolidada com todos os itens

---

## Notas Importantes

- **Projeto DevOps**: sempre "KPL"
- **Idioma**: todas as descricoes em portugues (pt-BR)
- **Formato**: usar HTML (nao Markdown) para campos do DevOps
- **Codebase**: localizado em `F:\DEV\adriano.calligioni\KPL\`
  - Delphi: `Aplicacoes/BackOfficeDelphi/`
  - SQL SPs: `Aplicacoes/SQLBackOffice/`
  - SQL Scripts: `Scripts/BackOffice/`
  - .NET: `Aplicacoes/Webservices/`, `Aplicacoes/KPL.ONCLICK.Api/`
- **Convencoes de nomenclatura Delphi KPL**:
  - `_M.pas` = Maintenance (formulario de edicao)
  - `_P.pas` = Pesquisa (formulario de busca)
  - `_L.pas` = Lista/consulta
  - `_D.pas` = DataModule (acesso a dados)
  - `_B.pas` = Botoes/acoes
- **Prefixos de tabelas SQL**:
  - `TFIN_` = Financeiro
  - `TCOM_` = Comercial
  - `TGEN_` = Generico
  - `TEST_` = Estoque
  - `TCPR_` = Compras
  - `TFIS_` = Fiscal
- **Prefixos de SPs**:
  - `PFIN_` = Financeiro
  - `PCOM_` = Comercial
  - `PGEN_` = Generico
  - `PEST_` = Estoque
  - `PCPR_` = Compras
- **Nunca sobrescrever Effort sem avisar** se o PBI ja tiver horas preenchidas
- **Encoding**: arquivos SQL do repo sao ISO-8859-1 (Latin1). Se precisar ler conteudo SQL, estar ciente do encoding
