---
name: kpl-user-docs
description: Gera documentação de usuário final para telas do sistema KPL e catálogo de tags de configuração (TINT_TAGINT/TINT_INTCFG) a partir do código-fonte Delphi e banco de dados. Use quando o usuário pedir documentação, manual, help, guia de uso, tutorial, referência de tela ou tags de configuração do sistema. Também dispara quando o usuário mencionar "documentar tela", "como funciona a tela X", "gerar manual", "doc de usuário", "tags de configuração", "catálogo de tags", "configuração de interface", "TINT_TAGINT", ou quiser entender o que uma tela faz do ponto de vista operacional. Comandos de gestão: /kpl-scan (escanear telas do menu), /kpl-status (progresso da documentação), /kpl-next (próxima tela a documentar), /kpl-doc-all (documentar todo o sistema ou módulo), /kpl-plan (planejar divisão em lotes para agentes paralelos), /kpl-tags (gerar catálogo de tags de configuração).
---

# KPL User Documentation Generator

Gera documentação de nível usuário final para telas do aplicativo Delphi KPL, analisando diretamente o código-fonte (DFM, PAS, SQL).

## Quando usar

- Usuário pede documentação/manual de uma tela
- Usuário quer entender como usar uma funcionalidade
- Necessidade de gerar guia operacional para treinamento
- Documentação de referência de campos e regras de negócio
- Documentar tags de configuração de interfaces de integração
- Gerar catálogo de referência de tags (TINT_TAGINT)

## Processo

### 1. Identificar a tela-alvo

O usuário pode fornecer:
- Nome da unit Delphi (ex: `GENCAD_ENTEND_M`)
- Nome funcional (ex: "Cadastro de Endereço", "Tela de Cliente")
- Módulo (ex: "Genérico", "Comercial", "Estoque")

Se o nome for funcional, buscar no codebase:
```
Glob: **/Aplicacoes/BackOfficeDelphi/**/*_M.dfm
Grep: Caption = '<termo buscado>'
```

### 2. Coletar os arquivos-fonte

Para cada tela `{UNIT}_M`, coletar a cadeia completa:

| Arquivo | Papel | Como encontrar |
|---------|-------|----------------|
| `{UNIT}_M.dfm` | Layout visual (posições, labels, campos) | Arquivo principal da tela |
| `{UNIT}_M.pas` | Lógica da tela (eventos, validações, atalhos) | Mesmo diretório |
| `{UNIT}_D.dfm` | DataModule (SQL selects, params, campos) | Procurar no PAS quais DataModules são usados |
| `{UNIT}_D.pas` | Lógica do DataModule (regras antes de salvar) | Mesmo diretório do D.dfm |
| `*.SQL` | Stored procedures chamadas | Extrair de InsertStProc/UpdateStProc no DFM |
| Tags de config | Tags de integração usadas pela tela | Buscar refs a `FRPL_S_TAG*` / `DBTag(` nos PAS/SQL |

Atenção: telas podem herdar DataModules de outros módulos. Verificar a cláusula `uses` do PAS e procurar por referências a `TFrm*_D` para encontrar todos os DataModules envolvidos.

### 3. Extrair informações do DFM (Layout)

Ler o DFM da tela (`_M.dfm`) e extrair:

#### 3.1 Informações gerais
- `Caption` do form → título da tela
- `ClientWidth` / `ClientHeight` → dimensões para o mockup
- Herança (`inherited`) → indica que é subform

#### 3.2 Campos editáveis
Para cada `TdxDBEdit`, `TRxDBComboBox`, `TMxDBLookupCombo`, `TMxDBComboBox`, `TNSDBStaticText`:
- **Nome do controle** (ex: `edtENTE_CEP`)
- **Label associado** → procurar o TLabel mais próximo à esquerda com `Top` similar (±5px)
- **DataField** → nome do campo no banco
- **DataSource** → qual dataset alimenta
- **TabOrder** → ordem de navegação
- **Required** (se definido no campo do dataset)
- Para combos: **Items.Strings** e **Values.Strings** → opções disponíveis

#### 3.3 Botões e ações
- Toolbar buttons (TBX items)
- Ações do `fdrMain` (insert, save, cancel, close, etc.)

#### 3.4 Construir mapa de posições
Montar lista: `(Left, Top, Width, Label, ControlType, DataField)` ordenada por Top, depois Left.

### 4. Extrair informações do PAS (Lógica)

#### 4.1 Atalhos de teclado
Procurar no `FormKeyDown` ou handlers de `OnKeyPress`/`OnKeyDown`:
- Teclas F1-F12 e suas funções
- Combinações Ctrl+, Shift+, Alt+

