# FMX Components (FireMonkey)

## Diferenças fundamentais FMX vs VCL

- Arquivo de form: `.fmx` (não `.dfm`)
- Propriedades visuais diferentes (ex: `Text` em vez de `Caption` em alguns componentes)
- Cores usam formato com alpha: `$AARRGGBB`
- Suporte multiplataforma: Win32, Win64, macOS, iOS, Android
- Diretiva: `{$R *.fmx}`

## Componentes mais comuns

| Componente | Equivalente VCL | Observação |
|---|---|---|
| TButton | TButton | Usa `Text` em vez de `Caption` |
| TEdit | TEdit | Similar |
| TLabel | TLabel | Usa `Text` em vez de `Caption` |
| TPanel | TPanel | Sem borda visível por padrão |
| TCheckBox | TCheckBox | Similar |
| TComboBox | TComboBox | Similar |
| TMemo | TMemo | Similar |
| TListBox | TListBox | Similar |
| TImage | TImage | Similar |
| TTabControl | TPageControl | Diferente estruturalmente |

## Cores em FMX

Formato obrigatório: `$AARRGGBB` (Alpha, Red, Green, Blue)

Exemplos:
```
$FFFFFFFF  — branco opaco
$FF000000  — preto opaco
$FF0000FF  — azul opaco
$FFFF0000  — vermelho opaco
$800000FF  — azul semi-transparente (alpha=128)
```

**Nunca usar cor sem alpha explícito em FMX.**

## Exemplo FMX — TButton

```xml
object btnConfirmar: TButton
  Position.X = 100
  Position.Y = 100
  Size.Width = 120
  Size.Height = 32
  Text = 'Confirmar'
  TabOrder = 0
  OnClick = btnConfirmarClick
end
```

## Checklist antes de alterar FMX

1. Verificar padrão de propriedades existentes no `.fmx`
2. Preservar estrutura hierárquica dos componentes (FMX é orientado a pai/filho)
3. Usar formato de cor correto com alpha
4. Não inventar propriedade inexistente
5. Verificar que o componente foi declarado no `.pas`
