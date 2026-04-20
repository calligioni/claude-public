---
name: kpl-legacy-manager
description: >
  Skill para manutenção e evolução do produto legado KPL. Analisa código-fonte
  Delphi 5, .NET Framework 4.5 e esquema SQL Server no repositório local. Use
  quando precisar de inventário de código, análise estática, sugestões de
  refatoração, relatórios do banco de dados, scripts de migração ou geração de
  testes. Comandos - /kpl-inventario, /kpl-db-report, /kpl-refactor-sugestoes,
  /kpl-gerar-migration. Requer MCP server configurado apontando para o
  repositório e conexão SQL Server em modo leitura.
user-invocable: true
tools: Bash, Read, Glob, Grep, Write, Edit
memory: project
effort: high
triggers:
  - "/kpl-inventario"
  - "/kpl-db-report"
  - "/kpl-refactor-sugestoes"
  - "/kpl-gerar-migration"
  - "analyze KPL"
  - "legacy code analysis"
  - "análise código legado"
---

# KPL Legacy Manager

Skill para análise, manutenção e evolução do produto legado KPL (Delphi 5, .NET 4.5, SQL Server).

## Configuração

### Pré-requisitos

1. **MCP Server** configurado apontando para `F:\dev\adriano.calligioni\kpl`
2. **Conexão SQL Server** em modo somente-leitura (salvo autorização explícita para escrita)
3. **Ferramentas MCP disponíveis**: leitura de arquivos, análise estática, conexão SQL

### Variáveis de Configuração

| Variável | Descrição | Padrão |
|----------|-----------|--------|
| `REPO_PATH` | Caminho do repositório | `F:\dev\adriano.calligioni\kpl` |
| `DB_CONNECTION` | String de conexão SQL Server | Somente leitura |
| `LOG_PATH` | Caminho para logs | `./kpl-analysis.log` |

## Comandos Disponíveis

### `/kpl-inventario`
Gera inventário completo do repositório.

**Workflow:**
1. Listar arquivos por extensão (.pas, .dpr, .cs, .vb, .sql)
2. Mapear projetos/soluções .NET e dependências
3. Identificar pontos críticos (BDE, ADO antigo, DLLs externas)
4. Gerar sumário com métricas e 3 ações recomendadas

### `/kpl-db-report`
Relatório do esquema do banco e problemas identificados.

**Workflow:**
1. Extrair esquema via MCP (tabelas, índices, FKs, procedures)
2. Identificar problemas (FKs faltando, colunas sem índice, tipos obsoletos)
3. Gerar diagrama ER simplificado (texto)
4. Listar recomendações priorizadas

### `/kpl-refactor-sugestoes <area>`
Sugestões de refatoração por módulo/pasta.

**Workflow:**
1. Analisar código na área especificada
2. Aplicar regras de análise (ver [references/delphi-rules.md](references/delphi-rules.md) e [references/dotnet-rules.md](references/dotnet-rules.md))
3. Priorizar por risco (Alta/Média/Baixa) e estimar esforço
4. Gerar lista de ações com justificativa

### `/kpl-gerar-migration <nome>`
Gera esqueleto de script de migração SQL.

**⚠️ REQUER CONFIRMAÇÃO antes de qualquer execução.**

**Workflow:**
1. Analisar diferenças de schema solicitadas
2. Gerar script em modo rascunho
3. Apresentar para revisão humana
4. Aguardar confirmação explícita antes de executar

## Regras de Segurança

**TODAS as operações de escrita requerem confirmação humana explícita:**
- Commits e pushes
- Execução de scripts de migração
- Alterações no banco de dados
- Modificação de arquivos

Antes de qualquer ação mutável, apresentar:
```
⚠️ CONFIRMAÇÃO NECESSÁRIA
Ação: [descrição]
Impacto: [detalhes]
Digite 'CONFIRMAR' para prosseguir ou 'CANCELAR' para abortar.
```

## Análise Estática