#### 4.2 Validações
Procurar em procedures de validação (`Validate`, `BeforePost`, `BeforeExecProc`):
- Campos obrigatórios (`.Required := True`, `raise Exception`)
- Regras de negócio (condições IF/THEN com raise)
- Formatações automáticas

#### 4.3 Comportamentos automáticos
- `NewRecord` → valores padrão ao inserir
- `AfterPost` → ações após salvar
- `StateChange` → campos habilitados/desabilitados conforme estado

### 5. Extrair informações do SQL (Regras do banco)

Ler a stored procedure referenciada em `InsertStProc`/`UpdateStProc`:
- Validações server-side (RAISERROR)
- Campos com tratamento especial (formatação de CEP, etc.)
- Dependências entre tabelas

### 5.5 Detectar Tags de Configuração Relacionadas

Verificar se a tela consome ou configura tags de interface. Usar três níveis de detecção:

#### Tier 1 — Referência direta no código da tela

Nos arquivos PAS e SQL da tela, buscar por:
```
Grep: FRPL_S_TAGCHR|FRPL_S_TAGSTR|FRPL_S_TAGINT|FRPL_S_TAGTXT|FRPL_S_TAGDAT|FRPL_S_TAGVAL
Grep: DBTag(
Grep: TINT_TAGINT|TINT_INTCFG
```

Para cada referência encontrada, extrair o nome da tag (string entre aspas simples no segundo argumento da função).

#### Tier 2 — Stored procedures da tela

Se a tela chama stored procedures (`InsertStProc`/`UpdateStProc` do DFM), verificar se essas procedures referenciam funções `FRPL_S_TAG*`. Muitas telas não referenciam tags diretamente, mas suas SPs sim.

```
Grep nos arquivos SQL das procedures: FRPL_S_TAG
```

#### Tier 3 — Correlação por módulo/interface

Para telas do módulo de Integração/Replicação, consultar via MCP SQL Server:

```sql
SELECT T.TAGI_TAG, T.TAGI_NME, T.TAGI_TXT_OBS
FROM ABACOS_ONCLKON.dbo.TINT_INTCFG C WITH (NOLOCK)
INNER JOIN ABACOS_ONCLKON.dbo.TINT_TAGINT T WITH (NOLOCK) ON C.TAGI_COD = T.TAGI_COD
INNER JOIN ABACOS_ONCLKON.dbo.TINT_INTFAC F WITH (NOLOCK) ON C.INTF_COD = F.INTF_COD
WHERE F.INTF_COD_TIP = {tipo_interface_relevante}
ORDER BY T.TAGI_TAG
```

#### Caso especial: RPLCFG_INTFAC

A tela de **Configuração de Interfaces** (`RPLCFG_INTFAC`) exibe TODAS as tags da interface selecionada de forma dinâmica. Os campos de configuração mudam conforme a interface selecionada. Ao documentar esta tela:
- Referenciar o catálogo completo de tags
- Explicar que o formulário é gerado dinamicamente a partir de TINT_TAGINT
- Documentar os tipos de controle possíveis (Edit, Combo, CheckBox, etc.)
- Indicar que o help text vem de TAGI_TXT_OBS

#### Resultado do Step 5.5

Montar lista de tags detectadas: `(TAGI_TAG, TAGI_NME, TAGI_TXT_OBS, tier_de_detecção)` para uso no Step 7.

### 6. Gerar o mockup ASCII da tela

Usar as posições extraídas do DFM para criar uma representação visual. Regras:

```
┌─────────────────────────────────────────────────────┐
│  Título da Tela                                      │
├─────────────────────────────────────────────────────┤
│                                                      │
│   Label:  [__campo_editável__]                       │
│                                                      │
│   Label:  [▼ combo_box_______]                       │
│                                                      │
│   Label:  [campo_somente_leitura]                    │
│                                                      │
└─────────────────────────────────────────────────────┘
```

Convenções:
- `[__texto__]` → campo editável (TdxDBEdit)
- `[▼ texto]` → combo/lookup (TRxDBComboBox, TMxDBLookupCombo)
- `[texto]` → campo somente leitura (TNSDBStaticText)
- Agrupar controles que estão na mesma linha (Top similar ±5px)
- Escala: ~6 caracteres por 100px de largura

### 7. Gerar a documentação Markdown

Usar a seguinte estrutura:

