# Regras para DFM e FMX

## Regra crítica

Componentes visuais **persistentes** devem existir no `.dfm` ou `.fmx`.

**Nunca criar componentes visuais em runtime quando o usuário pedir alteração de tela visual/designer.**

Exceção permitida: somente quando o usuário pedir **explicitamente** criação em runtime.

## Checklist para adicionar componente visual

1. Declarar o componente no `.pas` (seção `published` da classe do form)
2. Criar o objeto visual no `.dfm`/`.fmx` com propriedades corretas
3. Associar o evento no `.dfm`/`.fmx` (ex: `OnClick = btnConfirmarClick`)
4. Criar o método do evento no `.pas`
5. Verificar que o nome do evento no `.dfm`/`.fmx` bate **exatamente** com o método no `.pas`

## Estrutura DFM VCL — exemplo completo

```dfm
object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 'Form1'
  ClientHeight = 400
  ClientWidth = 600
  object btnConfirmar: TButton
    Left = 100
    Top = 100
    Width = 120
    Height = 32
    Caption = 'Confirmar'
    TabOrder = 0
    OnClick = btnConfirmarClick
  end
end
```

## Correspondência no .pas VCL

```pascal
type
  TForm1 = class(TForm)
    btnConfirmar: TButton;          // declarado aqui
    procedure btnConfirmarClick(Sender: TObject);  // declarado aqui
  private
  public
  end;

implementation

procedure TForm1.btnConfirmarClick(Sender: TObject);
begin
  ShowMessage('Confirmado');
end;
```

## Erros comuns a evitar

- Criar `TButton.Create(Self)` quando o usuário pediu um botão no form
- Declarar o componente no `.pas` mas esquecer de criá-lo no `.dfm`
- Alterar o Caption de um botão só no `.pas` sem atualizar o `.dfm`
- Renomear componente no `.pas` sem renomear no `.dfm`
