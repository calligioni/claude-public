# Padrões KPL/Abacos — Delphi 5 VCL

Padrões específicos do projeto KPL (Abacos.exe). Consultar sempre ao trabalhar neste projeto.

## Arquitetura de 3 camadas

```
Abacos.exe (Delphi 5 VCL)
    ↓
AbacosService (.NET WCF)
    ↓
WebServices (SOAP + REST)
```

## Padrão de DataModule (TMxDataSet)

Cada entidade tem um DataModule com:
- Datasets do tipo `TMxDataSet`
- Stored Procedures seguindo convenção: `dbo.P{MOD}_C_{TAB}`
  - `{MOD}` = código do módulo (ex: `EST` para Estoque, `COM` para Compras)
  - `{TAB}` = código da tabela/entidade

Exemplo:
```pascal
procedure TDMEstProduto.CarregarProduto(ACodigo: Integer);
begin
  dsProduto.Close;
  dsProduto.Params.ParamByName('PROD_COD').Value := ACodigo;
  dsProduto.Open;
end;
```

Macros especiais:
- `#VAZIO` — macro para filtro vazio (sem restrição)
- `#MACRO` — macro para aplicar filtro

## Padrão de Formulário Master (TFrmIntManutencaoPage)

Formulários de manutenção herdam de `TFrmIntManutencaoPage`.

Métodos obrigatórios:
```pascal
procedure DoCreate; override;
procedure DoDestroy; override;
procedure ValidateEdits; override;
```

Uso de `TdxPageControl` para abas de edição.

Estrutura típica:
```pascal
type
  TFrmEstManutProduto = class(TFrmIntManutencaoPage)
    // componentes do designer
  protected
    procedure DoCreate; override;
    procedure DoDestroy; override;
    procedure ValidateEdits; override;
  end;
```

## Padrão de Formulário de Pesquisa (TFrmIntPesquisa)

Formulários de busca herdam de `TFrmIntPesquisa`.

Método principal:
```pascal
procedure DoAplicarFiltro; override;
```

Utilitários de filtro:
- `MacroByName('NOME_MACRO').Value := 'valor'` — aplicar macro de filtro
- `TKCStr.Like('campo', 'valor')` — filtro LIKE para strings

## Registro no projeto principal (ABACOS.dpr)

**Versão**: Delphi 5
**Path**: `F:\DEV\adriano.calligioni\KPL\Aplicacoes\BackOfficeDelphi\Principal\ABACOS.dpr`
**Escala**: 1.352 units no `uses`; 1.278 classes de form registradas

Todo novo formulário deve ser registrado em `ABACOS.dpr`:
- Incluído na cláusula `uses` com path relativo: `UnitName in '..\Modulo\UnitName.pas' {FrmClassName}`
- Registrado com `RegisterClass(TFrmNovo)`

### Fluxo de inicialização do Abacos.exe

Apenas 3 forms são criados automaticamente (`Application.CreateForm`):
1. `TFrmIntMainDtm` → data module central de inicialização
2. `TFrmIntLogin` → tela de login (com parâmetros de linha de comando)
3. `TFrmABACOS_MENU` → menu principal (criado após login bem-sucedido)

Todos os demais 1.275 forms são instanciados sob demanda pelo menu.

## Classes base — hierarquia e file paths

Base path: `F:\DEV\adriano.calligioni\KPL\Aplicacoes\BackOfficeDelphi\Interface\`

| Classe | Arquivo | Uso |
|---|---|---|
| `TFrmIntBase` | `IntBase.pas` | Raiz de todos os forms |
| `TFrmIntManutencao` | `IntManutencao.pas` | Form de manutenção simples (sem abas) |
| `TFrmIntManutencaoPage` | `IntManutencaoPage.pas` | Form de manutenção com abas (herda de TFrmIntManutencao) |
| `TFrmIntPesquisa` | `IntPesquisa.pas` | Form de pesquisa/lookup |
| `TFrmIntLocaliza` | `IntLocaliza.pas` | Form de localização |
| `TFrmIntLogin` | `IntLogin.pas` | Tela de login |
| `TFrmIntMainDtm` | `IntMainDtm.pas` | Data module principal |
| `TFrmIntEspecial` | `IntEspecial.pas` | Funcionalidades especiais |

**Hierarquia de herança**:
```
TFrmIntBase
  └── TFrmIntManutencao        (IntManutencao.pas)
        └── TFrmIntManutencaoPage  (IntManutencaoPage.pas)  ← usar para forms com abas
  └── TFrmIntPesquisa          (IntPesquisa.pas)            ← usar para forms de busca
