# Guia de Estilo Object Pascal

## Convenções de nomenclatura

### Tipos
- Classes: prefixo `T` — `TForm1`, `TMinhaClasse`, `TClienteData`
- Interfaces: prefixo `I` — `IServicoCliente`
- Enumerações: prefixo `T` — `TStatusPedido = (spAberto, spFechado)`
- Records: prefixo `T` — `TRegistroCliente`

### Campos privados
- Prefixo `F` — `FNome: string`, `FIdade: Integer`

### Parâmetros de método
- Prefixo nenhum ou `A` para parâmetros de entrada — `AValor`, `ANome`
- `var` para parâmetros de saída

### Variáveis locais
- CamelCase sem prefixo — `valorTotal`, `listaProdutos`

### Constantes
- PascalCase — `MaxTentativas = 3`
- Ou ALL_CAPS se convenção do projeto — `MAX_TENTATIVAS = 3`

## Indentação e formatação

- 2 ou 4 espaços por nível (respeitar o padrão existente no arquivo)
- `begin`/`end` alinhados com o bloco pai
- Sem espaço antes de `;`
- Espaço antes e depois de operadores: `x := a + b`

## Exemplo de classe bem formatada

```pascal
type
  TClienteService = class(TObject)
  private
    FNome: string;
    FIdade: Integer;
    procedure Validar;
  public
    constructor Create(const ANome: string; AIdade: Integer);
    destructor Destroy; override;
    property Nome: string read FNome;
    property Idade: Integer read FIdade;
  end;

implementation

constructor TClienteService.Create(const ANome: string; AIdade: Integer);
begin
  inherited Create;
  FNome := ANome;
  FIdade := AIdade;
end;
```

## KPL/Abacos — convenções específicas

Prefixos de componentes visuais (ver `vcl-components.md` para lista completa):
- `btn` — TButton
- `edt` — TEdit
- `lbl` — TLabel
- `pnl` — TPanel
- `grd` — TDBGrid / TStringGrid

Nomes de formulários:
- Master (manutenção): `TFrm[Modulo]Manut[Entidade]` — ex: `TFrmEstManutProduto`
- Pesquisa: `TFrm[Modulo]Pesq[Entidade]` — ex: `TFrmEstPesqProduto`
- DataModule: `TDM[Modulo][Entidade]` — ex: `TDMEstProduto`

## O que não fazer

- Não misturar estilos de indentação no mesmo arquivo
- Não usar `goto` (evitar sempre)
- Não deixar `begin`/`end` vazios sem comentário explicativo
- Não criar variável com nome de uma letra (exceto contadores: `i`, `j`)
