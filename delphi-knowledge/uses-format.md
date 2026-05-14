# Formatação de Uses

## Regra obrigatória

Cada unit deve ficar em uma linha separada.

## Formato correto

```pascal
uses
  SysUtils,
  Classes,

  Controls,
  Forms,
  StdCtrls,
  ExtCtrls;
```

## Formato errado

```pascal
uses
  SysUtils, Classes, Controls, Forms, StdCtrls;
```

## Regras de formatação

1. Uma unit por linha
2. Vírgula no final de cada linha, exceto a última (que tem `;`)
3. Agrupar por namespace/categoria
4. Separar grupos com linha em branco
5. Preservar a ordem: System antes de VCL/FMX quando aplicável

## Delphi 5 — sem namespaces

Grupos típicos para Delphi 5:

```pascal
uses
  // RTL
  SysUtils,
  Classes,
  Math,

  // Windows
  Windows,
  Messages,
  ShellAPI,

  // VCL base
  Graphics,
  Controls,
  Forms,
  Dialogs,

  // VCL componentes
  StdCtrls,
  ExtCtrls,
  ComCtrls,
  Grids,

  // Data-aware
  DB,
  DBCtrls,
  DBGrids;
```

## Delphi moderno — com namespaces

```pascal
uses
  System.SysUtils,
  System.Classes,

  Vcl.Controls,
  Vcl.Forms,
  Vcl.StdCtrls;
```

## Regras de segurança

- Não remover unit sem verificar uso real no código
- Se adicionar método ou classe que exige unit nova, incluir no `uses` correto
- `uses` na `interface` = acesso público; `uses` na `implementation` = uso interno

## Como verificar uso de uma unit

Antes de remover uma unit do `uses`, pesquisar no `.pas` por tipos e funções típicos dela.
Exemplo: antes de remover `SysUtils`, verificar se o código usa `Format`, `IntToStr`, `StrToInt`, `Trim`, etc.