```

## Módulos do projeto — pastas e volumes

Base path: `F:\DEV\adriano.calligioni\KPL\Aplicacoes\BackOfficeDelphi\`

| Módulo | Pasta | ~.pas | Código |
|---|---|---|---|
| Comercial | `Comercial\` | 549 | COM |
| Financeiro | `Financeiro\` | 141 | FIN |
| Generico | `Generico\` | 100 | GEN |
| Estoque | `Estoque\` | 99 | EST |
| Loja | `Loja\` | 68 | LOJ |
| Administracao | `Administracao\` | 67 | ADM |
| Interface (base) | `Interface\` | 46 | INT |
| Compras | `Compras\` | 51 | CPR |
| Atendimento | `Atendimento\` | 32 | — |
| Marketplace/MercadoLivre | `Marketplace\MercadoLivre\` | 55 | — |
| Integracao (vários) | `Integracao\` | 100+ | — |
| Consultas | `Consultas\` | 13 | — |
| RMA | `RMA\` | 11 | RMA |

Total: ~1.616 arquivos `.pas` + ~1.392 `.dfm`

## Convenção de módulos

| Código | Módulo |
|---|---|
| `EST` | Estoque |
| `COM` | Compras/Comercial |
| `VEN` | Vendas |
| `FIN` | Financeiro |
| `CAD` | Cadastros |
| `GEN` | Geral/Genérico |
| `FAT` | Faturamento |
| `TRS` | Transporte |
| `LOJ` | Loja |
| `ADM` | Administração |
| `RMA` | RMA (Retorno) |

## Nomenclatura de SPs

```
dbo.P{MOD}_C_{ENT}
```

Exemplos:
- `dbo.PEST_C_MOVPRO` — Estoque, movimentação de produto
- `dbo.PADM_C_MUNCID` — Administração, municípios
- `dbo.PADM_C_ESTFED` — Administração, estados federais

**Uma única SP** trata Insert, Update e Delete — o parâmetro `@pACAO` determina a ação:
- `'I'` = Insert
- `'A'` = Alterar (Update)
- `'E'` = Excluir (Delete)

## Padrão completo do DataModule (tabela simples)

### .pas — estrutura mínima

```pascal
unit MODCAD_ENT_D;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  Db, DBTables, MxDataSet;

type
  TFrmMODCAD_ENT_D = class(TDataModule)
    dsEnt: TMxDataSet;
    dsEntENT_COD: TIntegerField;
    dsEntENT_NOM: TStringField;
    dsEntENT_DAT_CAD: TDateTimeField;
    dsEntENT_DAT_ALT: TDateTimeField;
    dtsEnt: TDataSource;
  private
  public
  end;

var
  FrmMODCAD_ENT_D: TFrmMODCAD_ENT_D;

implementation
{$R *.DFM}

initialization
  RegisterClass(TFrmMODCAD_ENT_D);

