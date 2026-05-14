# Delphi Knowledge Base

Base de conhecimento obrigatória para desenvolvimento Delphi com Claude Code.
**Ler este arquivo antes de alterar qualquer projeto Delphi.**

## Regra global
Sempre que uma correção nova for ensinada pelo usuário, atualizar o arquivo correspondente e depois atualizar este índice com a data da mudança.

---

## Estrutura de projeto
- [project-structure.md](project-structure.md) — .dpr/.dproj/.pas/.dfm/.fmx e suas relações

## Sintaxe Object Pascal
- [pascal-syntax.md](pascal-syntax.md) — tipos, estrutura de unit, declarações

## Relação .pas + .dfm/.fmx
- [dfm-fmx-rules.md](dfm-fmx-rules.md) — REGRA CRÍTICA: designer vs runtime

## VCL
- [vcl-components.md](vcl-components.md) — TButton, TEdit, TLabel e eventos no .dfm

## FMX
- [fmx-components.md](fmx-components.md) — componentes FireMonkey, cores com alpha

## Encoding
- [encoding.md](encoding.md) — UTF-8 BOM, CRLF, preservação de acentos

## Uses
- [uses-format.md](uses-format.md) — uma unit por linha, agrupamento por namespace

## Build
- [build-msbuild.md](build-msbuild.md) — MSBuild, plataforma, configuração, log

## Eventos de UI
- [ui-events.md](ui-events.md) — associação evento .dfm/.fmx ↔ método .pas

## Erros recorrentes
- [error-patterns.md](error-patterns.md) — registro acumulativo de erros corrigidos

## Estilo de código
- [style-guide.md](style-guide.md) — nomenclatura e formatação

## Padrões KPL (Delphi 5 VCL)
- [kpl-patterns.md](kpl-patterns.md) — padrões específicos do projeto KPL/Abacos

## SQL Server — KPL/Abacos
- [sqlserver-patterns.md](sqlserver-patterns.md) — naming, DT_ types, SP template, utilitários (PGEN_P_*, FGEN_S_GETDATE)