```markdown
# {Título da Tela}

> **Módulo**: {módulo}
> **Acesso**: {como chegar na tela, se identificável}

## Visão geral
{Descrição em 2-3 frases do propósito da tela, em linguagem simples}

## Layout da tela
{Mockup ASCII}

## Campos e controles

| Campo | Descrição | Tipo | Obrigatório | Observações |
|-------|-----------|------|:-----------:|-------------|
| {label} | {o que o campo armazena} | {Texto/Número/Data/Lista} | {Sim/Não} | {regras, formato, valores possíveis} |

## Atalhos de teclado

| Tecla | Função |
|-------|--------|
| F9 | {descrição} |

## Como cadastrar (Inserir)
1. Clique em **Inserir** na barra de ferramentas
2. Preencha os campos:
   - **{Campo}**: {orientação}
3. Clique em **Salvar**

## Como alterar
1. Selecione o registro desejado
2. Modifique os campos necessários
3. Clique em **Salvar**

## Como excluir
1. Selecione o registro desejado
2. Clique em **Excluir**
3. Confirme a operação

## Regras de negócio
- {regra extraída do código, em linguagem simples}

## Tags de configuração relacionadas

{SEÇÃO CONDICIONAL — incluir SOMENTE se o Step 5.5 detectou tags. Caso contrário, omitir completamente.}

Esta tela utiliza tags de configuração de interface para personalizar seu comportamento.
As tags são configuradas na tela **Configuração de Interfaces** (Menu: Integração > Replicação > Configuração de interfaces).

| Tag | Nome | O que faz | Tipo | Valor padrão |
|-----|------|-----------|------|--------------|
| {TAGI_TAG} | {TAGI_NME} | {explicação em linguagem simples do efeito da tag no comportamento DESTA tela} | {tipo_humano} | {valor padrão se conhecido} |

### Como as tags afetam esta tela

{Para cada tag detectada, incluir um parágrafo curto explicando:
- O que muda quando a tag está ativada/com valor X vs Y
- Exemplo prático do impacto na operação do usuário
- Se a tag é obrigatória para o funcionamento correto da tela}

> **Nota**: Para alterar estas configurações, acesse **Menu > Integração > Replicação > Configuração de interfaces**, selecione a interface desejada, e localize a tag na aba de configurações.

**REGRA CRÍTICA**: SEMPRE re-explicar o propósito de cada tag inline. Nunca usar apenas um link para o catálogo. Cada documento de tela deve ser auto-contido — o usuário deve entender a tag sem consultar outro arquivo.

## Mensagens de erro comuns

| Mensagem | Causa | Solução |
|----------|-------|---------|
| {texto do erro} | {causa} | {o que o usuário deve fazer} |
```

### 8. Adaptações por tipo de tela

#### Tela Master/Detail (com abas/páginas)
Se o DFM contiver `TdxPageControl` ou `TPageControl`:
- Documentar cada aba separadamente
- Indicar navegação entre abas

#### Tela de Pesquisa (_P)
Se existir `{UNIT}_P.dfm`:
- Documentar filtros disponíveis
- Explicar como buscar registros

#### Tela herdada
Se o DFM começa com `inherited`:
- Identificar a tela pai
- Documentar apenas os campos/comportamentos adicionados ou alterados

## Diretrizes de escrita

- **Linguagem**: Simples, direta, sem jargão técnico. Imaginar que o leitor nunca viu o sistema
- **Voz**: Imperativa nos tutoriais ("Clique em...", "Preencha o campo...")
- **Tom**: Profissional mas acessível
- **Termos técnicos do banco**: Traduzir para linguagem de negócio (ENTB_COD → "Código da entidade", ENTE_CHR_END → "Tipo de endereço")
- **Nomes de campos**: Usar o texto do Label na tela, não o nome técnico
- **Regras**: Explicar o "porquê" quando possível ("O CEP deve ter 8 dígitos para endereços nacionais")

## Saída

Salvar o arquivo em: `docs/manual-usuario/{UNIT_NAME}_DocumentacaoPreventiva.md`

Exemplo: `docs/manual-usuario/ESTMOV_DOCMOV_DocumentacaoPreventiva.md`

**Após salvar**, atualizar o banco de telas (ver seção "Atualização Automática do Banco").

---

# Documentação de Tags de Configuração (TINT_TAGINT / TINT_INTCFG)

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

---

# Rastreamento de Telas do Sistema

## Banco de Dados de Telas

O arquivo `.claude/skills/kpl-user-docs/screens-db.json` é o banco central de rastreamento de todas as telas do sistema. Ele mapeia cada tela encontrada no menu (`ABACOS_MENU`) com seu status de documentação.