end.
```

### .dfm — sintaxe completa do TMxDataSet

```
object FrmMODCAD_ENT_D: TFrmMODCAD_ENT_D
  OldCreateOrder = False
  object dsEnt: TMxDataSet
    ParametersPrefix = '@p'
    CheckFields = True
    ProtectedWithTransaction = True
    InsertStProc = 'dbo.PMOD_C_ENT'
    UpdateStProc = 'dbo.PMOD_C_ENT'
    DeleteStProc = 'dbo.PMOD_C_ENT'
    SQL.Strings = (
      'SELECT ENT_COD, ENT_NOM, ENT_DAT_CAD, ENT_DAT_ALT'
      'FROM dbo.TMOD_ENT (NOLOCK)'
      'WHERE (1=1)'
      '#VAZIO'
      '#ENT_COD'
      '#ENT_NOM'
      'ORDER BY ENT_NOM')
    InsertParams = <
      item
        DataType = ftInteger
        Name = 'Result'
        ParamType = ptResult
      end
      item
        DataType = ftString
        Name = '@pACAO'
        ParamType = ptInput
        Value = 'I'
      end
      item
        DataType = ftInteger
        Name = '@pENT_COD'
        ParamType = ptOutput
        FieldName = 'ENT_COD'
      end
      item
        DataType = ftString
        Name = '@pENT_NOM'
        ParamType = ptInput
        FieldName = 'ENT_NOM'
      end
      item
        DataType = ftDateTime
        Name = '@pENT_DAT_CAD'
        ParamType = ptInput
        FieldName = 'ENT_DAT_CAD'
      end
      item
        DataType = ftDateTime
        Name = '@pENT_DAT_ALT'
        ParamType = ptOutput
        FieldName = 'ENT_DAT_ALT'
      end>
    UpdateParams = <
      item
        DataType = ftInteger
        Name = 'Result'
        ParamType = ptResult
      end
      item
        DataType = ftString
        Name = '@pACAO'
        ParamType = ptInput
        Value = 'A'
      end
      item
        DataType = ftInteger
        Name = '@pENT_COD'
        ParamType = ptInput
        FieldName = 'ENT_COD'
      end
      item
        DataType = ftString
        Name = '@pENT_NOM'
        ParamType = ptInput
        FieldName = 'ENT_NOM'
      end
      item
        DataType = ftDateTime
        Name = '@pENT_DAT_ALT'
        ParamType = ptOutput
        FieldName = 'ENT_DAT_ALT'
      end>
    DeleteParams = <
      item
        DataType = ftInteger
        Name = 'Result'
        ParamType = ptResult
      end
      item
        DataType = ftString
        Name = '@pACAO'
        ParamType = ptInput
        Value = 'E'
      end
      item
        DataType = ftInteger
        Name = '@pENT_COD'
        ParamType = ptInput
        FieldName = 'ENT_COD'
      end>
    Macros = <
      item
        Name = 'VAZIO'
        Value = '(1=1)'
      end
      item
        Name = 'ENT_COD'
        Value = ''
      end
      item
        Name = 'ENT_NOM'
        Value = ''
      end>
  end
  object dtsEnt: TDataSource
    DataSet = dsEnt
    Left = 200
    Top = 100
  end
