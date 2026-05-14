# Estrutura de Projetos Delphi

## Arquivos obrigatórios

- `.dpr` — arquivo principal do programa (lista units e forms)
- `.dproj` — configuração do projeto (plataforma, versão, paths)
- `.pas` — unit Pascal (lógica + declaração de componentes do formulário)
- `.dfm` — formulário VCL (componentes visuais em texto ou binário)
- `.fmx` — formulário FireMonkey (componentes visuais FMX)
- `.res` — resources (ícones, strings, etc.)

## VCL vs FMX

| Tipo | Form | Unit |
|---|---|---|
| VCL | `.dfm` | `.pas` |
| FMX | `.fmx` | `.pas` |

## Relação obrigatória .pas ↔ .dfm/.fmx

Cada formulário tem DOIS arquivos inseparáveis:
- O `.pas` contém: declaração da classe, declaração dos componentes (na seção `published`), e implementação dos métodos/eventos
- O `.dfm` ou `.fmx` contém: a definição visual (posição, tamanho, propriedades, eventos vinculados)

**Regra absoluta: nunca assumir que alterar apenas o `.pas` é suficiente para mudanças visuais.**

## Checklist antes de alterar qualquer formulário

1. Ler o `.pas` — entender a classe, componentes declarados, eventos existentes
2. Ler o `.dfm` ou `.fmx` — entender o que existe visualmente, nomes dos componentes
3. Identificar se é VCL ou FMX
4. Planejar as alterações em AMBOS os arquivos
5. Nunca criar componente visual em runtime quando o pedido é de componente persistente no designer

## Delphi 5 especificamente (KPL/Abacos)

- Não usa `{$R *.fmx}` — usa `{$R *.dfm}`
- Não usa namespaces (`System.`, `Vcl.`) — usa nomes diretos (`SysUtils`, `Forms`, `StdCtrls`)
- Units legadas: `Controls`, `Forms`, `StdCtrls`, `ExtCtrls`, `Grids`, `DBCtrls`, `DBGrids`
