# Sistema de Tags de Configuração (TINT_TAGINT / TINT_INTCFG)

## Visão Geral do Sistema de Tags

O KPL possui um mecanismo de configuração dinâmica baseado em "tags" armazenadas no banco de dados. Tags configuram o comportamento de interfaces de integração (importação/exportação de dados, webservices, NFe, logística, etc.). Cada interface pode ter dezenas de tags que controlam aspectos como usuário padrão, transportadora, representante, regras de processamento, etc.

**Arquitetura**:
- **TINT_TAGINT** — Definições de tags (840+ registros): metadados, tipo de dado, componente UI, SQL de lookup, validação, ajuda
- **TINT_INTCFG** — Valores configurados por interface: liga cada tag a uma interface específica com seu valor tipado
- **TINT_INTFAC** — Interfaces de integração: cada interface (ex: "Web Services Plataforma", "APIECOMM HUB - MELI") tem seu conjunto de tags
- **TINT_INTGRP** — Grupos de tags: agrupamento lógico (ex: "GERAL", "SAÍDA DE PRODUTOS", "ENTRADA DE PEDIDOS")

**Como tags são lidas no código**:
- SQL: Funções `FRPL_S_TAGCHR`, `FRPL_S_TAGSTR`, `FRPL_S_TAGINT`, `FRPL_S_TAGTXT`, `FRPL_S_TAGDAT`, `FRPL_S_TAGVAL`
- Delphi: `TWSUtilsNET.DBTag()` em `WSUtilsNET.pas`
- C#: Classe `TagConfig` em `InterfaceConfig.cs`

## Quando Documentar Tags

- Ao documentar a tela **RPLCFG_INTFAC** (Configuração de Interfaces)
- Ao documentar qualquer tela que consome tags (detectado no código-fonte)
- Quando o usuário solicitar `/kpl-tags`
- Como referência cruzada ao documentar telas de módulos que usam interfaces de integração

## Processo de Documentação de Tags

### Tag Step 1: Extrair tags do banco via MCP SQL Server

Query principal (usar `mcp__sqlserver__execute_query`):

```sql
SELECT
    T.TAGI_COD,
    T.TAGI_TAG,
    T.TAGI_NME,
    T.TAGI_NME_PAI,
    T.TAGI_TXT_OBS,
    T.TAGI_CHR_TIP,
    T.TAGI_CHR_TIPCMP,
    T.TAGI_SQL_LKP,
    T.TAGI_FLD_LKPVAL,
    T.TAGI_FLD_LKPDES,
    T.TAGI_CHR_TIPVLD,
    T.TAGI_TAM_MAX,
    T.TAGI_STR_MSK,
    T.TAGI_NRO_ORDAPR,
    G.INTG_COD,
    G.INTG_NME
FROM ABACOS_ONCLKON.dbo.TINT_TAGINT T WITH (NOLOCK)
LEFT JOIN ABACOS_ONCLKON.dbo.TINT_INTGRP G WITH (NOLOCK) ON T.INTG_COD = G.INTG_COD
ORDER BY G.INTG_NME, T.TAGI_NRO_ORDAPR, T.TAGI_TAG
```

**Nota**: O MCP SQL Server está conectado ao banco `DWKPL`. As tabelas TINT_* estão nos bancos `ABACOS_*`. Usar referência cross-database: `ABACOS_ONCLKON.dbo.TINT_TAGINT`.

**Fallback sem banco**: Se o MCP SQL Server não estiver disponível, extrair definições de tags dos scripts SQL do repositório:
```
Glob: **/SQLBackOffice/Integracao/Replicacao/PRPL_C_INTCFG*.sql
```
Esses scripts contêm chamadas a `PRPL_C_TAGINT` com todos os parâmetros de cada tag.

### Tag Step 2: Extrair interfaces e contagem de tags

```sql
SELECT
    F.INTF_COD,
    F.INTF_NOM,
    F.INTF_COD_TIP,
    COUNT(C.INTC_COD) AS QTD_TAGS
FROM ABACOS_ONCLKON.dbo.TINT_INTFAC F WITH (NOLOCK)
LEFT JOIN ABACOS_ONCLKON.dbo.TINT_INTCFG C WITH (NOLOCK) ON F.INTF_COD = C.INTF_COD
WHERE F.INTF_DAT_FIM IS NULL
GROUP BY F.INTF_COD, F.INTF_NOM, F.INTF_COD_TIP
ORDER BY F.INTF_NOM
```

### Tag Step 3: Extrair tags associadas a cada interface

```sql
SELECT
    C.INTF_COD,
    F.INTF_NOM,
    T.TAGI_TAG,
    T.TAGI_NME,
    T.TAGI_TXT_OBS,
    C.INTC_INT,
    C.INTC_CHR,
    C.INTC_STR,
    C.INTC_TXT
FROM ABACOS_ONCLKON.dbo.TINT_INTCFG C WITH (NOLOCK)
INNER JOIN ABACOS_ONCLKON.dbo.TINT_TAGINT T WITH (NOLOCK) ON C.TAGI_COD = T.TAGI_COD
INNER JOIN ABACOS_ONCLKON.dbo.TINT_INTFAC F WITH (NOLOCK) ON C.INTF_COD = F.INTF_COD
WHERE F.INTF_DAT_FIM IS NULL
ORDER BY F.INTF_NOM, T.TAGI_TAG
```