**Localização**: `.claude/skills/kpl-user-docs/screens-db.json`

### Schema

```json
{
  "version": 1,
  "last_scan": "ISO-8601 timestamp do último scan",
  "screens": {
    "TFrmXXX_P": {
      "form_class": "TFrmXXX_P",
      "unit_name": "XXX",
      "menu_path": ["Módulo", "Submenu", "Tela"],
      "caption": "Título da tela no menu",
      "module": "KXXX",
      "module_label": "Nome do módulo",
      "source_files": ["XXX_M.pas", "XXX_M.dfm", "XXX_D.pas"],
      "source_dir": "Aplicacoes/BackOfficeDelphi/...",
      "doc_status": "pending|documented|needs_update|skipped",
      "doc_path": null,
      "doc_date": null,
      "source_last_modified": null,
      "needs_update": false,
      "skip_reason": null
    }
  },
  "stats": {
    "total": 0,
    "documented": 0,
    "pending": 0,
    "needs_update": 0,
    "skipped": 0
  }
}
```

### Status possíveis

| Status | Significado |
|--------|-------------|
| `pending` | Tela identificada, documentação ainda não gerada |
| `documented` | Documentação gerada e salva |
| `needs_update` | Fonte alterada após a documentação (source_last_modified > doc_date) |
| `skipped` | Não é uma tela documentável (ver skip_reason) |

---

## Mapa de Módulos

Mapeamento dos códigos de pacote Delphi (`Mx_PackageName`) para labels legíveis:

| Código | Label | Diretório típico |
|--------|-------|-------------------|
| `KADM` | Administração | BackOfficeDelphi/Administracao |
| `KCOM` | Comercial | BackOfficeDelphi/Comercial |
| `KEST` | Estoque | BackOfficeDelphi/Estoque |
| `KFIN` | Financeiro | BackOfficeDelphi/Financeiro |
| `KCPR` | Compras | BackOfficeDelphi/Compras |
| `KFAS` | Fiscal | BackOfficeDelphi/Fiscal |
| `KESP` | Especial | BackOfficeDelphi/Especial |
| `KREL` | Relatórios | BackOfficeDelphi/Relatorios |
| `KGEN` | Genérico | BackOfficeDelphi/Generico |
| `KTMS` | TMS | BackOfficeDelphi/TMS |
| `KWMS` | WMS | BackOfficeDelphi/WMS |
| `KCRM` | CRM | BackOfficeDelphi/CRM |
| `KPRO` | Produção | BackOfficeDelphi/Producao |

Se um módulo não estiver nesta tabela, usar o código como label e o handler do menu para inferir o diretório.

---

## Escanear Telas do Menu (Lógica do /kpl-scan)

A fonte de verdade para todas as telas do sistema são os arquivos:
- **DFM**: `Aplicacoes/BackOfficeDelphi/Principal/ABACOS_MENU.dfm` (hierarquia de menus)
- **PAS**: `Aplicacoes/BackOfficeDelphi/Principal/ABACOS_MENU.pas` (handlers com CreateFormBase)

### Passo 1: Parse do DFM — Hierarquia de menus

Ler `ABACOS_MENU.dfm`. Ele contém vários objetos `TMainMenu` (ex: `mmAdm`, `mmCom`, `mmEst`, `mmFin`, `mmCpr`, `mmFas`, `mmEsp`, `mmRel`, etc.).

Dentro de cada TMainMenu há TMenuItems aninhados. Para cada TMenuItem **folha** (que tem `OnClick`):

Extrair:
- `menu_item_name`: nome do objeto (ex: `mniDocumentoAuxiliarMovEstoque`)
- `Caption`: texto visível no menu (ex: `'Documento auxiliar de movimentação de estoque'`)
- `OnClick`: nome do handler (ex: `mniDocumentoAuxiliarMovEstoqueClick`)
- `menu_path`: array de Captions dos pais, da raiz até a folha

Exemplo de estrutura DFM:
```
object mmEst: TMainMenu
  object mniEstoque: TMenuItem
    Caption = 'Estoque'
    object mniMovimentacao: TMenuItem
      Caption = 'Movimentação'
      object mniDocumentoAuxiliarMovEstoque: TMenuItem
        Caption = 'Documento auxiliar de movimentação de estoque'
        OnClick = mniDocumentoAuxiliarMovEstoqueClick
      end
    end
  end
end
```

→ `menu_path = ["Estoque", "Movimentação", "Documento auxiliar de movimentação de estoque"]`

### Passo 2: Parse do PAS — Handlers com CreateFormBase

