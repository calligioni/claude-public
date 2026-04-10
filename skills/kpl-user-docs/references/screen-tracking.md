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

-> `menu_path = ["Estoque", "Movimentação", "Documento auxiliar de movimentação de estoque"]`

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

-> `form_class = "TFrmESTMOV_DOCMOV_P"`, `module = "KEST"`

**Handlers sem CreateFormBase**: Se o handler não contém `CreateFormBase` (ex: apenas `ShowMessage`, chama outra unit, abre ferramenta externa), registrar com `doc_status: "skipped"` e `skip_reason: "sem form associado — [descrição do que faz]"`.

### Passo 3: Correlação DFM + PAS

Para cada handler encontrado no DFM (via `OnClick`):
1. Buscar o handler correspondente no PAS
2. Extrair form_class e module do PAS
3. Combinar com menu_path e caption do DFM

**Form duplicado em múltiplos menus**: Se o mesmo form_class aparece em mais de um handler, usar apenas uma entrada no screens-db mas com `menu_path` sendo um array de arrays (múltiplos caminhos).

### Passo 4: Derivar unit_name

A partir do form_class, derivar o unit_name:
1. Strip prefixo `TFrm` -> ex: `ESTMOV_DOCMOV_P`
2. Strip sufixo `_P`, `_M`, `_L`, `_B` -> ex: `ESTMOV_DOCMOV`
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
- "status da documentação" -> todas as telas
- "status do comercial" -> só telas com module == "KCOM"
- "/kpl-status KFIN" -> só telas do Financeiro

**Resolução do módulo**: O usuário pode dizer o nome em português (Comercial, Estoque, Financeiro) ou o código (KCOM, KEST, KFIN). Usar o Mapa de Módulos para resolver.

**Fluxo**:
1. Ler `.claude/skills/kpl-user-docs/screens-db.json`
2. Se não existir ou `last_scan` for null, avisar: "Nenhum scan realizado. Execute `/kpl-scan` primeiro."
3. Se módulo especificado, filtrar telas por `module == <código>` antes de exibir. Mostrar lista detalhada das telas daquele módulo ao invés da tabela resumo.
   Se não especificado, mostrar tabela por módulo (como no resumo do scan)
4. Mostrar barra de progresso ASCII:

```
Progresso geral: [####................] 5% (24/475)
  Documentadas:    24
  Pendentes:       440
  Desatualizadas:  6
  Ignoradas:       5
```

5. Se houver telas `needs_update`, listar as top 5:
```
Telas desatualizadas (fonte modificada após documentação):
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
4. Mostrar sugestão com unit_name, menu path, datas, e arquivos
5. Se o usuário confirmar, iniciar o fluxo de documentação (Passos 1-8 da seção "Processo")

### /kpl-doc-all — Documentar o sistema completo

**Trigger**: Usuário pede para documentar todo o sistema, todas as telas, um módulo específico, ou diz "kpl-doc-all". Aceita filtro opcional de módulo.

**Fluxo**:
1. Se screens-db.json não existir ou `last_scan` for null, executar `/kpl-scan` primeiro
2. Filtrar escopo (por módulo se especificado)
3. Para cada tela, na ordem de prioridade: documentar, atualizar screens-db, perguntar se continua

### /kpl-plan — Planejar documentação (para dispatch paralelo)

**Trigger**: Usuário pede para planejar a documentação, listar telas pendentes de um módulo, preparar lotes para agentes paralelos, ou diz "kpl-plan".

**Propósito**: Gerar uma lista estruturada de telas pendentes que pode ser dividida em lotes e despachada para múltiplos agentes paralelos.

### /kpl-tags — Gerar catálogo de tags de configuração

**Trigger**: Usuário pede para documentar tags, listar tags, catálogo de tags, referência de tags, ou diz "kpl-tags". Aceita filtros opcionais.

**Fluxo**: Ver [references/tag-system.md](tag-system.md) para queries e processo completo.

1. Conectar ao banco via MCP SQL Server
2. Executar Tag Steps 1-3
3. Descrever lookups em linguagem humana
4. Buscar uso no código-fonte
5. Gerar catálogo
6. Salvar em `docs/manual-usuario/tags/`
7. Atualizar `tags-db.json`

**Regra de re-explicação**: Ao gerar documentação de tags, SEMPRE incluir a explicação completa da tag inline. Nunca usar apenas um link para o catálogo.

---

## Atualização Automática do Banco

**Sempre** que uma documentação for gerada pelos Passos 1-8, atualizar o screens-db.json:

1. Ler o screens-db.json atual
2. Localizar a entrada pelo `unit_name` ou `form_class`
3. Atualizar: `doc_status: "documented"`, `doc_path`, `doc_date`, `needs_update: false`
4. Recalcular `stats`
5. Salvar screens-db.json

Se a tela não existir no banco (scan não foi feito), criar a entrada com as informações disponíveis e `doc_status: "documented"`.

---

## Detecção de Desatualização

Uma documentação está desatualizada quando: `source_last_modified > doc_date`

Isto é verificado:
- Durante o `/kpl-scan` (Passo 7: Reconciliar)
- Durante o `/kpl-status` (recalcula ao exibir)
- Antes de documentar uma tela (avisa se já documentada e atualizada)

Quando detectada desatualização:
- Marcar `needs_update: true` no screens-db.json
- **Não** mudar `doc_status` (continua como `documented`)
- Listar no `/kpl-status` como alerta

---

## Template de prompt para agente paralelo

Quando despachar agentes paralelos (/kpl-plan), usar este template:

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
