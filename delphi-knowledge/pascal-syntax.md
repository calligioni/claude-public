# Sintaxe Object Pascal

## Estrutura de uma unit

```pascal
unit NomeDaUnit;

interface

uses
  SysUtils,
  Classes;

type
  TMinhaClasse = class(TObject)
  private
    FNome: string;
    procedure SetNome(const Value: string);
  public
    property Nome: string read FNome write SetNome;
    constructor Create;
    destructor Destroy; override;
  end;

implementation

constructor TMinhaClasse.Create;
begin
  inherited;
  FNome := '';
end;

destructor TMinhaClasse.Destroy;
begin
  inherited;
end;

procedure TMinhaClasse.SetNome(const Value: string);
begin
  FNome := Value;
end;

end.
```

## Tipos primitivos

| Tipo | Descrição |
|---|---|
| `Integer` | Inteiro 32 bits |
| `Int64` | Inteiro 64 bits |
| `Double` | Ponto flutuante |
| `Currency` | Monetário (4 decimais) |
| `Boolean` | True/False |
| `string` | String (AnsiString no Delphi 5) |
| `Char` | Caractere único |
| `Byte` | 0-255 |
| `Word` | 0-65535 |
| `TDateTime` | Data/hora |

## Estrutura de formulário VCL

```pascal
unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics,
  Controls, Forms, Dialogs, StdCtrls;

type
  TForm1 = class(TForm)
    btnConfirmar: TButton;        // declarado pelo designer
    procedure btnConfirmarClick(Sender: TObject);  // declarado pelo designer
  private
    // campos e métodos privados
  public
    // campos e métodos públicos
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

procedure TForm1.btnConfirmarClick(Sender: TObject);
begin
  ShowMessage('Clicado');
end;

end.
```

## Regras críticas Object Pascal

1. `begin`/`end` obrigatório em blocos, mesmo com uma linha
2. `;` obrigatório ao final de cada instrução (exceto antes de `end`)
3. `inherited` obrigatório em construtores e destrutores que sobrescrevem
4. Campos privados: prefixo `F` por convenção (`FNome`, `FIdade`)
5. Properties: `read`/`write` com campo privado ou getter/setter
6. Delphi 5: string = AnsiString — cuidado com Unicode

## Tratamento de exceções

```pascal
try
  // código
except
  on E: Exception do
    ShowMessage(E.Message);
end;

try
  // código
finally
  // sempre executado (liberação de recursos)
end;
```

## Delphi 5 — sem namespaces

Delphi 5 não usa prefixos de namespace:
- Correto: `SysUtils`, `Classes`, `Forms`, `StdCtrls`
- Errado: `System.SysUtils`, `Vcl.Forms`, `Vcl.StdCtrls`