end
```

### Regras dos parâmetros por ação

| Param | Insert | Update | Delete |
|---|---|---|---|
| `Result` | ptResult | ptResult | ptResult |
| `@pACAO` | `'I'` ptInput | `'A'` ptInput | `'E'` ptInput |
| PK (`ENT_COD`) | ptOutput | ptInput | ptInput |
| Campos editáveis | ptInput | ptInput | — (não incluir) |
| `DAT_CAD` | ptInput | — (não incluir) | — |
| `DAT_ALT` | ptOutput | ptOutput | — |

### Propriedades TMxDataSet obrigatórias

```
ParametersPrefix = '@p'
CheckFields = True
ProtectedWithTransaction = True
InsertStProc = 'dbo.PMOD_C_ENT'
UpdateStProc = 'dbo.PMOD_C_ENT'
DeleteStProc = 'dbo.PMOD_C_ENT'
```

Propriedades opcionais (usar quando necessário):
```
DisableEventsInBatch = True   // para datasets detail em batch
AutoUpdateBatch = True        // para commit automático em batch
Batch = True                  // para datasets detail
DataSource = dtsParent        // para master-detail
```

## Qual base herdar — decisão

| Situação | Base M | Base D |
|---|---|---|
| Tabela simples, sem abas | `TFrmIntManutencao` | `TDataModule` |
| Tabela simples, com abas | `TFrmIntManutencaoPage` | `TDataModule` |
| Entidade (pessoa/empresa/fornecedor/cliente) | `TFrmGENCAD_ENTBAS_M` | `TFrmGENCAD_ENTBAS_D` |

Regra prática: se a tabela tem TGEN_ENTBAS como FK (`ENTB_COD`), usar GENCAD_ENTBAS. Caso contrário, usar direto.

## Encoding dos arquivos KPL

**CRÍTICO**: arquivos `.pas` e `.sql` do KPL estão em **ISO-8859-1 (Latin-1)**.
- NUNCA usar Edit/Write para editar esses arquivos
- Usar Bash + `sed` para alterações pontuais
- Verificar antes: `file --mime-encoding arquivo.pas`

## Tabelas de estoque relevantes

- `TEST_SALPRO` — saldo de produto por almoxarifado
- `TEST_RASSAL` — saldo por lote/série (rastreabilidade)
- `TEST_MOVPRO` — log de movimentações
- `TEST_MOVPROLOGRAS` — auditoria de divergências de saldo

Regra de consistência:
```
SUM(TEST_RASSAL.RASS_QTF_ATU) = TEST_SALPRO.SALP_QTF_ATU
```
(para produtos com rastreabilidade ativa)

---

## Padrão completo do M form (manutenção)

### Variante simples — sem DataModule próprio (ex: ADMCAD_COTMON_M)

Usa o `dtsManutencao` herdado da base. Não sobrescreve DoCreate/DoDestroy.
Só tem componentes visuais no .dfm.

```pascal
unit {MOD}CAD_{ENT}_M;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  IntManutencao, {demais units dos componentes};

type
  TFrm{MOD}CAD_{ENT}_M = class(TFrmIntManutencao)
    // apenas componentes visuais — sem lógica
    lbl{Campo}: TLabel;
    edt{Campo}: TdxDBEdit;
  end;

var
  Frm{MOD}CAD_{ENT}_M: TFrm{MOD}CAD_{ENT}_M;

implementation
{$R *.DFM}

initialization
  RegisterClass(TFrm{MOD}CAD_{ENT}_M);

end.
```

### Variante com DataModule (ex: ADMACE_GRPUSU_M)

O M form **não cria** o DataModule — obtém do Owner (a P form que o abriu).
Usa `TMxMisc.GetPropValueByNameAsClass` para obter o DM via RTTI.

```pascal
unit {MOD}CAD_{ENT}_M;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  IntManutencao, MxMisc, {MOD}CAD_{ENT}_D, {componentes};

type
  TFrm{MOD}CAD_{ENT}_M = class(TFrmIntManutencao)
    // componentes visuais
  private
    FDataModule: TFrm{MOD}CAD_{ENT}_D;
  protected
    procedure DoCreate; override;
    procedure DoDestroy; override;
    procedure ValidateEdits; override;
  published
    property DataModule: TFrm{MOD}CAD_{ENT}_D read FDataModule;
  end;

var
  Frm{MOD}CAD_{ENT}_M: TFrm{MOD}CAD_{ENT}_M;

implementation
{$R *.DFM}

procedure TFrm{MOD}CAD_{ENT}_M.DoCreate;
var vObjDM: TObject;
begin
  inherited DoCreate;
  vObjDM := TMxMisc.GetPropValueByNameAsClass(Self.Owner, 'DataModule');
  if (vObjDM <> nil) and (vObjDM is TFrm{MOD}CAD_{ENT}_D) then
    FDataModule := (vObjDM as TFrm{MOD}CAD_{ENT}_D)
  else
    raise Exception.Create('Módulo de dados não encontrado!');
  FDataModule.FOnValidateEdits := ValidateEdits;
  ValidateEdits;
end;

procedure TFrm{MOD}CAD_{ENT}_M.DoDestroy;
begin
  if Assigned(FDataModule) then
    FDataModule.FOnValidateEdits := nil;
  inherited DoDestroy;
