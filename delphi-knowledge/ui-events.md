# Eventos de UI Delphi

## Regra fundamental

O nome do evento no `.dfm`/`.fmx` deve corresponder **exatamente** ao nome do método no `.pas`.

Se o `.dfm` diz `OnClick = btnConfirmarClick`, o `.pas` deve ter:
```pascal
procedure TForm1.btnConfirmarClick(Sender: TObject);
```

## Eventos mais comuns VCL

| Evento | Assinatura | Quando dispara |
|---|---|---|
| `OnClick` | `procedure(Sender: TObject)` | Clique do mouse |
| `OnDblClick` | `procedure(Sender: TObject)` | Duplo clique |
| `OnChange` | `procedure(Sender: TObject)` | Valor alterado |
| `OnKeyDown` | `procedure(Sender: TObject; var Key: Word; Shift: TShiftState)` | Tecla pressionada |
| `OnKeyPress` | `procedure(Sender: TObject; var Key: Char)` | Tecla pressionada (char) |
| `OnKeyUp` | `procedure(Sender: TObject; var Key: Word; Shift: TShiftState)` | Tecla solta |
| `OnEnter` | `procedure(Sender: TObject)` | Foco recebido |
| `OnExit` | `procedure(Sender: TObject)` | Foco perdido |
| `OnCreate` | `procedure(Sender: TObject)` | Formulário criado |
| `OnDestroy` | `procedure(Sender: TObject)` | Formulário destruído |
| `OnShow` | `procedure(Sender: TObject)` | Formulário exibido |
| `OnClose` | `procedure(Sender: TObject; var Action: TCloseAction)` | Formulário fechando |
| `OnResize` | `procedure(Sender: TObject)` | Componente redimensionado |

## Checklist para criar evento

1. Definir o nome do método: `[NomeForm][NomeComponente][NomeEvento]`
   - Exemplo: `btnConfirmarClick`, `edtNomeChange`, `FormCreate`
2. No `.dfm`, adicionar a linha do evento ao componente:
   ```
   OnClick = btnConfirmarClick
   ```
3. No `.pas`, declarar o método na seção `published` (ou deixar o IDE gerar):
   ```pascal
   procedure btnConfirmarClick(Sender: TObject);
   ```
4. No `.pas`, implementar o método na seção `implementation`:
   ```pascal
   procedure TForm1.btnConfirmarClick(Sender: TObject);
   begin
     // código aqui
   end;
   ```

## Convenção de nomenclatura de eventos

```
[prefixo do componente][Nome][Evento]
```

Exemplos:
- `btnSalvarClick` — botão btnSalvar, evento Click
- `edtCPFChange` — edit edtCPF, evento Change
- `grdProdutosKeyDown` — grid grdProdutos, evento KeyDown
- `FormCreate` — formulário, evento Create
- `FormClose` — formulário, evento Close

## Erro típico: nome de evento divergente

**Sintoma**: programa compila mas o evento não dispara, ou erro em runtime.

**Causa**: `.dfm` diz `OnClick = btnSalvarClick` mas o `.pas` declara `procedure btnSalvar_Click(...)`.

**Correção**: garantir que o nome é idêntico em ambos os arquivos.