Ler `ABACOS_MENU.pas`. Para cada `procedure TFrmABACOS_MENU.mni*Click`, extrair:

1. **form_class**: o primeiro argumento de `CreateFormBase('TFrmXXXXX', ...)` ou `CreateFormBase('TFrmXXXXX')`
2. **module**: valor de `Mx_PackageName := 'KXXX'` dentro do handler (pode estar antes ou depois do CreateFormBase)

Exemplo:
```pascal
procedure TFrmABACOS_MENU.mniDocumentoAuxiliarMovEstoqueClick(Sender: TObject);
begin
  Mx_PackageName := 'KEST';
  CreateFormBase('TFrmESTMOV_DOCMOV_P', vParams);
end;
```

→ `form_class = "TFrmESTMOV_DOCMOV_P"`, `module = "KEST"`

**Handlers sem CreateFormBase**: Se o handler não contém `CreateFormBase` (ex: apenas `ShowMessage`, chama outra unit, abre ferramenta externa), registrar com `doc_status: "skipped"` e `skip_reason: "sem form associado — [descrição do que faz]"`.

### Passo 3: Correlação DFM + PAS

Para cada handler encontrado no DFM (via `OnClick`):
1. Buscar o handler correspondente no PAS
2. Extrair form_class e module do PAS
3. Combinar com menu_path e caption do DFM

**Form duplicado em múltiplos menus**: Se o mesmo form_class aparece em mais de um handler, usar apenas uma entrada no screens-db mas com `menu_path` sendo um array de arrays (múltiplos caminhos).

### Passo 4: Derivar unit_name

A partir do form_class, derivar o unit_name:
1. Strip prefixo `TFrm` → ex: `ESTMOV_DOCMOV_P`
2. Strip sufixo `_P`, `_M`, `_L`, `_B` → ex: `ESTMOV_DOCMOV`
3. Este é o `unit_name` base para buscar arquivos fonte

### Passo 5: Localizar source files

Buscar arquivos da tela:
```
Glob: **/BackOfficeDelphi/**/{unit_name}_*.pas
Glob: **/BackOfficeDelphi/**/{unit_name}_*.dfm
```

Registrar os arquivos encontrados em `source_files` e o diretório em `source_dir`.

### Passo 6: Datas via git

Para cada tela, obter a data da última modificação dos fontes:
```bash
git log -1 --format=%aI -- <source_dir>/{unit_name}_*
```

Salvar em `source_last_modified`.

**Nota de performance**: Este passo pode ser demorado (~475 chamadas git). Para o scan inicial, é aceitável fazer em lotes ou pular este passo e preencher sob demanda quando `/kpl-next` ou `/kpl-status` forem chamados.

### Passo 7: Reconciliar com docs existentes

Antes de salvar:
1. Ler o screens-db.json existente (se houver)
2. Para cada tela já com `doc_status: "documented"`, preservar: `doc_path`, `doc_date`, `doc_status`
3. Se `source_last_modified > doc_date`, marcar `needs_update: true`
4. Verificar se o arquivo de doc ainda existe no disco. Se não, reverter para `pending`

### Passo 8: Salvar e reportar

Salvar `screens-db.json` com timestamp em `last_scan`.

Recalcular `stats`:
```
total = count(all screens)
documented = count(doc_status == "documented")
pending = count(doc_status == "pending")
needs_update = count(needs_update == true)
skipped = count(doc_status == "skipped")
```

Mostrar resumo ao usuário:
```
## Scan concluído

| Módulo | Total | Pendentes | Documentadas | Desatualizadas | Ignoradas |
|--------|-------|-----------|--------------|----------------|-----------|
| Estoque | 45 | 44 | 1 | 0 | 0 |
| Comercial | 80 | 80 | 0 | 0 | 0 |
| ... | ... | ... | ... | ... | ... |
| **TOTAL** | **475** | **474** | **1** | **0** | **0** |
```

---

## Comandos de Gestão

### /kpl-scan — Escanear telas do sistema

**Trigger**: Usuário pede para escanear, mapear, inventariar telas do sistema, ou diz "kpl-scan".

**Fluxo**:
1. Executar o parse completo conforme "Escanear Telas do Menu" (Passos 1-8)
2. Mostrar resumo por módulo
3. Informar: "Use `/kpl-status` para ver o progresso ou `/kpl-next` para começar a documentar."

### /kpl-status — Status da documentação

**Trigger**: Usuário pede status, progresso, overview da documentação, ou diz "kpl-status". Aceita filtro opcional de módulo.