end;

procedure TFrm{MOD}CAD_{ENT}_M.ValidateEdits;
begin
  // Habilita/desabilita componentes conforme estado do DataSet
  // ex: edt{Campo}.Enabled := FDataModule.ds{ENT}.State in [dsInsert, dsEdit];
end;

initialization
  RegisterClass(TFrm{MOD}CAD_{ENT}_M);

end.
```

**No DataModule**, expor o callback e dispará-lo em AfterScroll/StateChange:

```pascal
public
  FOnValidateEdits: TMxProcedure;

procedure TFrm{MOD}CAD_{ENT}_D.ds{ENT}AfterScroll(DataSet: TDataSet);
begin
  if Assigned(FOnValidateEdits) then FOnValidateEdits;
end;
```

---

## Padrão completo do P form (pesquisa)

### Variante simples — DataSet direto no form (ex: ADMCAD_FERIAD_P)

TMxDataSet declarado no próprio form. FormCreate apenas abre o dataset.
Não sobrescreve DoAplicarFiltro.

```pascal
unit {MOD}CAD_{ENT}_P;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  IntPesquisa, MxDataSet, Db, {componentes};

type
  TFrm{MOD}CAD_{ENT}_P = class(TFrmIntPesquisa)
    ds{ENT}: TMxDataSet;
    ds{ENT}{ENT}_COD: TIntegerField;
    ds{ENT}{ENT}_NOM: TStringField;
    dts{ENT}: TDataSource;
    procedure FormCreate(Sender: TObject);
  end;

var
  Frm{MOD}CAD_{ENT}_P: TFrm{MOD}CAD_{ENT}_P;

implementation
{$R *.DFM}

procedure TFrm{MOD}CAD_{ENT}_P.FormCreate(Sender: TObject);
begin
  inherited;
  dtsGrd1.DataSet := ds{ENT};
  dtsGrd1.DataSet.Open;
end;

initialization
  RegisterClass(TFrm{MOD}CAD_{ENT}_P);

end.
```

### Variante com DataModule (ex: ADMACE_RDPCAD_P)

A P form **cria** o DataModule em DoCreate e o expõe como `published property`.
O M form (aberto a partir desta P form) obtém o DM via `Self.Owner.DataModule`.

```pascal
unit {MOD}CAD_{ENT}_P;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  IntPesquisa, MxDataSet, KCDs, MxDialogs, {MOD}CAD_{ENT}_D, {componentes};

type
  TFrm{MOD}CAD_{ENT}_P = class(TFrmIntPesquisa)
    // apenas componentes visuais de filtro — sem dataset aqui
  private
    FDataModule: TFrm{MOD}CAD_{ENT}_D;
  protected
    procedure DoCreate; override;
    procedure DoDestroy; override;
    procedure DoAplicarFiltro; override;
  published
    property DataModule: TFrm{MOD}CAD_{ENT}_D read FDataModule;
  end;

var
  Frm{MOD}CAD_{ENT}_P: TFrm{MOD}CAD_{ENT}_P;

implementation
{$R *.DFM}

procedure TFrm{MOD}CAD_{ENT}_P.DoCreate;
begin
  FDataModule := TFrm{MOD}CAD_{ENT}_D.Create(Self);
  dtsGrd1.DataSet := FDataModule.ds{ENT};
  dtsGrd1.DataSet.Open;
  inherited DoCreate;
end;

procedure TFrm{MOD}CAD_{ENT}_P.DoDestroy;
begin
  if FDataModule <> nil then FreeAndNil(FDataModule);
  inherited DoDestroy;
end;

procedure TFrm{MOD}CAD_{ENT}_P.DoAplicarFiltro;
var
  vDs: TMxDataSet;
  vTemFiltro: Boolean;
  vInt: Integer;