### Regras Delphi
Ver [references/delphi-rules.md](references/delphi-rules.md) para regras completas.

**Principais verificações:**
- Código morto (funções/procedures não utilizadas)
- Vazamentos de memória (Create sem Free)
- Uso de componentes BDE (obsoletos)
- Strings sem tratamento de encoding
- Acesso direto a banco sem transação

### Regras .NET 4.5
Ver [references/dotnet-rules.md](references/dotnet-rules.md) para regras completas.

**Principais verificações:**
- APIs obsoletas (WebClient, ArrayList)
- Async patterns ausentes em I/O
- Binding de dados sem INotifyPropertyChanged
- Exceptions genéricas (catch Exception)
- String concatenation em loops

## Análise de Banco de Dados

Ver [references/sql-analysis.md](references/sql-analysis.md) para guia completo.

**Verificações principais:**
- Tabelas sem chave primária
- FKs ausentes em relacionamentos óbvios
- Colunas sem índice em JOINs frequentes
- Procedures com SQL dinâmico vulnerável
- Tipos de dados obsoletos (text, image)

## Formato de Saída

### Sumário de Inventário
```
=== KPL INVENTÁRIO ===
Data: [timestamp]

📊 MÉTRICAS
- Arquivos Delphi: X (.pas: N, .dpr: M)
- Arquivos .NET: Y (.cs: N, .vb: M)
- Scripts SQL: Z
- Projetos/Soluções: N

⚠️ PONTOS CRÍTICOS
1. [descrição] - Risco: [Alto/Médio/Baixo]
2. [descrição] - Risco: [Alto/Médio/Baixo]
3. [descrição] - Risco: [Alto/Médio/Baixo]

🎯 AÇÕES RECOMENDADAS
1. [ação prioritária]
2. [segunda ação]
3. [terceira ação]
```

### Relatório de Problemas
```
=== PROBLEMA IDENTIFICADO ===
Tipo: [categoria]
Arquivo/Objeto: [localização]
Risco: [Alto/Médio/Baixo]
Esforço estimado: [horas/dias]
Descrição: [detalhes]
Sugestão: [como resolver]
```

## Geração de Testes

Ao sugerir testes, gerar:
1. **Unit tests** onde aplicável (Delphi: DUnit, .NET: MSTest/NUnit)
2. **Checklist de QA** para validação manual
3. **Steps de validação** para mudanças de schema

## Logs e Rastreabilidade

A skill gera logs em formato estruturado:
```
[TIMESTAMP] [LEVEL] [ACTION] [DETAILS]
```

**Níveis:** INFO, WARN, ERROR, AUDIT

**IMPORTANTE:** Logs não contêm credenciais ou dados sensíveis.

## Riscos e Limitações

| Risco | Mitigação |
|-------|-----------|
| Analisadores externos não disponíveis | Usar heurísticas textuais |
| Timeout em repositórios grandes | Análise incremental por módulo |
| Schema complexo | Priorizar tabelas principais |
| Código ofuscado | Reportar como não analisável |

## Exemplo de Uso

**Usuário:** `/kpl-inventario`

**Resposta esperada:**
```
Analisando repositório F:\dev\adriano.calligioni\kpl...

=== KPL INVENTÁRIO ===
Data: 2026-01-22 10:30:00

📊 MÉTRICAS
- Arquivos Delphi: 342 (.pas: 320, .dpr: 22)
- Arquivos .NET: 156 (.cs: 140, .vb: 16)
- Scripts SQL: 89
- Projetos/Soluções: 8

⚠️ PONTOS CRÍTICOS
1. 15 units usando BDE - Risco: Alto
2. 8 procedures com SQL dinâmico - Risco: Alto
3. 23 classes sem tratamento de exceção - Risco: Médio

🎯 AÇÕES RECOMENDADAS
1. Migrar componentes BDE para ADO/dbExpress
2. Parametrizar queries em procedures críticas
3. Adicionar try/finally em operações de I/O
```