Exemplos:
- "status da documentação" → todas as telas
- "status do comercial" → só telas com module == "KCOM"
- "/kpl-status KFIN" → só telas do Financeiro

**Resolução do módulo**: O usuário pode dizer o nome em português (Comercial, Estoque, Financeiro) ou o código (KCOM, KEST, KFIN). Usar o Mapa de Módulos para resolver.

**Fluxo**:
1. Ler `.claude/skills/kpl-user-docs/screens-db.json`
2. Se não existir ou `last_scan` for null, avisar: "Nenhum scan realizado. Execute `/kpl-scan` primeiro."
3. Se módulo especificado, filtrar telas por `module == <código>` antes de exibir. Mostrar lista detalhada das telas daquele módulo ao invés da tabela resumo.
   Se não especificado, mostrar tabela por módulo (como no resumo do scan)
4. Mostrar barra de progresso ASCII:

```
Progresso geral: [████░░░░░░░░░░░░░░░░] 5% (24/475)
  Documentadas:    24
  Pendentes:       440
  Desatualizadas:  6
  Ignoradas:       5
```

5. Se houver telas `needs_update`, listar as top 5:
```
⚠ Telas desatualizadas (fonte modificada após documentação):
  - ESTMOV_DOCMOV (modificado em 2026-03-01, doc de 2025-08-01)
  - COMPED_PEDVEN (modificado em 2026-02-15, doc de 2026-01-10)
```

### /kpl-next — Próxima tela a documentar

**Trigger**: Usuário pede próxima tela, sugestão do que documentar, ou diz "kpl-next".

**Fluxo**:
1. Ler screens-db.json
2. Se não existir ou `last_scan` for null, executar `/kpl-scan` primeiro
3. Priorizar:
   - **Primeiro**: telas com `needs_update: true` (documentação desatualizada)
   - **Segundo**: telas com `doc_status: "pending"`, priorizando módulos com menos telas pendentes (quick wins)
4. Mostrar sugestão:

```
## Próxima tela sugerida

**ESTMOV_DOCMOV** (Estoque) — Desatualizada
- Menu: Estoque → Movimentação → Documento auxiliar
- Fonte modificada em: 2026-03-01
- Doc atual de: 2025-08-01
- Arquivos: ESTMOV_DOCMOV_M.pas, ESTMOV_DOCMOV_D.pas, ...

Deseja documentar esta tela agora? (sim/não)
```

5. Se o usuário confirmar, iniciar o fluxo de documentação (Passos 1-8 da seção "Processo")

### /kpl-doc-all — Documentar o sistema completo

**Trigger**: Usuário pede para documentar todo o sistema, todas as telas, um módulo específico, ou diz "kpl-doc-all". Aceita filtro opcional de módulo.

Exemplos:
- "documente todo o sistema" → todas as telas pendentes
- "documente todo o comercial" → só telas com module == "KCOM"
- "documente o módulo estoque" → só telas com module == "KEST"
- "/kpl-doc-all KFIN" → só telas do Financeiro

**Resolução do módulo**: O usuário pode dizer o nome em português (Comercial, Estoque, Financeiro) ou o código (KCOM, KEST, KFIN). Usar o Mapa de Módulos para resolver.

**Fluxo**:
1. Se screens-db.json não existir ou `last_scan` for null, executar `/kpl-scan` primeiro
2. Filtrar escopo:
   - Se módulo especificado: filtrar screens-db.json por `module == <código>`
   - Se não especificado: usar todas as telas
   Calcular escopo filtrado:
```
## Plano de documentação completa

- Telas pendentes: 440
- Telas desatualizadas: 6
- Total a processar: 446

Ordem de prioridade:
1. Desatualizadas primeiro (6 telas)
2. Módulos menores primeiro (quick wins)
   - CRM: 8 telas
   - TMS: 12 telas
   - Especial: 15 telas
   - ...

Deseja iniciar? A documentação será gerada uma tela por vez.
```

3. Para cada tela, na ordem de prioridade:
   a. Mostrar qual tela será documentada
   b. Executar o fluxo de documentação completo (Passos 1-8 da seção "Processo")
   c. Atualizar screens-db.json (ver "Atualização Automática do Banco")
   d. Perguntar: "Tela documentada. Continuar com a próxima? (sim/não/pular)"
      - **sim**: prossegue para a próxima
      - **não**: para o processo
      - **pular**: marca como `skipped` com `skip_reason: "pulada pelo usuário"` e vai para a próxima

### /kpl-plan — Planejar documentação (para dispatch paralelo)