### Tag Step 4: Mapear tipos para linguagem humana

| TAGI_CHR_TIP | Tipo de Dado | Coluna em INTCFG |
|---|---|---|
| I | Número inteiro | INTC_INT |
| C | Caractere (S/N, flag) | INTC_CHR |
| S | Texto curto (até 255 chars) | INTC_STR |
| T | Texto longo (até 8000 chars) | INTC_TXT |
| D | Data | INTC_DAT |
| V | Valor numérico (decimal) | INTC_VAL |

| TAGI_CHR_TIPCMP | Controle na Tela |
|---|---|
| 1 | Campo de texto livre (Edit) |
| 2 | Seletor de data (DateEdit) |
| 3 | Lista suspensa com opções pré-definidas (ComboEdit) |
| 4 | Campo de busca com consulta ao banco (LookupCombo) |
| 5 | Caixa de marcação Sim/Não (CheckBox) |
| 6 | Lista de dados com seleção múltipla (DataList) |
| 7 | Dia e Mês |
| 8 | Mês e Ano |
| 9 | Campo monetário (CurrencyEdit) |
| M | Campo de texto multilinha (Memo) |

| TAGI_CHR_TIPVLD | Validação |
|---|---|
| 0 | Sem validação |
| 1 | Somente números |
| 2 | Letras e números |
| 3 | Números e vírgula |
| 4 | Sem espaços |
| 5 | Somente inteiros |

### Tag Step 5: Gerar documentação por prefixo

Agrupar tags pelo prefixo (parte antes do primeiro underscore em TAGI_TAG). Prefixos principais:

| Prefixo | Descrição | Qtd |
|---------|-----------|-----|
| EXPPRO | Exportação de Produtos | 97 |
| IMPPDS | Importação de Pedidos | 93 |
| IMPPRO | Importação de Produtos | 82 |
| EXPNFE | Exportação NFe | 59 |
| EXPGNR | Exportação GNRE | 57 |
| IMPOUT | Importação Outros | 35 |
| INTLGT | Integração Logística | 34 |
| EXPOUT | Exportação Outros | 31 |
| IMPNOT | Importação Notas | 28 |
| EXPPDS | Exportação Pedidos | 23 |

Para cada prefixo, gerar uma seção com todas as tags daquele grupo.

### Tag Step 6: Gerar documentação por interface

Para cada interface ativa, listar suas tags configuradas com valores atuais.

### Tag Step 7: Detectar uso no código-fonte

Para cada tag documentada, buscar no codebase onde ela é consumida:
```
Grep: pattern = "'{TAGI_TAG}'" (busca a tag entre aspas simples)
```
Registrar os arquivos .SQL, .pas, .cs que referenciam a tag.

## Template de Catálogo de Tags

```markdown
# Catálogo de Tags de Configuração — KPL

> Gerado em: {data}
> Total de tags: {N}
> Total de grupos: {G}
> Total de interfaces ativas: {I}

## Índice por Prefixo

| Prefixo | Descrição | Qtd Tags |
|---------|-----------|----------|
| EXPPRO | Exportação de Produtos | 97 |
| IMPPDS | Importação de Pedidos | 93 |
| ... | ... | ... |

---

## Tags por Grupo

### {INTG_NME} (Grupo {INTG_COD})

| Tag | Nome | Tipo | Controle | Descrição | Tam. Max |
|-----|------|------|----------|-----------|----------|
| {TAGI_TAG} | {TAGI_NME} | {tipo_humano} | {controle_humano} | {TAGI_TXT_OBS} | {TAGI_TAM_MAX} |

#### Detalhes das tags com lookup

##### {TAGI_TAG} — {TAGI_NME}

- **Propósito**: {TAGI_TXT_OBS em linguagem simples}
- **Tipo de dado**: {tipo_humano}
- **Como preencher**: {controle_humano} — {se lookup: "Selecione um valor da lista. A lista busca: {descrição do que TAGI_SQL_LKP consulta}"}
- **Validação**: {TAGI_CHR_TIPVLD descrito}
- **Tamanho máximo**: {TAGI_TAM_MAX}
- **Máscara**: {TAGI_STR_MSK se houver}
- **Onde é usado no código**: {lista de arquivos que referenciam esta tag}

---

## Tags por Interface

### {INTF_NOM} (Código {INTF_COD})

> Tags configuradas: {N}

| Tag | Nome | Valor Atual | Descrição |
|-----|------|-------------|-----------|
| {TAGI_TAG} | {TAGI_NME} | {valor} | {TAGI_TXT_OBS} |
```

## Prefixos Conhecidos

Mapeamento de prefixos para descrições humanas:

| Prefixo | Descrição |
|---------|-----------|
| AGT | Agendador de Tarefas |
| AGTCAN | Agendador - Cancelamento Automático |
| AGTVLDMOV | Agendador - Validação Movimentação |
| AUTCUR | Atualização de Curadoria/Troca |
| CANTRD | Cancelamento de Troca |
| CERDIG | Certificado Digital |
| CONGTW | Configuração Gateway Pagamento |
| CORLR | Correios/Leader |
| DEBCAR | Débito em Cartão |
| EMLENV | E-mail Envio |
| ENVEML | Envio de E-mail |
| ENVSMS | Envio de SMS |
| EXPC | Exportação Complementar |
| EXPCLI | Exportação de Clientes |
| EXPEST | Exportação de Estoque |
| EXPGNR | Exportação GNRE |
| EXPNFE | Exportação NFe |
| EXPNOT | Exportação de Notas |
| EXPOUT | Exportação Outros |
| EXPPDC | Exportação Pedido Compra |
| EXPPDS | Exportação de Pedidos |
| EXPPRE | Exportação de Preço |
| EXPPRO | Exportação de Produtos |
| EXPPDV | Exportação PDV |
| EXPSTA | Exportação de Status |
| FASPRO | Fascinação/Processamento |
| FATAPI | Faturamento via API |
| GERARQ | Geração de Arquivos |
| ICLCLI | iCliniq Cliente |
| ICLSER | iCliniq Serviço |
| IMPARQ | Importação de Arquivos |
| IMPCLI | Importação de Clientes |
| IMPCNB | Importação CNAB |
| IMPEST | Importação de Estoque |
| IMPNOT | Importação de Notas |
| IMPOUT | Importação Outros |
| IMPPDS | Importação de Pedidos |
| IMPPDV | Importação PDV |
| IMPPRE | Importação de Preço |
| IMPPRO | Importação de Produtos |
| IMPTED | Importação TED |
| INTANARIS | Integração Análise de Risco |
| INTDWS | Integração Data WebService |
| INTLGT | Integração Logística |
| INTLOG | Integração Log |
| KORMECI | Komerci (Rede) |
| LEADER | Leader Transportes |
| MULCOD | Multi-Código |
| PDSCOM | Pedidos Comerciais |
| PRODES | Processamento/Despacho |
| REDECAR | Redecard |
| SAIOUT | Saída Outros |
| SPED | SPED Fiscal |
| SRVIMP | Serviço de Importação |
| TOTALEX | Total Express |
| TRNFTP | Transferência FTP |
| TRSFTP | Transferência SFTP |
| VAP | VAP |
| WEBSVC | WebService Config |

## Banco de Dados de Tags (tags-db.json)

O arquivo `.claude/skills/kpl-user-docs/tags-db.json` rastreia a documentação de tags de configuração, complementando o `screens-db.json` que rastreia telas.

**Localização**: `.claude/skills/kpl-user-docs/tags-db.json`

### Schema

```json
{
  "version": 1,
  "last_scan": "ISO-8601 timestamp do último scan de tags",
  "tags": {
    "IMPPDS_USUSIS": {
      "tagi_cod": 123,
      "tagi_tag": "IMPPDS_USUSIS",
      "tagi_nme": "Usuário do sistema",
      "prefix": "IMPPDS",
      "group_cod": 7,
      "group_name": "ENTRADA DE PEDIDOS",
      "data_type": "I",
      "component_type": "4",
      "has_lookup": true,
      "help_text": "Texto de ajuda da tag",
      "code_references": ["arquivo1.SQL", "arquivo2.cs"],
      "interfaces": [9, 13],
      "doc_status": "documented|pending",
      "doc_date": "2026-03-26"
    }
  },
  "groups": {
    "1": { "intg_cod": 1, "intg_nme": "GERAL", "tag_count": 15 }
  },
  "interfaces": {
    "9": { "intf_cod": 9, "intf_nom": "Web Services Plataforma", "tag_count": 155 }
  },
  "prefixes": {
    "EXPPRO": { "count": 97, "description": "Exportação de Produtos" }
  },
  "stats": {
    "total_tags": 840,
    "total_groups": 41,
    "total_interfaces": 15,
    "documented": 0,
    "with_code_refs": 0,
    "orphan_tags": 0
  }
}
```

### Atualização do tags-db.json

**Sempre** que o comando `/kpl-tags` for executado:

1. Ler o tags-db.json atual (se existir)
2. Para cada tag documentada, atualizar/criar entrada com todos os campos
3. Recalcular `stats`
4. Salvar com `last_scan` atualizado

Se o tags-db.json não existir, criar com a estrutura acima.

### Integração com screens-db.json

Quando uma tela é documentada (via Passos 1-8) e tags são detectadas (via Step 5.5):
1. Atualizar o `screens-db.json` normalmente
2. No `tags-db.json`, adicionar a tela como referência nas tags detectadas (campo `code_references`)
3. Isso permite rastrear quais telas consomem quais tags
