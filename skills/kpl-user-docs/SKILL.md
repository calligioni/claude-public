---
name: kpl-user-docs
description: Gera documentação de usuário final para telas do sistema KPL e catálogo de tags de configuração (TINT_TAGINT/TINT_INTCFG) a partir do código-fonte Delphi e banco de dados. Use quando o usuário pedir documentação, manual, help, guia de uso, tutorial, referência de tela ou tags de configuração do sistema. Também dispara quando o usuário mencionar "documentar tela", "como funciona a tela X", "gerar manual", "doc de usuário", "tags de configuração", "catálogo de tags", "configuração de interface", "TINT_TAGINT", ou quiser entender o que uma tela faz do ponto de vista operacional. Comandos de gestão: /kpl-scan (escanear telas do menu), /kpl-status (progresso da documentação), /kpl-next (próxima tela a documentar), /kpl-doc-all (documentar todo o sistema ou módulo), /kpl-plan (planejar divisão em lotes para agentes paralelos), /kpl-tags (gerar catálogo de tags de configuração).
user-invocable: true
effort: high
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

# Referências Detalhadas

Para manter este arquivo principal enxuto, as referências detalhadas foram movidas para arquivos separados:

- **[references/tag-system.md](references/tag-system.md)** — Sistema de tags de configuração: queries SQL, mapeamento de tipos, template de catálogo, prefixos conhecidos, banco tags-db.json
- **[references/screen-tracking.md](references/screen-tracking.md)** — Rastreamento de telas: schema screens-db.json, mapa de módulos, lógica do /kpl-scan (passos 1-8), comandos de gestão (/kpl-scan, /kpl-status, /kpl-next, /kpl-doc-all, /kpl-plan, /kpl-tags), templates de agentes paralelos, atualização automática, detecção de desatualização

**IMPORTANTE**: Ao executar qualquer comando, ler o arquivo de referência correspondente para obter queries SQL, schemas e templates completos.