begin
  inherited;
  vDs := (dtsGrd1.DataSet as TMxDataSet);
  vDs.Close;
  TKCDs.LimparMacro(vDs);  // zera todas as macros do dataset
  vTemFiltro := False;
  for vInt := 0 to vDs.MacroCount - 1 do
    if vDs.Macros[vInt].AsString <> EmptyStr then
      vTemFiltro := True;
  if (not vTemFiltro) and
     (not TMxDialogs.Question('Você não especificou nenhum filtro, deseja consultar todo o cadastro?', False)) then
    vDs.MacroByName('VAZIO').AsString := 'AND (1=2) ';
  vDs.Open;
  if vDs.IsEmpty and vTemFiltro then
    TMxDialogs.Warning('Nenhum dado foi localizado');
end;

initialization
  RegisterClass(TFrm{MOD}CAD_{ENT}_P);

end.
```

**No DoAplicarFiltro**, para aplicar filtros dos controles de tela ao DataSet:
```pascal
// Após TKCDs.LimparMacro(vDs):
if Trim(edt{ENT}_NOM.Text) <> '' then
  vDs.MacroByName('{ENT}_NOM').Value := TKCStr.Like('{ENT}_NOM', Trim(edt{ENT}_NOM.Text));
if edt{ENT}_COD.Value > 0 then
  vDs.MacroByName('{ENT}_COD').Value := ' AND {ENT}_COD = ' + IntToStr(edt{ENT}_COD.Value);
```

---

## Padrão completo do V form (consulta read-only)

Telas de visualização de **1 registro completo**, abertas a partir de P forms ou de outras telas.
Modo somente leitura — sem botões CRUD, apenas Atualizar (F2) e Fechar.

**Classe base:** `TFrmGENCON_PAGCTR_V` — `F:\DEV\adriano.calligioni\KPL\Aplicacoes\BackOfficeDelphi\Generico\GENCON_PAGCTR_V.pas`
**Nomenclatura:** `{MOD}{SUB}_{ENT}_V.pas` — ex: `FINGEN_CHEQUE_V.pas`, `GENCON_CLIFOR_V.pas`
**DataSet:** `TQuery` (não TMxDataSet) — SQL direto com parâmetro do ID
**Componentes read-only:** `TNSDBStaticText`, `TdxDBGrid`, `TdxDBMemo` — **nunca** `TEdit`

```pascal
unit {MOD}{SUB}_{ENT}_V;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  GENCON_PAGCTR_V, DBTables, Db, {componentes};

type
  TFrm{MOD}{SUB}_{ENT}_V = class(TFrmGENCON_PAGCTR_V)
    qry{ENT}:       TQuery;           // DataSet principal read-only
    dtsMain:        TDataSource;      // DataSource principal
    pgcMain:        TdxPageControl;   // Abas por seção
    tbsMain:        TdxTabSheet;      // Aba principal
    // Campos do qry:
    qry{ENT}{ENT}_COD: TIntegerField;
    qry{ENT}{ENT}_NOM: TStringField;
    // Componentes de exibição:
    NSDBStaticText1: TNSDBStaticText;
    // Abas extras (lazy load):
    tbsExtra:       TdxTabSheet;
    qryExtra:       TQuery;
    dtsExtra:       TDataSource;
  protected
    procedure DoCreate; override;
    procedure DoOpenPage; override;
  end;

var
  Frm{MOD}{SUB}_{ENT}_V: TFrm{MOD}{SUB}_{ENT}_V;

implementation
{$R *.DFM}

procedure TFrm{MOD}{SUB}_{ENT}_V.DoCreate;
begin
  inherited;
  // Recebe o ID via FormParams (passado por quem abre)
  qry{ENT}.ParamByName('{ENT}_COD').AsInteger :=
    StrToInt(FormParams.Mx_StringList.Values['{ENT}_COD']);
  qry{ENT}.Open;
  // Ocultar abas de módulos não licenciados (opcional):
  // tbsExtra.TabVisible := FrmIntMainDtm.CheckModule('MOD');
end;