**Trigger**: Usuário pede para planejar a documentação, listar telas pendentes de um módulo, preparar lotes para agentes paralelos, ou diz "kpl-plan". Também quando o usuário menciona "dividir", "paralelo", "lotes", "agentes" no contexto de documentação.

**Propósito**: Gerar uma lista estruturada de telas pendentes que pode ser dividida em lotes e despachada para múltiplos agentes paralelos. Diferente do `/kpl-doc-all` que executa sequencialmente, este comando apenas **planeja** sem documentar.

**Fluxo**:
1. Se screens-db.json não existir ou `last_scan` for null, executar `/kpl-scan` primeiro
2. Filtrar telas:
   - Se módulo especificado: filtrar por `module == <código>` (resolver via Mapa de Módulos)
   - Se não: usar todas as telas com `doc_status == "pending"` ou `needs_update == true`
3. Gerar lista completa formatada:

```
## Plano de Documentação — {Módulo} ({Código})

**Telas pendentes**: {N}
**Telas desatualizadas**: {M}
**Total a processar**: {N+M}

### Lista de telas

| # | unit_name | caption | menu_path | status |
|---|-----------|---------|-----------|--------|
| 1 | COMPED_PEDVEN | Pedido de venda | Comercial > Pedidos > Pedido de venda | pending |
| 2 | COMPED_ORCVEN | Orçamento de venda | Comercial > Pedidos > Orçamento | pending |
| 3 | COMCAD_CLIENT | Cadastro de clientes | Comercial > Cadastros > Clientes | needs_update |
| ... | ... | ... | ... | ... |

### Sugestão de divisão em lotes

Para {X} agentes paralelos (lotes de ~{Y} telas):
- **Lote 1** (telas 1-{Y}): COMPED_PEDVEN, COMPED_ORCVEN, ...
- **Lote 2** (telas {Y+1}-{2Y}): COMCAD_TRANSPOR, ...
- **Lote 3** (telas {2Y+1}-{N+M}): COMREL_VENDAS, ...

Deseja ajustar o número de lotes ou iniciar o dispatch?
```

4. Se o usuário quiser dispatch paralelo:
   - Para cada lote, gerar um prompt de agente contendo:
     a. O caminho da skill: `.claude/skills/kpl-user-docs/SKILL.md`
     b. A lista de unit_names do lote
     c. Instrução: "Para cada unit_name na lista, execute os Passos 1-8 do processo de documentação da skill kpl-user-docs. Após cada tela, atualize o screens-db.json."
   - Usar a ferramenta Agent para despachar cada lote como um subagente independente
   - Cada agente recebe contexto suficiente para operar autonomamente

### Template de prompt para agente paralelo

Quando despachar agentes paralelos, usar este template:

```
Você é um agente de documentação do sistema KPL.

**Skill**: Leia `.claude/skills/kpl-user-docs/SKILL.md` para entender o processo completo.

**Sua tarefa**: Documentar as seguintes telas, uma por vez, seguindo os Passos 1-8 da skill:

{lista_de_unit_names}

Para cada tela:
1. Siga rigorosamente os Passos 1-8 da seção "Processo" do SKILL.md
2. Salve o arquivo em `docs/manual-usuario/{UNIT_NAME}_DocumentacaoPreventiva.md`
3. Atualize `.claude/skills/kpl-user-docs/screens-db.json`:
   - Localizar a entrada pelo unit_name
   - Setar doc_status = "documented", doc_path, doc_date = hoje, needs_update = false
   - Recalcular stats

Documente todas as telas da lista sem parar para perguntar. Reporte ao final quantas foram concluídas.
```

### /kpl-tags — Gerar catálogo de tags de configuração

**Trigger**: Usuário pede para documentar tags, listar tags, catálogo de tags, referência de tags, ou diz "kpl-tags". Aceita filtros opcionais.

Exemplos:
- "documente as tags" → catálogo completo
- "tags da interface Plataforma" → tags de INTF_COD=9
- "tags do grupo IMPPDS" → tags com prefixo IMPPDS
- "/kpl-tags INTF_COD=13" → tags da interface 13 (MELI)
- "/kpl-tags prefixo=EXPPRO" → tags com prefixo EXPPRO

