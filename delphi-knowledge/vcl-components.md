# VCL Components

## Componentes mais comuns

| Componente | Tipo | Uso |
|---|---|---|
| TButton | Botão clicável | Ações, confirmar, cancelar |
| TEdit | Campo de texto | Entrada de dado simples |
| TLabel | Texto estático | Rótulos, captions |
| TPanel | Container | Agrupar controles |
| TGroupBox | Container com borda | Agrupar com título |
| TCheckBox | Caixa de seleção | Booleano visual |
| TComboBox | Lista suspensa | Seleção de opção |
| TListBox | Lista | Múltiplos itens |
| TMemo | Texto multilinha | Notas, texto longo |
| TStringGrid | Grade de strings | Tabelas simples |
| TDBGrid | Grade de dados | Exibição de dataset |
| TPageControl | Abas | Formulários com tabs |

## Exemplo DFM — TButton

```dfm
object btnConfirmar: TButton
  Left = 100
  Top = 100
  Width = 120
  Height = 32
  Caption = 'Confirmar'
  TabOrder = 0
  OnClick = btnConfirmarClick
end
```

Método correspondente no `.pas`:
```pascal
procedure TForm1.btnConfirmarClick(Sender: TObject);
begin
  ShowMessage('Confirmado');
end;
```

## Exemplo DFM — TEdit

```dfm
object edtNome: TEdit
  Left = 100
  Top = 50
  Width = 200
  Height = 21
  TabOrder = 0
  Text = ''
end
```

## Exemplo DFM — TLabel

```dfm
object lblNome: TLabel
  Left = 10
  Top = 53
  Width = 35
  Height = 13
  Caption = 'Nome:'
end
```

## Convenções de nomenclatura VCL

| Prefixo | Tipo |
|---|---|
| `btn` | TButton |
| `edt` | TEdit |
| `lbl` | TLabel |
| `pnl` | TPanel |
| `grp` | TGroupBox |
| `chk` | TCheckBox |
| `cbo` | TComboBox |
| `lst` | TListBox |
| `mmo` | TMemo |
| `grd` | TStringGrid / TDBGrid |
| `pgc` | TPageControl |
| `tab` | TTabSheet |
| `img` | TImage |

## Declaração no .pas (Delphi 5)

```pascal
type
  TForm1 = class(TForm)
    btnConfirmar: TButton;
    edtNome: TEdit;
    lblNome: TLabel;
    procedure btnConfirmarClick(Sender: TObject);
  private
  public
  end;
```

Observação Delphi 5: sem namespaces — usar `StdCtrls` (não `Vcl.StdCtrls`) no uses.