procedure TFrm{MOD}{SUB}_{ENT}_V.DoOpenPage;
var vDs: TDataSet;
begin
  vDs := nil;
  if (pgcMain.ActivePage = tbsExtra) then vDs := dtsExtra.DataSet;
  if Assigned(vDs) and (not vDs.Active) then vDs.Open;
end;

initialization
  RegisterClass(TFrm{MOD}{SUB}_{ENT}_V);

end.
```

**Como abrir um V form** — via helper `TKCDisplay` (em `Generico\`):
```pascal
// Em qualquer tela, para abrir a consulta do registro selecionado:
TKCDisplay.{NomeDaEntidade}(dtsGrd1.DataSet.FieldByName('{ENT}_COD').AsInteger);
```
`TKCDisplay` constrói o `TIntParamsBase` com `Mx_StringList.Values['{ENT}_COD']` e chama `SpecialFunctions.CreateFormBase`.

**SQL do TQuery no .dfm:**
```
SQL.Strings = (
  'SELECT {ENT}_COD, {ENT}_NOM, {ENT}_DAT_CAD, {ENT}_DAT_ALT'
  'FROM   dbo.T{MOD}_{ENT} (NOLOCK)'
  'WHERE  {ENT}_COD = :ENT_COD')
```

**Diferença V vs P:**

| Aspecto | V (visualização) | P (pesquisa) |
|---|---|---|
| Base | TFrmGENCON_PAGCTR_V | TFrmIntPesquisa |
| DataSet | TQuery (read-only) | TMxDataSet (editável) |
| Componentes | TNSDBStaticText | TEdit, TComboBox |
| Função | 1 registro completo | Lista + filtros |
| Abre | TKCDisplay helper | Menu principal |
| CRUD | Nenhum | Insert/Update/Delete |

---

## Registro no menu (ABACOS_MENU)

O menu é **hardcoded** nos arquivos:
- `.pas`: `F:\DEV\adriano.calligioni\KPL\Aplicacoes\BackOfficeDelphi\Principal\ABACOS_MENU.pas`
- `.dfm`: `F:\DEV\adriano.calligioni\KPL\Aplicacoes\BackOfficeDelphi\Principal\ABACOS_MENU.dfm`

Não existe tabela de banco — cada item é um `TMenuItem` no .dfm com handler no .pas.

### Adicionar handler no ABACOS_MENU.pas

```pascal
procedure TFrmABACOS_MENU.mni{Mod}Cad{Ent}Click(Sender: TObject);
var vParams: TIntParamsBase;
begin
  vParams := TIntParamsBase.Create;
  vParams.Mx_FormAutoDestroyIt := True;
  vParams.Mx_FormCaption       := (Sender as TMenuItem).Caption;
  vParams.Mx_PackageName       := 'K{MOD}';  // ex: 'KADM', 'KEST', 'KCOM'
  vParams.Mx_HideTreeViewMenu  := True;
  vParams.Mx_UrlMenu           := TKCHelp.RetornarEnderecoMenu(Sender as TMenuItem);
  SpecialFunctions.CreateFormBase('TFrm{MOD}CAD_{ENT}_P', vParams);
  FrmIntMainDtm.DoSendToDataDog(DATADOG_METRIC, DATADOG_TAGNAME, vParams.Mx_UrlMenu);
end;
```

### Adicionar TMenuItem no ABACOS_MENU.dfm

Localizar o submenu correto (ex: `mniAdmCad` para Administração → Cadastros) e inserir:

```
object mni{Mod}Cad{Ent}: TMenuItem
  Caption = '<Caption do item>'
  OnClick = mni{Mod}Cad{Ent}Click
end
```

**CRÍTICO:** `ABACOS_MENU.pas` e `.dfm` estão em **ISO-8859-1** — usar `sed` via Bash para editar, nunca Edit/Write tool.

### Declarar o handler no .pas (seção published ou interface)

No tipo `TFrmABACOS_MENU`, na seção `published`:
```pascal
procedure mni{Mod}Cad{Ent}Click(Sender: TObject);
```