**Fluxo**:
1. Conectar ao banco via MCP SQL Server (`mcp__sqlserver__execute_query`)
2. Executar Tag Steps 1-3 da seção "Processo de Documentação de Tags" (queries com cross-database `ABACOS_ONCLKON.dbo`)
3. Para cada tag com `TAGI_SQL_LKP` não nulo, descrever em linguagem humana o que o lookup busca (interpretar o SQL, não executá-lo)
4. Executar Tag Step 7 (buscar uso no código-fonte via Grep por `'{TAGI_TAG}'`)
5. Gerar o catálogo no formato do "Template de Catálogo de Tags"
6. Se filtro aplicado, gerar apenas a seção relevante:
   - Por prefixo: filtrar `WHERE TAGI_TAG LIKE '{PREFIX}_%'`
   - Por interface: filtrar `WHERE C.INTF_COD = {N}`
   - Por grupo: filtrar `WHERE T.INTG_COD = {N}`
7. Salvar em `docs/manual-usuario/tags/`:
   - Catálogo completo: `CATALOGO_TAGS_COMPLETO.md`
   - Por interface: `TAGS_INTF_{INTF_COD}_{NOME_SANITIZADO}.md`
   - Por prefixo: `TAGS_PREFIXO_{PREFIXO}.md`
   - Por grupo: `TAGS_GRUPO_{INTG_COD}_{NOME_SANITIZADO}.md`
8. Atualizar `tags-db.json` (ver seção "Banco de Dados de Tags")

**Fallback sem banco**: Se o MCP SQL Server não estiver disponível:
1. Buscar scripts de definição de tags no repositório:
   ```
   Glob: **/SQLBackOffice/Integracao/Replicacao/PRPL_C_INTCFG*.sql
   ```
2. Parsear chamadas a `PRPL_C_TAGINT` para extrair definições
3. Gerar catálogo com base nos scripts (sem valores atuais de INTCFG)

**Apresentação ao usuário**:
```
## Catálogo de Tags gerado

| Métrica | Valor |
|---------|-------|
| Tags documentadas | 840 |
| Grupos | 41 |
| Interfaces ativas | 15 |
| Tags com referência no código | {N} |
| Tags órfãs (sem uso encontrado) | {M} |

Arquivo salvo em: docs/manual-usuario/tags/CATALOGO_TAGS_COMPLETO.md
```

**Regra de re-explicação**: Ao gerar documentação de tags (tanto no catálogo quanto na documentação de telas), SEMPRE incluir a explicação completa da tag inline. Nunca usar apenas um link para o catálogo. O objetivo é que cada documento seja auto-contido — o usuário deve entender a tag sem precisar consultar outro arquivo.

---

## Atualização Automática do Banco

**Sempre** que uma documentação for gerada pelos Passos 1-8 (tanto por fluxo individual quanto por `/kpl-doc-all`), atualizar o screens-db.json:

1. Ler o screens-db.json atual
2. Localizar a entrada pelo `unit_name` ou `form_class`
3. Atualizar:
   ```json
   {
     "doc_status": "documented",
     "doc_path": "<caminho relativo do arquivo .md gerado>",
     "doc_date": "<data de hoje no formato YYYY-MM-DD>",
     "needs_update": false
   }
   ```
4. Recalcular `stats`
5. Salvar screens-db.json

Se a tela não existir no banco (scan não foi feito), criar a entrada com as informações disponíveis e `doc_status: "documented"`.

---

## Detecção de Desatualização

Uma documentação está desatualizada quando:

```
source_last_modified > doc_date
```

Isto é verificado:
- Durante o `/kpl-scan` (Passo 7: Reconciliar)
- Durante o `/kpl-status` (recalcula ao exibir)
- Antes de documentar uma tela (avisa se já documentada e atualizada)

Quando detectada desatualização:
- Marcar `needs_update: true` no screens-db.json
- **Não** mudar `doc_status` (continua como `documented`)
- Listar no `/kpl-status` como alerta

---

# Banco de Dados de Tags

O arquivo `.claude/skills/kpl-user-docs/tags-db.json` rastreia a documentação de tags de configuração, complementando o `screens-db.json` que rastreia telas.

**Localização**: `.claude/skills/kpl-user-docs/tags-db.json`

## Schema

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

## Atualização do tags-db.json

**Sempre** que o comando `/kpl-tags` for executado:

1. Ler o tags-db.json atual (se existir)
2. Para cada tag documentada, atualizar/criar entrada com todos os campos
3. Recalcular `stats`
4. Salvar com `last_scan` atualizado

Se o tags-db.json não existir, criar com a estrutura acima.

## Integração com screens-db.json

Quando uma tela é documentada (via Passos 1-8) e tags são detectadas (via Step 5.5):
1. Atualizar o `screens-db.json` normalmente
2. No `tags-db.json`, adicionar a tela como referência nas tags detectadas (campo `code_references`)
3. Isso permite rastrear quais telas consomem quais tags
